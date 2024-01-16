import requests
import sys
import json
import os
import csv

def get_contract_source_code(eth_address, api_key):
    url = f"https://api.etherscan.io/api?module=contract&action=getsourcecode&address={eth_address}&apikey={api_key}"
    response = requests.get(url)
    data = response.json()
    
    if data['status'] == '1' and data['message'] == 'OK':
        return data['result'][0]
    else:
        return None

def save_single_file(eth_address, source_code):
    file_name = f"dataset/contracts/{eth_address}.sol"
    with open(file_name, "w") as file:
        file.write(source_code)

def save_multiple_files(eth_address, contract_data):
    folder_name = f"dataset/contracts/{eth_address}"
    os.makedirs(folder_name, exist_ok=True)

    sc = contract_data['SourceCode']
    if sc[1] == '{':
        source_code = json.loads(sc[0] + sc[2:-2] + sc[-1])
    else:
        source_code = json.loads(sc)

    # Save settings
    settings = source_code.get("settings", {})
    with open(f"{folder_name}/settings.json", "w") as settings_file:
        json.dump(settings, settings_file, indent=4)

    # Save source files
    
    for file_name, file_content in source_code['sources'].items() if 'sources' in source_code else source_code.items():
        if file_name.startswith("/"):
            file_name = file_name[1:]
        file_path = os.path.join(folder_name, file_name)  # Construct the file path
        os.makedirs(os.path.dirname(file_path), exist_ok=True)  # Create the directory if it doesn't exist
        with open(file_path, "w") as source_file:
            source_file.write(file_content['content'])

def main():
    if len(sys.argv) < 2:
        print("Usage: python script.py <ETHERSCAN_API_KEY>")
        sys.exit(1)

    etherscan_api_key = sys.argv[1]
    file_path = 'dataset/data/addresses.csv'

    count_processed = 0
    count_skipped = 0

    with open(file_path, 'r') as file:
        reader = csv.reader(file)
        # start at line 2560
        for _ in range(3250):
            next(reader)
        for row in reader:
            eth_address = row[0].strip()

            # check if sol file or folder already exists
            if os.path.exists(f"dataset/contracts/{eth_address}.sol"): # or os.path.exists(f"dataset/contracts/{eth_address}"):
                count_processed += 1
                continue
            try:
                contract_data = get_contract_source_code(eth_address, etherscan_api_key)
                if contract_data and contract_data['SourceCode']:
                    count_processed += 1
                    if contract_data['SourceCode'].startswith('{'):
                        # Multiple files in JSON format
                        save_multiple_files(eth_address, contract_data)
                    else:
                        # Single Solidity file
                        save_single_file(eth_address, contract_data['SourceCode'])
                    print(count_processed, count_skipped, f"Processed contract for {eth_address}")
                else:
                    count_skipped += 1
                    print(count_processed, count_skipped, f"No verified source code found for {eth_address}")
            except Exception as e:
                count_skipped += 1
                print(count_processed, count_skipped, f"Error processing contract for {eth_address}: {e}")
                with open("dataset/data/addresses_skipped.csv", "a") as file:
                    file.write(f"{eth_address}\n")  
if __name__ == "__main__":
    main()
