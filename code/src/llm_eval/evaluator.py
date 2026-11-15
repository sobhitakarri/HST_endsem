"""
LLM Prompt Optimization & Zero-Shot Detection Evaluator (Approach 2)
Implements and evaluates the 4 prompt strategies from Appendix A:
1. Simple Prompt
2. TrustHub Definition & Example
3. Checklist-Based Review (ISO/IEC 20246:2017)
4. Role-Playing / Perspective-Based Review (Security Analyst, Verification Eng, Test Eng)
"""

import re
from typing import Dict, List, Tuple, Any
import pandas as pd
import requests
from sklearn.metrics import accuracy_score, recall_score, precision_score, f1_score
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


class LLMEvaluator:
    def __init__(
        self, 
        model_name: str = "qwen2.5:3b", 
        host: str = "http://localhost:11434"
    ):
        self.model_name = model_name
        self.api_url = f"{host}/api/chat"

    def predict_single(self, system_prompt: str, user_prompt: str) -> int:
        """
        Sends code + prompt to local Ollama and extracts binary 0 or 1 classification.
        """
        payload = {
            "model": self.model_name,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "stream": False,
            "options": {
                "temperature": 0.0, # Deterministic zero-shot classification
            }
        }

        try:
            response = requests.post(self.api_url, json=payload, timeout=60)
            response.raise_for_status()
            content = response.json().get("message", {}).get("content", "").strip()

            # Parse integer 0 or 1 from response
            numbers = re.findall(r"\b[01]\b", content)
            if numbers:
                return int(numbers[-1])
            # Fallback heuristic: check keywords
            if "1" in content or "trojan" in content.lower() or "malicious" in content.lower():
                return 1
            return 0
        except Exception as e:
            print(f"[LLM Evaluator] Request error: {e}")
            return 0

    def evaluate_strategy(
        self, 
        df: pd.DataFrame, 
        strategy_name: str, 
        system_prompt: str, 
        user_prompt_template: str
    ) -> Dict[str, Any]:
        """
        Evaluates a single prompt strategy over the dataset.
        """
        y_true = df["label"].tolist()
        y_pred = []

        print(f" -> Evaluating [{strategy_name}] on {len(df)} samples...", end="", flush=True)
        for idx, row in df.iterrows():
            user_msg = user_prompt_template.format(verilog_code=row["code"])
            pred = self.predict_single(system_prompt, user_msg)
            y_pred.append(pred)
        print(" [Done]")

        acc = accuracy_score(y_true, y_pred) * 100
        rec = recall_score(y_true, y_pred, zero_division=0) * 100
        f1 = f1_score(y_true, y_pred, zero_division=0) * 100

        return {
            "Approach": f"{self.model_name} ({strategy_name})",
            "Accuracy": f"{acc:.2f}%",
            "Recall": f"{rec:.2f}%",
            "f1-score": f"{f1:.2f}%",
            "_acc": acc,
            "_rec": rec,
            "_f1": f1
        }

    def run_all_strategies(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Runs all 4 prompting strategies and prints comparison table (Table 6).
        """
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
        print("\n" + "="*70)
        print(" TABLE 6: PERFORMANCE COMPARISON OF LLM PROMPTS")
        print("="*70)
        print(tabulate(res_df[["Approach", "Accuracy", "Recall", "f1-score"]], headers="keys", tablefmt="github", showindex=False))
        return res_df
