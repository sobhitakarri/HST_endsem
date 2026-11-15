"""
LLM Prompt Optimization & Zero-Shot Detection Evaluator (Approach 2)
Implements and evaluates the 4 prompt strategies from Appendix A:
1. Simple Prompt
2. TrustHub Definition & Example
3. Checklist-Based Review (ISO/IEC 20246:2017)
4. Role-Playing / Perspective-Based Review (Security Analyst, Verification Eng, Test Eng)

Supports local Ollama as well as cloud OpenAI-compatible APIs (e.g., Groq).
"""

import os
import re
import time
from pathlib import Path
from typing import Dict, Any, Optional
import pandas as pd
import requests
from sklearn.metrics import accuracy_score, recall_score, precision_score, f1_score, balanced_accuracy_score
from tabulate import tabulate

from src.llm_eval.prompts import (
    SIMPLE_SYSTEM_PROMPT,
    SIMPLE_USER_PROMPT_TEMPLATE,
    TRUSTHUB_SYSTEM_PROMPT,
    TRUSTHUB_USER_PROMPT_TEMPLATE,
    CHECKLIST_SYSTEM_PROMPT,
    SECURITY_ANALYST_SYSTEM_PROMPT,
    VERIFICATION_ENGINEER_SYSTEM_PROMPT,
    TEST_ENGINEER_SYSTEM_PROMPT,
    PERSPECTIVE_USER_PROMPT_TEMPLATE,
)


def _load_dotenv():
    """Loads .env from current or parent directory if present."""
    for env_path in (Path(".env"), Path("../.env")):
        if env_path.exists():
            for line in env_path.read_text(encoding="utf-8", errors="ignore").splitlines():
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    os.environ.setdefault(k.strip(), v.strip())


def _parse_binary_prediction(content: str) -> Optional[int]:
    """Extracts 0 or 1 cleanly from an LLM response."""
    text = content.strip()
    if text in ("0", "1"):
        return int(text)
    numbers = re.findall(r"\b[01]\b", text)
    if numbers:
        return int(numbers[-1])
    low = text.lower()
    if "no trojan" in low or "clean" in low or "benign" in low:
        return 0
    if "trojan" in low or "malicious" in low:
        return 1
    return None


