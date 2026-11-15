# Hardware Trojan Detection in Open-Source Hardware Designs Using Machine Learning

Replication and Implementation of the research paper by Victor Takashi Hayashi and Wilson Vicente Ruggiero (*IEEE Access*, 2025).

---

## 🚀 Quick Start Guide

### 1. Install Dependencies
```powershell
pip install -r requirements.txt
```

### 2. Run NLP + Machine Learning Pipeline (Approach 1)
Trains Decision Tree, Extra Trees, Random Forest, XGBoost, and other classifiers using TF-IDF & BoW features with Cross-Validation:
```powershell
python main.py
```

### 3. Run LLM Zero-Shot Detection (Approach 2) using Local Ollama Qwen
Evaluates the 4 Prompt Strategies (Simple, TrustHub, Checklist, Role-Playing Security Analyst) through your local Ollama `qwen2.5:3b`:
```powershell
python main.py --eval-llm
```

### 4. (Optional) Generate Synthetic Hardware Trojans
Uses your local Ollama `qwen2.5:3b` to insert stealthy hardware trojans into clean Verilog golden models:
```powershell
python main.py --generate --eval-llm
```

---

## 📁 Project Structure

```text
code/
├── data/
│   ├── raw/
│   │   ├── golden/               # Clean Verilog designs (RISC-V ALU, UART, AES, Register File, MAC)
│   │   └── trojans/              # Trojan-infected Verilog designs
│   └── seed_data.py              # Script populating initial benchmark designs
├── src/
│   ├── preprocessor/
│   │   └── sanitizer.py          # Strips comments & giveaway keywords ('trojan', 'trigger', etc.)
│   ├── synthetic_generator/
│   │   └── generator.py          # Red-teaming trojan generator using local Ollama LLM
│   ├── nlp_ml/
│   │   ├── dataset_loader.py     # Loads, sanitizes, and balances datasets
│   │   └── train_models.py       # TF-IDF & BoW feature extractor + 11 ML models with CV
│   ├── llm_eval/
│   │   ├── prompts.py            # Exact prompt templates from Paper Section IV-A & Appendix A
│   │   └── evaluator.py          # Evaluates 4 prompt strategies against local LLM
│   └── visualizer/
│       └── plot_results.py       # Recreates Figure 7 (Accuracy vs. Recall scatter plot)
├── results/                      # Output figures and evaluation tables
├── requirements.txt
├── main.py                       # Master CLI entrypoint
└── README.md
```
