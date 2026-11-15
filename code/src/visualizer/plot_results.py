"""
Visualizer Module
Recreates Figure 7 (Accuracy vs. Recall scatter plot comparing NLP+ML vs LLM prompting)
and saves summary plots for submission/presentation.
"""

from pathlib import Path
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


def plot_accuracy_vs_recall(
    ml_results_df: pd.DataFrame, 
    llm_results_df: pd.DataFrame, 
    output_path: str = "results/accuracy_vs_recall_comparison.png"
):
    """
    Recreates Figure 7 from the paper:
    Graphical comparison of detection approaches (Accuracy vs Recall).
    """
    Path("results").mkdir(exist_ok=True)
    plt.figure(figsize=(10, 6), dpi=300)
    sns.set_theme(style="whitegrid")

    # Plot ML Models (Red / Coral dots)
    if "_acc_raw" in ml_results_df.columns:
        plt.scatter(
            ml_results_df["_acc_raw"], 
            ml_results_df["_rec_raw"], 
            color="#e74c3c", 
            s=90, 
            label="NLP Embeddings + ML Classifiers",
            alpha=0.8,
            edgecolors="black"
        )
        for _, row in ml_results_df.head(4).iterrows():
            plt.annotate(
                row["Model"].split()[0], 
                (row["_acc_raw"] + 0.3, row["_rec_raw"] - 0.5),
                fontsize=9
            )

    # Plot LLM Approaches (Different markers/colors)
    if "_acc" in llm_results_df.columns:
        colors = {"simple": "#3498db", "trusthub": "#9b59b6", "checklist": "#e67e22", "Role": "#2ecc71"}
        for _, row in llm_results_df.iterrows():
            plt.scatter(
                row["_acc"], 
                row["_rec"], 
                s=120, 
                marker="^",
                label=f"LLM: {row['Approach']}",
                alpha=0.9,
                edgecolors="black"
            )

    plt.title("Hardware Trojan Detection: Accuracy vs. Recall Comparison\n(Replication of Figure 7, Hayashi & Ruggiero 2025)", fontsize=13, pad=15)
    plt.xlabel("Accuracy (%)", fontsize=11)
    plt.ylabel("Recall (%)", fontsize=11)
    plt.xlim(50, 105)
    plt.ylim(50, 105)
    plt.legend(bbox_to_anchor=(1.05, 1), loc="upper left", fontsize=9)
    plt.tight_layout()

    plt.savefig(output_path, dpi=300)
    plt.close()
    print(f"[Visualizer] Saved comparison plot to: {output_path}")
