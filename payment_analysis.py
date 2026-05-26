"""
Payment Success & Error Diagnostics Dashboard
Analysis Script for Nigerian Digital Payment Data

This script loads and analyzes payment transaction data to identify:
- Payment success/failure rates by step
- Geographic and demographic failure patterns
- Payment method reliability
- User cohort behavior
"""

import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime

# ============================================================================
# 1. LOAD DATA
# ============================================================================

data_path = Path('DATA FILES')

print("=" * 80)
print("PAYMENT SUCCESS & ERROR DIAGNOSTICS DASHBOARD")
print("Analysis Report")
print("=" * 80)
print()

# Load CSVs
users_df = pd.read_csv(data_path / 'dim_users.csv')
events_df = pd.read_csv(data_path / 'fact_app_events.csv')
transactions_df = pd.read_csv(data_path / 'fact_transactions.csv')

print(f"✓ Loaded {len(users_df)} users")
print(f"✓ Loaded {len(events_df)} transaction events")
print(f"✓ Loaded {len(transactions_df)} completed transactions")
print()

# ============================================================================
# 2. DATA PREPROCESSING
# ============================================================================

# Convert timestamps
events_df['timestamp'] = pd.to_datetime(events_df['timestamp'])
transactions_df['timestamp'] = pd.to_datetime(transactions_df['timestamp'])
users_df['signup_date'] = pd.to_datetime(users_df['signup_date'])

# ============================================================================
# 3. OVERALL SUCCESS METRICS
# ============================================================================

print("=" * 80)
print("1. OVERALL PAYMENT SUCCESS METRICS")
print("=" * 80)
print()

# Get the final step for each transaction
final_steps = events_df.sort_values('timestamp').groupby('transaction_id')['step'].last()

success_count = (final_steps == 'Transaction_Success').sum()
total_transactions = len(final_steps)
success_rate = (success_count / total_transactions * 100) if total_transactions > 0 else 0

print(f"Total Transactions Initiated: {total_transactions}")
print(f"Successful Transactions: {success_count}")
print(f"Failed Transactions: {total_transactions - success_count}")
print(f"Success Rate: {success_rate:.1f}%")
print()

# ============================================================================
# 4. FAILURE ANALYSIS BY TRANSACTION STEP
# ============================================================================

print("=" * 80)
print("2. FAILURE HOTSPOTS BY TRANSACTION STEP")
print("=" * 80)
print()

# Track which step people reach
steps_by_tx = events_df.groupby('transaction_id')['step'].apply(lambda x: x.iloc[-1] if len(x) > 0 else 'Unknown')
step_distribution = steps_by_tx.value_counts().sort_values(ascending=False)

print("Transaction Flow Step Distribution:")
print("-" * 50)
for step, count in step_distribution.items():
    pct = (count / len(steps_by_tx) * 100)
    print(f"  {step:<30} {count:>4} ({pct:>5.1f}%)")
print()

# Calculate drop-off at each step
step_sequence = ['Transaction_Initiated', 'Payment_Method_Selected', 'PIN_Entered', 'Transaction_Success']
step_counts = {}
for step in step_sequence:
    count = (events_df['step'] == step).sum()
    step_counts[step] = count

print("Cumulative User Progression:")
print("-" * 50)
cumulative = len(events_df)
for i, step in enumerate(step_sequence):
    if i == 0:
        print(f"  {step:<30} 100.0%")
    else:
        pct = (step_counts.get(step, 0) / step_counts.get(step_sequence[0], 1) * 100)
        print(f"  {step:<30} {pct:>5.1f}%")
print()

# ============================================================================
# 5. GEOGRAPHIC ANALYSIS
# ============================================================================

print("=" * 80)
print("3. GEOGRAPHIC FAILURE PATTERNS")
print("=" * 80)
print()

