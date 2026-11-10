from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt

# Update this path to your folder containing the CSV files.
PROJECT_DIR = Path(__file__).resolve().parent.parent

DATA_DIR = PROJECT_DIR / "data"
OUTPUT_DIR = PROJECT_DIR / "visuals"

accounts = pd.read_csv(DATA_DIR / "ravenstack_accounts.csv")
subscriptions = pd.read_csv(DATA_DIR / "ravenstack_subscriptions.csv")
feature_usage = pd.read_csv(DATA_DIR / "ravenstack_feature_usage.csv")
support_tickets = pd.read_csv(DATA_DIR / "ravenstack_support_tickets.csv")
churn_events = pd.read_csv(DATA_DIR / "ravenstack_churn_events.csv")

# Check dataset dimensions.
datasets = {
    "Accounts": accounts,
    "Subscriptions": subscriptions,
    "Feature Usage": feature_usage,
    "Support Tickets": support_tickets,
    "Churn Events": churn_events,
}

for name, df in datasets.items():
    print(f"{name}: {df.shape[0]:,} rows, {df.shape[1]} columns")

# Check the account churn baseline.
print("\nAccount churn summary:")
print(accounts["churn_flag"].value_counts(dropna=False))

churn_rate = accounts["churn_flag"].astype(str).str.strip().str.lower().eq("true").mean() * 100

print(f"Account churn rate: {churn_rate:.2f}%")


# Churn rate by industry
accounts["churned"] = (
    accounts["churn_flag"]
    .astype(str)
    .str.strip()
    .str.lower()
    .eq("true")
)

industry_churn = (
    accounts.groupby("industry")
    .agg(
        account_count=("account_id", "count"),
        churned_accounts=("churned", "sum")
    )
    .reset_index()
)

industry_churn["churn_rate_pct"] = (
    industry_churn["churned_accounts"]
    / industry_churn["account_count"]
    * 100
)

industry_churn = industry_churn.sort_values(
    "churn_rate_pct", ascending=False
)

print("\nChurn Rate by Industry:")
print(industry_churn.round(2).to_string(index=False))


# Visualize churn rate by industry
plt.figure(figsize=(10, 6))

plt.bar(
    industry_churn["industry"],
    industry_churn["churn_rate_pct"]
)

plt.title("Customer Churn Rate by Industry")
plt.xlabel("Industry")
plt.ylabel("Churn Rate (%)")
plt.ylim(0, 35)
plt.xticks(rotation=25, ha="right")

plt.tight_layout()

# Save the chart to the visuals folder
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