class LLMEvaluator:
    def __init__(
        self,
        model_name: str = "qwen2.5:3b",
        provider: str = "ollama",
        host: str = "http://localhost:11434",
        api_key: Optional[str] = None,
        max_code_chars: int = 12000,
    ):
        _load_dotenv()
        self.model_name = model_name
        self.provider = provider.lower()
        self.max_code_chars = max_code_chars

        if self.provider == "groq":
            self.api_url = "https://api.groq.com/openai/v1/chat/completions"
            self.api_key = api_key or os.environ.get("GROQ_API_KEY", "")
            if not self.api_key:
                raise ValueError("GROQ_API_KEY not found in environment or .env")
        elif self.provider == "openai":
            self.api_url = f"{host.rstrip('/')}/v1/chat/completions"
            self.api_key = api_key or os.environ.get("OPENAI_API_KEY", "")
        else:
            self.api_url = f"{host.rstrip('/')}/api/chat"
            self.api_key = ""

    def _call_api(self, system_prompt: str, user_prompt: str, max_retries: int = 6) -> str:
        """Calls the configured LLM backend with automatic 429 rate-limit backoff."""
        if self.provider in ("groq", "openai"):
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
            }
            payload = {
                "model": self.model_name,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                "temperature": 0.0,
                "max_tokens": 256,
            }
            for attempt in range(max_retries):
                resp = requests.post(self.api_url, headers=headers, json=payload, timeout=60)
                if resp.status_code == 429:
                    wait = float(resp.headers.get("Retry-After", 10 + 5 * attempt))
                    time.sleep(min(wait, 65))
                    continue
                resp.raise_for_status()
                # Proactive pacing if remaining tokens are below 2,000
                rem_tok = resp.headers.get("x-ratelimit-remaining-tokens")
                if rem_tok is not None and int(rem_tok) < 2000:
                    time.sleep(8)
                return resp.json()["choices"][0]["message"].get("content", "") or ""
            raise RuntimeError("Exceeded max retries due to rate limiting (429).")

        # Local Ollama
        payload = {
            "model": self.model_name,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            "stream": False,
            "options": {"temperature": 0.0},
        }
        resp = requests.post(self.api_url, json=payload, timeout=90)
        resp.raise_for_status()
        return resp.json().get("message", {}).get("content", "")

    def predict_single(self, system_prompt: str, user_prompt: str) -> int:
        """Sends code + prompt to the LLM and extracts binary 0 or 1 classification."""
        try:
            content = self._call_api(system_prompt, user_prompt)
            parsed = _parse_binary_prediction(content)
            return parsed if parsed is not None else 0
        except Exception as e:
            print(f"\n[LLM Evaluator] Request error: {e}")
            return 0

    def evaluate_strategy(
        self,
        df: pd.DataFrame,
        strategy_name: str,
        system_prompt: str,
        user_prompt_template: str,
    ) -> Dict[str, Any]:
        """Evaluates a single prompt strategy over the dataset."""
        y_true = df["label"].tolist()
        y_pred = []

        print(f" -> Evaluating [{strategy_name}] on {len(df)} samples...", end="", flush=True)
        for _, row in df.iterrows():
            code_snippet = row["code"][:self.max_code_chars]
            user_msg = user_prompt_template.format(verilog_code=code_snippet)
            pred = self.predict_single(system_prompt, user_msg)
            y_pred.append(pred)
        print(" [Done]", flush=True)

        acc = accuracy_score(y_true, y_pred) * 100
        bal_acc = balanced_accuracy_score(y_true, y_pred) * 100
        rec = recall_score(y_true, y_pred, zero_division=0) * 100
        prec = precision_score(y_true, y_pred, zero_division=0) * 100
        f1 = f1_score(y_true, y_pred, zero_division=0) * 100

        return {
            "Approach": f"{self.model_name} ({strategy_name})",
            "Accuracy": f"{acc:.2f}%",
            "Balanced Acc": f"{bal_acc:.2f}%",
            "Recall": f"{rec:.2f}%",
            "Precision": f"{prec:.2f}%",
            "f1-score": f"{f1:.2f}%",
            "_acc": acc,
            "_bal_acc": bal_acc,
            "_rec": rec,
            "_f1": f1,
        }

    def run_all_strategies(self, df: pd.DataFrame) -> pd.DataFrame:
        """Runs all prompting strategies and prints comparison table (Table 6)."""
        strategies = [
            ("simple prompt", SIMPLE_SYSTEM_PROMPT, SIMPLE_USER_PROMPT_TEMPLATE),
            ("trusthub tj def and ex", TRUSTHUB_SYSTEM_PROMPT, TRUSTHUB_USER_PROMPT_TEMPLATE),
            ("checklist", CHECKLIST_SYSTEM_PROMPT, PERSPECTIVE_USER_PROMPT_TEMPLATE),
            ("Security Analyst Role", SECURITY_ANALYST_SYSTEM_PROMPT, PERSPECTIVE_USER_PROMPT_TEMPLATE),
            ("Verification Engineer Role", VERIFICATION_ENGINEER_SYSTEM_PROMPT, PERSPECTIVE_USER_PROMPT_TEMPLATE),
            ("Test Engineer Role", TEST_ENGINEER_SYSTEM_PROMPT, PERSPECTIVE_USER_PROMPT_TEMPLATE),
        ]

        results = []
        for name, sys_p, usr_p in strategies:
            res = self.evaluate_strategy(df, name, sys_p, usr_p)
            results.append(res)

        res_df = pd.DataFrame(results)
        print("\n" + "=" * 70)
        print(" TABLE 6: PERFORMANCE COMPARISON OF LLM PROMPTS")
        print("=" * 70)
        print(tabulate(
            res_df[["Approach", "Accuracy", "Balanced Acc", "Recall", "Precision", "f1-score"]],
            headers="keys",
            tablefmt="github",
            showindex=False,
        ))
        return res_df