# Merge user location with transaction data
tx_with_location = events_df.merge(users_df[['user_id', 'location']], on='user_id', how='left')
tx_with_status = tx_with_location.sort_values('timestamp').groupby('transaction_id').agg({
    'step': 'last',
    'location': 'first'
}).reset_index()

tx_with_status['success'] = (tx_with_status['step'] == 'Transaction_Success').astype(int)

geo_summary = tx_with_status.groupby('location').agg({
    'transaction_id': 'count',
    'success': ['sum', 'mean']
}).round(3)
geo_summary.columns = ['Total_Tx', 'Successful_Tx', 'Success_Rate']
geo_summary['Success_Rate'] = (geo_summary['Success_Rate'] * 100).round(1)
geo_summary = geo_summary.sort_values('Success_Rate')

print("Success Rate by State:")
print("-" * 50)
for location, row in geo_summary.iterrows():
    print(f"  {location:<15} {int(row['Successful_Tx']):>4} / {int(row['Total_Tx']):>4}  ({row['Success_Rate']:>5.1f}%)")
print()

# ============================================================================
# 6. PAYMENT METHOD ANALYSIS
# ============================================================================

print("=" * 80)
print("4. PAYMENT METHOD RELIABILITY")
print("=" * 80)
print()

# Merge payment method
tx_with_method = events_df.merge(transactions_df[['transaction_id', 'payment_method']], 
                                 on='transaction_id', how='left')
tx_with_method = tx_with_method.sort_values('timestamp').groupby('transaction_id').agg({
    'step': 'last',
    'payment_method': 'first'
}).reset_index()
tx_with_method['success'] = (tx_with_method['step'] == 'Transaction_Success').astype(int)

method_summary = tx_with_method.groupby('payment_method').agg({
    'transaction_id': 'count',
    'success': ['sum', 'mean']
}).round(3)
method_summary.columns = ['Total_Tx', 'Successful_Tx', 'Success_Rate']
method_summary['Success_Rate'] = (method_summary['Success_Rate'] * 100).round(1)
method_summary = method_summary.sort_values('Success_Rate', ascending=False)

print("Success Rate by Payment Method:")
print("-" * 50)
for method, row in method_summary.iterrows():
    print(f"  {method:<20} {int(row['Successful_Tx']):>4} / {int(row['Total_Tx']):>4}  ({row['Success_Rate']:>5.1f}%)")
print()

# ============================================================================
# 7. DEMOGRAPHIC ANALYSIS
# ============================================================================

print("=" * 80)
print("5. USER DEMOGRAPHIC PATTERNS")
print("=" * 80)
print()

# Merge age groups
tx_with_demo = events_df.merge(users_df[['user_id', 'age_group']], on='user_id', how='left')
tx_with_demo = tx_with_demo.sort_values('timestamp').groupby('transaction_id').agg({
    'step': 'last',
    'age_group': 'first'
}).reset_index()
tx_with_demo['success'] = (tx_with_demo['step'] == 'Transaction_Success').astype(int)

demo_summary = tx_with_demo.groupby('age_group').agg({
    'transaction_id': 'count',
    'success': ['sum', 'mean']
}).round(3)
demo_summary.columns = ['Total_Tx', 'Successful_Tx', 'Success_Rate']
demo_summary['Success_Rate'] = (demo_summary['Success_Rate'] * 100).round(1)
demo_summary = demo_summary.sort_values('Success_Rate', ascending=False)

print("Success Rate by Age Group:")
print("-" * 50)
for age, row in demo_summary.iterrows():
    print(f"  {age:<10} {int(row['Successful_Tx']):>4} / {int(row['Total_Tx']):>4}  ({row['Success_Rate']:>5.1f}%)")
print()

# ============================================================================
# 8. SIGNUP CHANNEL ANALYSIS
# ============================================================================

print("=" * 80)
print("6. USER ACQUISITION CHANNEL PERFORMANCE")
print("=" * 80)
print()

