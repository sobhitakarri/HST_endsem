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


def load_combined_dataset(
    zenodo_dir: str = "data/raw/zenodo",
    clean_dir: str = "data/raw/golden",
    trojan_dir: str = "data/raw/trojans",
    apply_sanitization: bool = True
) -> pd.DataFrame:
    """
    Loads and merges all datasets: Zenodo benchmarks (RISC-V, Web3, Wallet),
    expanded open-source golden designs, and trojan designs.
    Removes duplicates and attaches design groups for robust evaluation.
    """
    frames = []

    # 1. Zenodo benchmark dataset
    zenodo_path = Path(zenodo_dir)
    if zenodo_path.exists() and any(zenodo_path.rglob("*.v")):
        df_z = load_zenodo_dataset(zenodo_dir=zenodo_dir, apply_sanitization=apply_sanitization)
        frames.append(df_z)

    # 2. Expanded golden & trojan designs
    clean_path = Path(clean_dir)
    trojan_path = Path(trojan_dir)
    if clean_path.exists() or trojan_path.exists():
        df_local = load_and_preprocess_dataset(clean_dir=clean_dir, trojan_dir=trojan_dir, apply_sanitization=apply_sanitization)
        frames.append(df_local)

    if not frames:
        return pd.DataFrame(columns=["filename", "code", "label", "group"])

    combined = pd.concat(frames, ignore_index=True)
    before = len(combined)
    combined = combined.drop_duplicates(subset="code").reset_index(drop=True)
    if before != len(combined):
        print(f"[DataLoader] Removed {before - len(combined)} duplicate files across merged datasets")

    # Attach base design group (strip _T<n>, _trojan*, etc.)
    combined["group"] = combined["filename"].str.replace(r"_T\d+.*\.v$", "", regex=True)\
                                            .str.replace(r"_trojan.*\.v$", "", regex=True)\
                                            .str.replace(r"_infected.*\.v$", "", regex=True)\
                                            .str.replace(r"\.v$", "", regex=True)

    n_clean = int((combined["label"] == 0).sum())
    n_trojan = int((combined["label"] == 1).sum())
    print(f"[DataLoader] Complete Unified Dataset: {len(combined)} samples ({n_clean} Clean, {n_trojan} Trojan, {combined['group'].nunique()} Unique Hardware Core Groups)")
    return combined

