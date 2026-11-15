"""
Synthetic Hardware Trojan Generator using Local Ollama LLM (Qwen 2.5 3B).
Implements the Red-Teaming hardware trojan insertion pipeline from Section IV-A.
"""

import json
import re
from pathlib import Path
from typing import Optional
import requests

from src.llm_eval.prompts import (
    GENERATION_SYSTEM_PROMPT,
    GENERATION_USER_PROMPT_TEMPLATE,
)


class OllamaTrojanGenerator:
    def __init__(
        self, 
        model_name: str = "qwen2.5:3b", 
        host: str = "http://localhost:11434"
    ):
        self.model_name = model_name
        self.api_url = f"{host}/api/chat"

    def generate_trojan(self, clean_verilog: str, timeout: int = 120) -> Optional[str]:
        """
        Queries local Ollama Qwen model to insert a hardware trojan into clean Verilog code.
        """
        user_prompt = GENERATION_USER_PROMPT_TEMPLATE.format(verilog_code=clean_verilog)
        
        payload = {
            "model": self.model_name,
            "messages": [
                {"role": "system", "content": GENERATION_SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt}
            ],
            "stream": False,
            "options": {
                "temperature": 0.4,
                "top_p": 0.9,
            }
        }

        try:
            response = requests.post(self.api_url, json=payload, timeout=timeout)
            response.raise_for_status()
            data = response.json()
            content = data.get("message", {}).get("content", "")
            
            # Extract Verilog code block if enclosed in ```verilog ... ```
            match = re.search(r"```(?:verilog)?\s*([\s\S]*?)\s*```", content, re.IGNORECASE)
            if match:
                return match.group(1).strip()
            return content.strip()
        except Exception as e:
            print(f"[Generator] Error calling Ollama: {e}")
            return None

    def batch_generate(
        self, 
        golden_dir: str = "data/raw/golden", 
        output_dir: str = "data/raw/trojans",
        variants_per_file: int = 2
    ):
        """
        Reads all golden Verilog files and generates trojan-infected versions.
        """
        golden_path = Path(golden_dir)
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        golden_files = list(golden_path.glob("*.v"))
        print(f"[Generator] Found {len(golden_files)} golden designs in {golden_dir}")

        for idx, file_path in enumerate(golden_files, 1):
            with open(file_path, "r", encoding="utf-8") as f:
                code = f.read()

            print(f"[{idx}/{len(golden_files)}] Generating trojans for: {file_path.name}")
            for v in range(variants_per_file):
                trojan_code = self.generate_trojan(code)
                if trojan_code:
                    out_name = f"{file_path.stem}_trojan_v{v+1}.v"
                    out_file = output_path / out_name
                    with open(out_file, "w", encoding="utf-8") as out_f:
                        out_f.write(trojan_code)
                    print(f"   -> Saved infected variant: {out_name}")
                else:
                    print(f"   -> Failed generation for variant {v+1}")
