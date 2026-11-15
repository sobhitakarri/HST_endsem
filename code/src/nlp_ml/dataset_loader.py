"""
Dataset Loader & Preparation Module
Loads sanitized Verilog files, attaches labels (0 = Clean, 1 = Trojan),
and balances classes via oversampling.
"""

from pathlib import Path
from typing import List, Tuple
import pandas as pd
from imblearn.over_sampling import RandomOverSampler
from src.preprocessor.sanitizer import VerilogSanitizer


def load_and_preprocess_dataset(
    clean_dir: str = "data/raw/golden",
    trojan_dir: str = "data/raw/trojans",
    apply_sanitization: bool = True
) -> pd.DataFrame:
    """
    Loads all .v files from clean and trojan directories, applies comment & keyword sanitization,
    and returns a pandas DataFrame with columns ['filename', 'code', 'label'].
    """
    sanitizer = VerilogSanitizer(filter_keywords=True)
    records: List[Tuple[str, str, int]] = []

    clean_path = Path(clean_dir)
    trojan_path = Path(trojan_dir)

    # 1. Load Clean (Golden) Designs -> Label 0
    if clean_path.exists():
        for f in clean_path.glob("*.v"):
            try:
                with open(f, "r", encoding="utf-8", errors="ignore") as file:
                    raw = file.read()
                code = sanitizer.sanitize(raw) if apply_sanitization else raw
                if code.strip():
                    records.append((f.name, code, 0))
            except Exception as e:
                print(f"Error reading clean file {f.name}: {e}")

    # 2. Load Trojan-infected Designs -> Label 1
    if trojan_path.exists():
        for f in trojan_path.glob("*.v"):
            try:
                with open(f, "r", encoding="utf-8", errors="ignore") as file:
                    raw = file.read()
                code = sanitizer.sanitize(raw) if apply_sanitization else raw
                if code.strip():
                    records.append((f.name, code, 1))
            except Exception as e:
                print(f"Error reading trojan file {f.name}: {e}")

    df = pd.DataFrame(records, columns=["filename", "code", "label"])
    print(f"[DataLoader] Loaded {len(df)} total samples ({sum(df['label'] == 0)} Clean, {sum(df['label'] == 1)} Trojan)")
    return df


def load_zenodo_dataset(
    zenodo_dir: str = "data/raw/zenodo",
    apply_sanitization: bool = True
) -> pd.DataFrame:
    """
    Loads the Hayashi & Ruggiero Zenodo dataset (DOI 10.5281/zenodo.11035341).
    Label rule from the dataset description: '<name>_T<n>.v' = trojan (1), otherwise golden (0).
    """
    import re
    sanitizer = VerilogSanitizer(filter_keywords=True)
    trojan_pattern = re.compile(r"_T\d+$")
    records: List[Tuple[str, str, int]] = []

    for f in Path(zenodo_dir).rglob("*.v"):
        try:
            raw = f.read_text(encoding="utf-8", errors="ignore")
            code = sanitizer.sanitize(raw) if apply_sanitization else raw
            if code.strip():
                label = 1 if trojan_pattern.search(f.stem) else 0
                records.append((f.name, code, label))
        except Exception as e:
            print(f"Error reading {f.name}: {e}")

    df = pd.DataFrame(records, columns=["filename", "code", "label"])
    before = len(df)
    df = df.drop_duplicates(subset="code").reset_index(drop=True)
    if before != len(df):
        print(f"[DataLoader] Removed {before - len(df)} duplicate files (same code in multiple folders)")
    print(f"[DataLoader] Zenodo: {len(df)} samples ({sum(df['label'] == 0)} Clean, {sum(df['label'] == 1)} Trojan)")
    return df
