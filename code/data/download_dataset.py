"""
Downloads the authors' public dataset from Zenodo:
  "Hardware Trojan Dataset of RISC-V and Web3 Generated with ChatGPT-4"
  Hayashi & Ruggiero, Data 2024, 9(6), 82.  DOI: 10.5281/zenodo.11035341

Labeling rule (from the Zenodo description):
  Files with "_T<number>" in the name are trojan-infected (e.g. fpgaminer_top_T0.v)
  Files without it are golden (clean) models (e.g. fpgaminer_top.v)

Usage:
    python data/download_dataset.py

If Zenodo keeps timing out, download the zips manually from
https://zenodo.org/records/11035341 into data/raw/zenodo/ and re-run this
script -- it will just extract them.
"""

import time
import zipfile
from pathlib import Path

import requests

RECORD_ID = "11035341"
API_URL = f"https://zenodo.org/api/records/{RECORD_ID}"
OUT_DIR = Path("data/raw/zenodo")
MAX_RETRIES = 5


def download_with_retry(url: str, dest: Path) -> bool:
    """Streams a file to disk, retrying on server errors / timeouts."""
    if dest.exists() and dest.stat().st_size > 0:
        print(f"   already downloaded: {dest.name}")
        return True

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            print(f"   downloading {dest.name} (attempt {attempt}/{MAX_RETRIES})...")
            with requests.get(url, stream=True, timeout=(30, 300)) as resp:
                resp.raise_for_status()
                tmp = dest.with_suffix(dest.suffix + ".part")
                with open(tmp, "wb") as f:
                    for chunk in resp.iter_content(chunk_size=1 << 16):
                        f.write(chunk)
                tmp.replace(dest)
            print(f"   saved: {dest.name}")
            return True
        except requests.RequestException as e:
            wait = 10 * attempt
            print(f"   failed ({e.__class__.__name__}: {e}). Retrying in {wait}s...")
            time.sleep(wait)

    print(f"   GAVE UP on {dest.name}. Download it manually from "
          f"https://zenodo.org/records/{RECORD_ID}")
    return False


def extract_zips():
    for z in OUT_DIR.glob("*.zip"):
        try:
            with zipfile.ZipFile(z) as zf:
                zf.extractall(OUT_DIR / z.stem)
            print(f"   extracted: {z.name}")
        except zipfile.BadZipFile:
            print(f"   corrupt zip, delete and re-download: {z.name}")


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"[Download] Fetching record metadata: {API_URL}")
    try:
        files = requests.get(API_URL, timeout=60).json().get("files", [])
    except requests.RequestException as e:
        print(f"[Download] Could not reach Zenodo: {e}")
        files = []
    print(f"[Download] Record lists {len(files)} file(s)")

    for f in files:
        name = f.get("key") or f.get("filename")
        url = f.get("links", {}).get("self") or f.get("links", {}).get("download")
        if name and url:
            download_with_retry(url, OUT_DIR / name)

    print("[Download] Extracting archives...")
    extract_zips()

    verilog = list(OUT_DIR.rglob("*.v"))
    trojans = [p for p in verilog if "_T" in p.stem]
    print(f"\n[Download] Done. {len(verilog)} Verilog files in {OUT_DIR}")
    print(f"           Golden: {len(verilog) - len(trojans)} | Trojan (_T): {len(trojans)}")


if __name__ == "__main__":
    main()
