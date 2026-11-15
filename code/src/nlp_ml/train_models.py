"""
Machine Learning Training & Evaluation Module (Approach 1: NLP + Classical ML)
Recreates Tables 2, 3, and 7 from the paper:
- Evaluates BoW (Bag-of-Words) and TF-IDF word embeddings (1,000 features).
- Trains 11 Classical Classifiers using 10-fold Cross-Validation.
- Outputs Accuracy, Recall, Precision, and F1-score tables.
"""

from typing import Dict, Any, Tuple
import numpy as np
import pandas as pd
from tabulate import tabulate

from sklearn.feature_extraction.text import CountVectorizer, TfidfVectorizer
from sklearn.model_selection import StratifiedKFold, cross_validate
from imblearn.over_sampling import RandomOverSampler
from imblearn.pipeline import Pipeline as ImbPipeline
from sklearn.base import clone
from sklearn.preprocessing import FunctionTransformer

# Classifiers evaluated in paper
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import (
    ExtraTreesClassifier,
    RandomForestClassifier,
    GradientBoostingClassifier,
    AdaBoostClassifier,
)
from sklearn.linear_model import LogisticRegression, RidgeClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.svm import SVC
from sklearn.naive_bayes import GaussianNB
from sklearn.discriminant_analysis import (
    LinearDiscriminantAnalysis,
    QuadraticDiscriminantAnalysis,
)

try:
    from xgboost import XGBClassifier
    HAS_XGB = True
except ImportError:
    HAS_XGB = False


def get_models() -> Dict[str, Any]:
    """Returns the exact dictionary of ML models evaluated in Tables 1, 2, and 3."""
    models = {
        "Decision Tree Classifier": DecisionTreeClassifier(random_state=42),
        "Extra Trees Classifier": ExtraTreesClassifier(n_estimators=100, random_state=42),
        "Random Forest Classifier": RandomForestClassifier(n_estimators=100, random_state=42),
        "Gradient Boosting Classifier": GradientBoostingClassifier(random_state=42),
        "Ada Boost Classifier": AdaBoostClassifier(random_state=42),
        "Logistic Regression": LogisticRegression(max_iter=1000, random_state=42),
        "Ridge Classifier": RidgeClassifier(random_state=42),
        "K Neighbors Classifier": KNeighborsClassifier(n_neighbors=5),
        "SVM - Linear Kernel": SVC(kernel="linear", random_state=42),
        "Linear Discriminant Analysis": LinearDiscriminantAnalysis(),
        "Naive Bayes": GaussianNB(),
    }
    if HAS_XGB:
        models["Extreme Gradient Boosting"] = XGBClassifier(
            eval_metric="logloss", random_state=42
        )
    return models


def evaluate_embeddings_and_models(
    df: pd.DataFrame, 
    embedding_type: str = "tfidf", 
    max_features: int = 1000,
    n_splits: int = 10
) -> Tuple[pd.DataFrame, Any, Any]:
    """
    Extracts features (BoW or TF-IDF), balances classes via oversampling,
    and runs n_splits-fold cross validation on all ML models.
    """
    print(f"\n" + "="*70)
    print(f" EVALUATING NLP + ML PIPELINE: {embedding_type.upper()} ({max_features} features)")
    print("="*70)

    # 1. Feature Extraction (BoW or TF-IDF)
    if embedding_type.lower() == "bow":
        vectorizer = CountVectorizer(
            max_features=max_features,
            token_pattern=r"(?u)\b\w+\b"
        )
    else:
        vectorizer = TfidfVectorizer(
            max_features=max_features,
            token_pattern=r"(?u)\b\w+\b"
        )

    X = df["code"].values
    y = df["label"].values
    print(f"Samples: {len(y)} (Class 0: {sum(y==0)}, Class 1: {sum(y==1)})")
    print("Oversampling is applied INSIDE each training fold only (no test leakage).")

    # 2. Stratified Cross-Validation
    cv = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=42)
    scoring = ["accuracy", "recall", "precision", "f1"]

    results = []
    models = get_models()

    for name, model in models.items():
        try:
            # vectorize -> dense -> oversample -> classify, all re-fit per fold
            pipe = ImbPipeline([
                ("vec", clone(vectorizer)),
                ("dense", FunctionTransformer(lambda m: m.toarray(), accept_sparse=True)),
                ("ros", RandomOverSampler(random_state=42)),
                ("clf", model),
            ])
            scores = cross_validate(pipe, X, y, cv=cv, scoring=scoring, n_jobs=1)
            acc = np.mean(scores["test_accuracy"]) * 100
            rec = np.mean(scores["test_recall"]) * 100
            prec = np.mean(scores["test_precision"]) * 100
            f1 = np.mean(scores["test_f1"]) * 100

            results.append({
                "Model": name,
                "Accuracy": f"{acc:.2f}%",
                "Recall": f"{rec:.2f}%",
                "Precision": f"{prec:.2f}%",
                "f1-score": f"{f1:.2f}%",
                "_acc_raw": acc,
                "_rec_raw": rec,
                "_f1_raw": f1
            })
        except Exception as e:
            print(f"Error training {name}: {e}")

    results_df = pd.DataFrame(results).sort_values(by="_acc_raw", ascending=False)
    
    # Format and print clean table
    display_df = results_df[["Model", "Accuracy", "Recall", "f1-score"]]
    print("\n" + tabulate(display_df, headers="keys", tablefmt="github", showindex=False))

    return results_df, vectorizer, models