plt.savefig(
    OUTPUT_DIR / "churn_rate_by_industry.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()


# Churn rate by trial status
trial_churn = (
    accounts.groupby("is_trial")
    .agg(
        account_count=("account_id", "count"),
        churned_accounts=("churned", "sum")
    )
    .reset_index()
)

trial_churn["churn_rate_pct"] = (
    trial_churn["churned_accounts"]
    / trial_churn["account_count"]
    * 100
)

trial_churn["customer_type"] = trial_churn["is_trial"].map({
    True: "Trial",
    False: "Non-Trial",
    "True": "Trial",
    "False": "Non-Trial",
    1: "Trial",
    0: "Non-Trial"
})

print("\nChurn Rate by Trial Status:")
print(
    trial_churn[
        ["customer_type", "account_count",
         "churned_accounts", "churn_rate_pct"]
    ].round(2).to_string(index=False)
)


# Visualize churn rate by trial status
plt.figure(figsize=(7, 5))

plt.bar(
    trial_churn["customer_type"],
    trial_churn["churn_rate_pct"]
)

plt.title("Customer Churn Rate: Trial vs. Non-Trial")
plt.xlabel("Customer Type")
plt.ylabel("Churn Rate (%)")
plt.ylim(0, 30)

plt.tight_layout()

plt.savefig(
    OUTPUT_DIR / "churn_rate_by_trial_status.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()


# Subscription churn by plan and billing frequency

# Normalize churn flags in case they were imported as strings
subscriptions["churned"] = (
    subscriptions["churn_flag"]
    .astype(str)
    .str.strip()
    .str.lower()
    .eq("true")
)

plan_billing_churn = (
    subscriptions.groupby(["plan_tier", "billing_frequency"])
    .agg(
        subscription_count=("subscription_id", "count"),
        churned_subscriptions=("churned", "sum"),
        avg_mrr=("mrr_amount", "mean")
    )
    .reset_index()
)

plan_billing_churn["churn_rate_pct"] = (
    plan_billing_churn["churned_subscriptions"]
    / plan_billing_churn["subscription_count"]
    * 100
)

plan_billing_churn = plan_billing_churn.sort_values(
    "churn_rate_pct", ascending=False
)

print("\nSubscription Churn by Plan and Billing Frequency:")
print(
    plan_billing_churn.round(2).to_string(index=False)
)


# Visualize subscription churn by plan and billing frequency
pivot_churn = plan_billing_churn.pivot(
    index="plan_tier",
    columns="billing_frequency",
    values="churn_rate_pct"
)

# Keep plans in a consistent order
pivot_churn = pivot_churn.reindex(
    ["Basic", "Pro", "Enterprise"]
)

pivot_churn.plot(
    kind="bar",
    figsize=(9, 6)
)

plt.title("Subscription Churn by Plan and Billing Frequency")
plt.xlabel("Subscription Plan")
plt.ylabel("Churn Rate (%)")
plt.xticks(rotation=0)
plt.ylim(0, 13)
plt.legend(title="Billing Frequency")
plt.tight_layout()

plt.savefig(
    OUTPUT_DIR / "subscription_churn_by_plan_billing.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()


# Support escalations by account churn status

# Standardize escalation flags
support_tickets["escalated"] = (
    support_tickets["escalation_flag"]
    .astype(str)
    .str.strip()
    .str.lower()
    .eq("true")
)

# Identify accounts with at least one escalated ticket
escalated_accounts = (
    support_tickets.groupby("account_id")["escalated"]
    .any()
    .reset_index()
    .rename(columns={"escalated": "has_escalation"})
)

# Combine escalation data with account churn status
account_support = accounts[
    ["account_id", "churned"]
].merge(
    escalated_accounts,
    on="account_id",
    how="left"
)

account_support["has_escalation"] = (
    account_support["has_escalation"]
    .fillna(False)
)

support_churn_summary = (
    account_support.groupby("churned")
    .agg(
        account_count=("account_id", "count"),
        accounts_with_escalations=("has_escalation", "sum")
    )
    .reset_index()
)

support_churn_summary["escalation_rate_pct"] = (
    support_churn_summary["accounts_with_escalations"]
    / support_churn_summary["account_count"]
    * 100
)

support_churn_summary["customer_status"] = (
    support_churn_summary["churned"]
    .map({True: "Churned", False: "Retained"})
)

print("\nAccount-Level Escalation Rate by Churn Status:")
print(
    support_churn_summary[
        ["customer_status", "account_count",
         "accounts_with_escalations", "escalation_rate_pct"]
    ].round(2).to_string(index=False)
)


# Visualize account-level escalation rates
support_churn_summary = support_churn_summary.sort_values(
    "customer_status",
    ascending=False
)

plt.figure(figsize=(7, 5))

plt.bar(
    support_churn_summary["customer_status"],
    support_churn_summary["escalation_rate_pct"]
)

plt.title("Accounts with Escalated Support Tickets")
plt.xlabel("Customer Status")
plt.ylabel("Accounts with Escalations (%)")
plt.ylim(0, 25)

plt.tight_layout()

plt.savefig(
    OUTPUT_DIR / "support_escalation_by_churn.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()


# Product usage by account churn status

# Aggregate usage records to the account level
usage_by_account = (
    feature_usage
    .merge(
        subscriptions[["subscription_id", "account_id"]],
        on="subscription_id",
        how="left"
    )
    .groupby("account_id")
    .agg(
        total_usage=("usage_count", "sum"),
        usage_records=("usage_id", "count"),
        total_duration_secs=("usage_duration_secs", "sum"),
        total_errors=("error_count", "sum")
    )
    .reset_index()
)

# Add account churn status
usage_with_churn = usage_by_account.merge(
    accounts[["account_id", "churned"]],
    on="account_id",
    how="left"
)

# Compare average usage metrics
usage_churn_summary = (
    usage_with_churn.groupby("churned")
    .agg(
        account_count=("account_id", "count"),
        avg_total_usage=("total_usage", "mean"),
        avg_usage_records=("usage_records", "mean"),
        avg_total_duration_secs=("total_duration_secs", "mean"),
        avg_total_errors=("total_errors", "mean")
    )
    .reset_index()
)

usage_churn_summary["customer_status"] = (
    usage_churn_summary["churned"]
    .map({True: "Churned", False: "Retained"})
)

usage_churn_summary["avg_usage_per_record"] = (
    usage_churn_summary["avg_total_usage"]
    / usage_churn_summary["avg_usage_records"]
)

print("\nProduct Usage by Churn Status:")
print(
    usage_churn_summary[
        ["customer_status", "account_count", "avg_total_usage",
         "avg_usage_records", "avg_usage_per_record",
         "avg_total_duration_secs", "avg_total_errors"]
    ].round(2).to_string(index=False)
)


# Visualize average total product usage
usage_churn_summary = usage_churn_summary.sort_values(
    "customer_status",
    ascending=False
)

plt.figure(figsize=(7, 5))

plt.bar(
    usage_churn_summary["customer_status"],
    usage_churn_summary["avg_total_usage"]
)

plt.title("Average Product Usage by Customer Status")
plt.xlabel("Customer Status")
plt.ylabel("Average Total Usage per Account")

plt.tight_layout()

plt.savefig(
    OUTPUT_DIR / "product_usage_by_churn.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()


# Churn reasons and refunds

refunds_by_reason = (
    churn_events.groupby("reason_code")
    .agg(
        churn_events=("churn_event_id", "count"),
        unique_accounts=("account_id", "nunique"),
        total_refunds=("refund_amount_usd", "sum"),
        avg_refund=("refund_amount_usd", "mean")
    )
    .reset_index()
)

refunds_by_reason["refund_share_pct"] = (
    refunds_by_reason["total_refunds"]
    / refunds_by_reason["total_refunds"].sum()
    * 100
)

refunds_by_reason = refunds_by_reason.sort_values(
    "total_refunds", ascending=False
)

print("\nChurn Reasons and Refunds:")
print(
    refunds_by_reason.round(2).to_string(index=False)
)

print(
    f"\nTotal refunds: "
    f"${refunds_by_reason['total_refunds'].sum():,.2f}"
)


# Visualize total refunds by churn reason
refunds_chart = refunds_by_reason.sort_values(
    "total_refunds",
    ascending=True
)

plt.figure(figsize=(9, 6))

plt.barh(
    refunds_chart["reason_code"],
    refunds_chart["total_refunds"]
)

plt.title("Total Refunds by Churn Reason")
plt.xlabel("Total Refunds ($)")
plt.ylabel("Churn Reason")

plt.tight_layout()

plt.savefig(
    OUTPUT_DIR / "refunds_by_churn_reason.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()


# Executive Summary

overall_churn_rate = accounts["churned"].mean() * 100

industry_summary = industry_churn.sort_values(
    "churn_rate_pct", ascending=False
)
highest_churn_industry = industry_summary.iloc[0]

trial_summary = trial_churn.set_index("customer_type")
trial_rate = trial_summary.loc["Trial", "churn_rate_pct"]
non_trial_rate = trial_summary.loc["Non-Trial", "churn_rate_pct"]

highest_refund_reason = refunds_by_reason.iloc[0]

print("\n" + "=" * 50)
print("RAVENSTACK CUSTOMER CHURN — EXECUTIVE SUMMARY")
print("=" * 50)

print(f"Total accounts analyzed: {len(accounts):,}")
print(f"Overall account churn rate: {overall_churn_rate:.2f}%")

print(
    f"\nHighest-churn industry: {highest_churn_industry['industry']} "
    f"({highest_churn_industry['churn_rate_pct']:.2f}%)"
)

print(
    f"Trial account churn rate: {trial_rate:.2f}%"
)
print(
    f"Non-trial account churn rate: {non_trial_rate:.2f}%"
)
print(
    f"Difference: {trial_rate - non_trial_rate:.2f} percentage points"
)

print(
    f"\nHighest-refund churn reason: "
    f"{highest_refund_reason['reason_code']}"
)
print(
    f"Refunds for this reason: "
    f"${highest_refund_reason['total_refunds']:,.2f}"
)

print(
    f"\nTotal recorded refunds: "
    f"${refunds_by_reason['total_refunds'].sum():,.2f}"
)

print("\nRecommended areas for further investigation:")
print("- Investigate churn patterns among DevTools accounts.")
print("- Review trial onboarding and early product activation.")
print("- Investigate feature-related churn and unknown churn reasons.")
print("- Examine escalated support cases and their timing relative to churn.")

print("\nNote: This is a synthetic dataset.")
print("Findings are descriptive and do not establish causation.")
print("=" * 50)
