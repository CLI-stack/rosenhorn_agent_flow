import pandas as pd
import sys
# Define the file path and name of the existing CSV file
#existing_file_path =  "/proj/cmb_pnr_vol21/leonz/timing_classification_450/feature_extract_"+sys.argv[1]+".csv"
existing_file_path =  sys.argv[2]+"/feature_extract_"+sys.argv[1]+".csv"

# Read the existing CSV file into a DataFrame
try:
    existing_df = pd.read_csv(existing_file_path)
except pd.errors.EmptyDataError:
    print(f"Error: The file '{existing_file_path}' is empty.")
    exit(1)

# Get the number of rows from the existing DataFrame
num_rows = len(existing_df)

# Define the file path and name for the new CSV file
new_file_path = sys.argv[2]+"/margin_info_"+sys.argv[1]+".csv"

# Create a DataFrame with a "skew" column filled with zeros
new_df = pd.DataFrame({'skew_margin_overslack': [0] * num_rows})

# Save the new DataFrame to a new CSV file
new_df.to_csv(new_file_path, index=False)

print(f"CSV file '{new_file_path}' created with 'skew_margin_overslack' column filled with zeros based on the existing file.")