# Merge signup channels
tx_with_channel = events_df.merge(users_df[['user_id', 'signup_channel']], on='user_id', how='left')
tx_with_channel = tx_with_channel.sort_values('timestamp').groupby('transaction_id').agg({
    'step': 'last',
    'signup_channel': 'first'
}).reset_index()
tx_with_channel['success'] = (tx_with_channel['step'] == 'Transaction_Success').astype(int)

channel_summary = tx_with_channel.groupby('signup_channel').agg({
    'transaction_id': 'count',
    'success': ['sum', 'mean']
}).round(3)
channel_summary.columns = ['Total_Tx', 'Successful_Tx', 'Success_Rate']
channel_summary['Success_Rate'] = (channel_summary['Success_Rate'] * 100).round(1)
channel_summary = channel_summary.sort_values('Success_Rate', ascending=False)

print("Success Rate by Signup Channel:")
print("-" * 50)
for channel, row in channel_summary.iterrows():
    print(f"  {channel:<10} {int(row['Successful_Tx']):>4} / {int(row['Total_Tx']):>4}  ({row['Success_Rate']:>5.1f}%)")
print()

# ============================================================================
# 9. TRANSACTION VALUE ANALYSIS
# ============================================================================

print("=" * 80)
print("7. TRANSACTION VALUE INSIGHTS")
print("=" * 80)
print()

# Merge with transaction amounts for completed transactions only
successful_tx = tx_with_status[tx_with_status['success'] == 1]['transaction_id'].values
tx_amounts = transactions_df[transactions_df['transaction_id'].isin(successful_tx)]['amount']

print(f"Successful Transactions: {len(successful_tx)}")
print(f"Average Transaction Value: ₦{tx_amounts.mean():,.0f}")
print(f"Median Transaction Value: ₦{tx_amounts.median():,.0f}")
print(f"Min Transaction Value: ₦{tx_amounts.min():,.0f}")
print(f"Max Transaction Value: ₦{tx_amounts.max():,.0f}")
print(f"Total Value Transacted: ₦{tx_amounts.sum():,.0f}")
print()

# ============================================================================
# 10. KEY RECOMMENDATIONS
# ============================================================================

print("=" * 80)
print("8. KEY RECOMMENDATIONS FOR PRODUCT TEAM")
print("=" * 80)
print()

# Identify bottlenecks
bottleneck_step = step_distribution.idxmax() if len(step_distribution) > 1 else "Unknown"
worst_geo = geo_summary['Success_Rate'].idxmin()
best_method = method_summary['Success_Rate'].idxmax()
worst_method = method_summary['Success_Rate'].idxmin()
worst_cohort = demo_summary['Success_Rate'].idxmin()

print(f"1. PIN ENTRY BOTTLENECK")
print(f"   Most transactions end at: {bottleneck_step}")
print(f"   → Recommendation: Implement biometric/OTP alternative to reduce friction")
print()

print(f"2. GEOGRAPHIC SUPPORT PRIORITY")
print(f"   Lowest success rate: {worst_geo} ({geo_summary.loc[worst_geo, 'Success_Rate']:.1f}%)")
print(f"   → Recommendation: Investigate network/infrastructure issues in this region")
print()

print(f"3. PAYMENT METHOD OPTIMIZATION")
print(f"   Most reliable: {best_method} ({method_summary.loc[best_method, 'Success_Rate']:.1f}%)")
print(f"   Least reliable: {worst_method} ({method_summary.loc[worst_method, 'Success_Rate']:.1f}%)")
print(f"   → Recommendation: Debug {worst_method}; promote {best_method} as default")
print()

print(f"4. USER RETENTION FOCUS")
print(f"   Highest churn cohort: {worst_cohort} age group ({demo_summary.loc[worst_cohort, 'Success_Rate']:.1f}% success)")
print(f"   → Recommendation: Build simplified UX for younger users; add error guidance")
print()

print("=" * 80)
print(f"Report Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("=" * 80)
