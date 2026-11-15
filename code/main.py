"""
Main Execution Script for Hardware Trojan Detection Project
Recreation of Hayashi & Ruggiero (IEEE Access 2025)

Usage:
    python main.py [--generate] [--eval-llm] [--model-name qwen2.5:3b]
"""

import argparse
from pathlib import Path
import pandas as pd

from data.seed_data import seed
from src.nlp_ml.dataset_loader import load_and_preprocess_dataset, load_zenodo_dataset, load_combined_dataset
from src.nlp_ml.train_models import evaluate_embeddings_and_models
from src.llm_eval.evaluator import LLMEvaluator
from src.synthetic_generator.generator import OllamaTrojanGenerator
from src.visualizer.plot_results import plot_accuracy_vs_recall


def main():
    parser = argparse.ArgumentParser(description="Hardware Trojan Detection Framework (IEEE Access 2025)")
    parser.add_argument("--generate", action="store_true", help="Generate synthetic trojans using local Ollama LLM")
    parser.add_argument("--eval-llm", action="store_true", help="Run LLM prompt engineering detection (Approach 2)")
    parser.add_argument("--provider", type=str, default="ollama", choices=["ollama", "groq", "openai"], help="LLM API provider (default: ollama)")
    parser.add_argument("--model-name", type=str, default="qwen2.5:3b", help="Model name (e.g., qwen2.5:3b or openai/gpt-oss-120b)")
    parser.add_argument("--n-splits", type=int, default=5, help="Number of CV folds (default: 5, paper uses 10)")
    parser.add_argument("--llm-samples", type=int, default=20, help="Number of samples to evaluate for LLM (default: 20 balanced, 0 for all)")
    args = parser.parse_args()

    print("=" * 80)
    print(" HARDWARE TROJAN DETECTION IN OPEN-SOURCE HARDWARE DESIGNS USING ML & LLM")
    print("=" * 80)

    # 1. Check / Seed Initial Data
    golden_dir = Path("data/raw/golden")
    trojan_dir = Path("data/raw/trojans")
    if not golden_dir.exists() or len(list(golden_dir.glob("*.v"))) == 0:
        print("[Main] No seed data found. Populating seed hardware designs...")
        seed()

    # 2. Optional: Generate Synthetic Trojans with Local Ollama Qwen
    if args.generate:
        print("\n" + "-" * 70)
        print(f" GENERATING SYNTHETIC TROJANS VIA OLLAMA ({args.model_name})...")
        print("-" * 70)
        generator = OllamaTrojanGenerator(model_name=args.model_name)
        generator.batch_generate(golden_dir=str(golden_dir), output_dir=str(trojan_dir))

    # 3. Load and Sanitize Dataset
    print("\n" + "-" * 70)
    print(" PREPROCESSING & SANITIZING DATASET...")
    print("-" * 70)
    df = load_combined_dataset(
        zenodo_dir="data/raw/zenodo",
        clean_dir="data/raw/golden",
        trojan_dir="data/raw/trojans"
    )

    if len(df) == 0:
        print("[Error] No Verilog files found to train on. Exiting.")
        return

    # 4. Approach 1: NLP + Classical ML Classifiers (TF-IDF & BoW)
    print("\n" + "-" * 70)
    print(" APPROACH 1: NLP EMBEDDINGS + CLASSICAL ML CLASSIFIERS")
    print("-" * 70)
    tfidf_results, vectorizer, ml_models = evaluate_embeddings_and_models(
        df, embedding_type="tfidf", max_features=1000, n_splits=args.n_splits
    )
    bow_results, _, _ = evaluate_embeddings_and_models(
        df, embedding_type="bow", max_features=1000, n_splits=args.n_splits
    )

    Path("results").mkdir(exist_ok=True)
    tfidf_results.to_csv("results/tfidf_results.csv", index=False)
    bow_results.to_csv("results/bow_results.csv", index=False)
    print("[Main] Exported results to 'results/tfidf_results.csv' and 'results/bow_results.csv'")

    # 5. Approach 2: LLM Prompt Engineering Evaluation
    llm_results = None
    if args.eval_llm:
        print("\n" + "-" * 70)
        print(f" APPROACH 2: LLM PROMPT-ENGINEERED DETECTION ({args.model_name})")
        print("-" * 70)
        
        # Prepare evaluation dataset
        if args.llm_samples > 0 and args.llm_samples < len(df):
            n_per_class = args.llm_samples // 2
            df_clean = df[df["label"] == 0].sample(min(n_per_class, sum(df["label"] == 0)), random_state=42)
            df_trojan = df[df["label"] == 1].sample(min(n_per_class, sum(df["label"] == 1)), random_state=42)
            eval_df = pd.concat([df_clean, df_trojan]).reset_index(drop=True)
            print(f"[LLM Eval] Selected balanced subset of {len(eval_df)} samples ({sum(eval_df['label']==0)} Clean, {sum(eval_df['label']==1)} Trojan)")
        else:
            eval_df = df
            print(f"[LLM Eval] Evaluating full dataset ({len(eval_df)} samples)")

        evaluator = LLMEvaluator(model_name=args.model_name, provider=args.provider)
        llm_results = evaluator.run_all_strategies(eval_df)
        llm_results.to_csv("results/llm_results.csv", index=False)
        print("[Main] Exported LLM results to 'results/llm_results.csv'")

    # 6. Recreate Figure 7 (Visualizations)
    print("\n" + "-" * 70)
    print(" GENERATING SUMMARY PLOTS...")
    print("-" * 70)
    plot_accuracy_vs_recall(
        ml_results_df=tfidf_results,
        llm_results_df=llm_results if llm_results is not None else tfidf_results.head(1),
        output_path="results/accuracy_vs_recall_comparison.png"
    )

    print("\n" + "=" * 80)
    print(" [DONE] Pipeline finished successfully! Check 'results/' for charts.")
    print("=" * 80)


if __name__ == "__main__":
    main()
