"""
Verilog Sanitizer & Preprocessor Module
Implements comment removal, token filtering, and text normalization 
as described in Section IV-A & IV-B of the paper.
"""

import re
from pathlib import Path
from typing import List, Tuple, Union


class VerilogSanitizer:
    def __init__(self, filter_keywords: bool = True):
        # Specific giveaway words mentioned in the paper (e.g. 'trojan', 'Tj', 'payload', 'trigger')
        self.filter_keywords = filter_keywords
        self.banned_tokens = [
            r"\btrojan\b",
            r"\bTrojan\b",
            r"\bTROJAN\b",
            r"\bTj\b",
            r"\bTj_Trig\b",
            r"\btrigger\b",
            r"\bTrigger\b",
            r"\bpayload\b",
            r"\bPayload\b",
            r"\bmalicious\b",
            r"\bbackdoor\b",
            r"\battack\b",
        ]
        self.token_regex = re.compile("|".join(self.banned_tokens), re.IGNORECASE)

    def remove_comments(self, verilog_code: str) -> str:
        """Removes single-line (//) and multi-line (/* */) Verilog comments."""
        # Remove multi-line comments: /* ... */
        code_without_multiline = re.sub(r"/\*[\s\S]*?\*/", "", verilog_code)
        # Remove single-line comments: // ...
        code_clean = re.sub(r"//.*", "", code_without_multiline)
        return code_clean

    def sanitize(self, verilog_code: str) -> str:
        """
        Cleans Verilog source code:
        1. Strips all comments.
        2. Filters giveaway keywords that would trivially bias classifiers.
        3. Normalizes whitespace while preserving structure.
        """
        # 1. Remove comments
        clean_code = self.remove_comments(verilog_code)

        # 2. Filter giveaway tokens if requested
        if self.filter_keywords:
            clean_code = self.token_regex.sub("aux_sig", clean_code)

        # 3. Clean and normalize whitespace
        lines = [line.strip() for line in clean_code.splitlines() if line.strip()]
        return "\n".join(lines)


def process_directory(
    input_dir: Union[str, Path], 
    output_dir: Union[str, Path], 
    label: int
) -> List[Tuple[str, int, str]]:
    """
    Sanitizes all .v / .sv files in input_dir and saves processed versions.
    Returns list of (file_name, label, sanitized_code).
    """
    sanitizer = VerilogSanitizer(filter_keywords=True)
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    records = []
    if not input_path.exists():
        return records

    for file_path in input_path.glob("*.v"):
        try:
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                raw_code = f.read()
            clean_code = sanitizer.sanitize(raw_code)
            
            # Save sanitized file
            out_file = output_path / file_path.name
            with open(out_file, "w", encoding="utf-8") as f:
                f.write(clean_code)

            records.append((file_path.name, label, clean_code))
        except Exception as e:
            print(f"Error processing {file_path.name}: {e}")

    return records
