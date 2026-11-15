"""
Synthetic Hardware Trojan Generator using a local Ollama LLM (default: qwen2.5:3b).
Implements the red-teaming trojan insertion pipeline from Section IV-A of the paper:
the golden model + the paper's generation prompt are sent to an LLM, which returns
a trojan-infected version that keeps the original module interface.
"""

import re
import time
from pathlib import Path
from typing import Optional

import requests

from src.llm_eval.prompts import (
    GENERATION_SYSTEM_PROMPT,
    GENERATION_USER_PROMPT_TEMPLATE,
)

_MODULE_RE = re.compile(r"\bmodule\s+(\w+)")


def _norm(code: str) -> list:
    """Non-empty, whitespace-normalised lines (comments removed) for diffing."""
    code = re.sub(r"/\*[\s\S]*?\*/", "", code)
    code = re.sub(r"//.*", "", code)
    return [" ".join(l.split()) for l in code.splitlines() if l.strip()]


def validate_trojan(golden: str, candidate: str) -> Optional[str]:
    """Returns None if the candidate looks like a valid modified design, else a reason."""
    if not candidate or "endmodule" not in candidate:
        return "no endmodule"
    g_mod, c_mod = _MODULE_RE.search(golden), _MODULE_RE.search(candidate)
    if not c_mod:
        return "no module"
    if g_mod and g_mod.group(1) != c_mod.group(1):
        return f"module renamed ({g_mod.group(1)} -> {c_mod.group(1)})"
    g, c = _norm(golden), _norm(candidate)
    if not g or not c:
        return "empty"
    ratio = len(c) / len(g)
    if ratio < 0.6 or ratio > 2.5:
        return f"length ratio {ratio:.2f}"
    changed = len(set(c) - set(g))
    if changed < 2:
        return "no meaningful change"
    return None


class OllamaTrojanGenerator:
    def __init__(
        self,
        model_name: str = "qwen2.5:3b",
        host: str = "http://localhost:11434",
        num_ctx: int = 16384,
    ):
        self.model_name = model_name
        self.api_url = f"{host}/api/chat"
        self.num_ctx = num_ctx

    def generate_trojan(self, clean_verilog: str, timeout: int = 600) -> Optional[str]:
        """Asks the LLM to insert a hardware trojan into clean Verilog code."""
        user_prompt = GENERATION_USER_PROMPT_TEMPLATE.format(verilog_code=clean_verilog)
        payload = {
            "model": self.model_name,
            "messages": [
                {"role": "system", "content": GENERATION_SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt},
            ],
            "stream": False,
            "options": {"temperature": 0.4, "top_p": 0.9, "num_ctx": self.num_ctx},
        }
        try:
            response = requests.post(self.api_url, json=payload, timeout=timeout)
            response.raise_for_status()
            content = response.json().get("message", {}).get("content", "")
            match = re.search(r"```(?:verilog|systemverilog|v)?\s*([\s\S]*?)\s*```", content, re.IGNORECASE)
            return (match.group(1) if match else content).strip()
        except Exception as e:
            print(f"[Generator] Error calling Ollama: {e}")
            return None

    def generate_missing(
        self,
        golden_dir: str = "data/raw/golden",
        output_dir: str = "data/raw/trojans",
        variants_per_file: int = 1,
        max_attempts: int = 3,
        max_lines: int = 600,
    ):
        """
        For every golden design, creates `<stem>_T<n>.v` trojan variants that do not exist yet.
        Each candidate is validated (same module name, real modification, sane length);
        invalid outputs are retried and finally skipped (logged).
        """
        golden_files = sorted(Path(golden_dir).glob("*.v"))
        out = Path(output_dir)
        out.mkdir(parents=True, exist_ok=True)
        print(f"[Generator] {len(golden_files)} golden designs, model={self.model_name}")

        ok = skipped = failed = 0
        for idx, f in enumerate(golden_files, 1):
            code = f.read_text(encoding="utf-8", errors="ignore")
            if len(code.splitlines()) > max_lines:
                print(f"[{idx}/{len(golden_files)}] {f.name}: SKIP (> {max_lines} lines)")
                skipped += 1
                continue
            for v in range(variants_per_file):
                target = out / f"{f.stem}_T{v}.v"
                if target.exists():
                    continue
                t0 = time.time()
                reason = "not attempted"
                for attempt in range(1, max_attempts + 1):
                    cand = self.generate_trojan(code)
                    reason = validate_trojan(code, cand or "")
                    if reason is None:
                        target.write_text(cand + "\n", encoding="utf-8")
                        ok += 1
                        print(f"[{idx}/{len(golden_files)}] {target.name}: OK "
                              f"(attempt {attempt}, {time.time() - t0:.0f}s)", flush=True)
                        break
                else:
                    failed += 1
                    print(f"[{idx}/{len(golden_files)}] {f.stem}_T{v}: FAILED ({reason})", flush=True)
        print(f"[Generator] done: {ok} generated, {failed} failed validation, {skipped} skipped (too long)")

    # kept for backward compatibility with main.py --generate
    def batch_generate(self, golden_dir: str = "data/raw/golden", output_dir: str = "data/raw/trojans",
                       variants_per_file: int = 1):
        self.generate_missing(golden_dir, output_dir, variants_per_file)
