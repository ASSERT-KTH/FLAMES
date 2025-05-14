import os
import json
import subprocess


def get_files(directory):
    all_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".sol"):
                all_files.append((os.path.join(root, file),file))
    return all_files

def find_occurrences(file_path, search_text):
    with open(file_path, "r", encoding="utf-8") as file:
        content = file.read()  
    line_numbers = []
    lines = content.split("\n")  
    for line_number, line in enumerate(lines, start=1):
        if search_text in line:
            line_numbers.append(line_number) 
    return content, line_numbers

def replace_lines_with_string(contract_code, lines_to_replace, string):
    """
    Replace specified lines in the contract code with blank lines.
    
    Parameters:
    - contract_code (str): The original Solidity contract code as a string.
    - lines_to_replace (list): A list of line numbers (1-based) to replace with blank lines.
    - string (str): The string to replace the specified lines with.

    Returns:
    - str: The contract code with the specified lines replaced by blank lines.
    """
    # Split the contract code into lines
    contract_lines = contract_code.splitlines() #from string to list of lines (change the numeration)
    
    # Replace the specified lines with a blank line
    for line_number in lines_to_replace:
        # Adjust for 0-based index
        if line_number - 1 < len(contract_lines):
            contract_lines[line_number - 1] = string
    
    # Join the lines back into a formatted string
    formatted_contract_code = "\n".join(contract_lines)
    
    return formatted_contract_code 

def print_json_report(folder, data):

    if os.path.exists(folder):
        os.remove(folder)
    # Write the compilation reports to the file
    with open(folder, "w") as file:
        json.dump(data, file, indent=4)

import json
import os

def read_json_report(filepath):
    """
    Reads a JSON file and reconstructs the original data structure.

    Args:
        filepath (str): Path to the JSON file.

    Returns:
        dict or list: Parsed JSON data, depending on the original structure.

    Raises:
        FileNotFoundError: If the file does not exist.
        json.JSONDecodeError: If the file is not a valid JSON.
    """
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"The file '{filepath}' does not exist.")

    with open(filepath, "r") as file:
        data = json.load(file)
    
    return data


def find_contract_path(repo_root, contract_name):
    """
    Search for a Solidity contract file with the given name in the repo.

    Args:
        repo_root (str): Root directory of the repo.
        contract_name (str): Name of the contract file (e.g., 'MyContract.sol').

    Returns:
        str: Full path to the contract file, or None if not found.
    """
    for dirpath, _, filenames in os.walk(repo_root):
        for file in filenames:
            if file == contract_name:
                return os.path.join(dirpath, file)
    return None

def print_txt_report(folder, data):

    if os.path.exists(folder):
        os.remove(folder)
    # Write the compilation reports to the file
    with open(folder, "w") as file:
        for contract_name, contract, line in data:
            file.write(f"Contract: {contract_name}\n")
            file.write(f"Lines: {line}\n")
            file.write(f"{contract}\n\n")
            file.write("***END OF CONTRACT***\n\n")
                
def evaluate_contracts(contract_lines, patch):
    if not os.path.exists("/home/matteo/FLAMES/verification-results/evaluation_results"):
        os.makedirs("/home/matteo/FLAMES/verification-results/evaluation_results")

    
    contract_name = contract_lines[0]
    contract_file = find_contract_path("/home/matteo/FLAMES/verification-results/sb-heists/smartbugs-curated/0.4.x/contracts/dataset", contract_name)
    test_file = find_contract_path("/home/matteo/FLAMES/verification-results/sb-heists/smartbugs-curated", contract_name.replace(".sol", "_test.js"))
    if not test_file:
        return True
    
    print(f"\n=== Evaluating patches for contract: {contract_name} ===")
        
    replaced_contract = patch[0]
    original_line = patch[1]
    generated_require = patch[2]
        
            
    tempdir = "/home/matteo/FLAMES/verification-results/evaluation_results"  

    patch_file = os.path.join(tempdir, f"{contract_name}_patch_line_{original_line}.sol")

    

    with open(patch_file, "w") as pf:
        pf.write(replaced_contract) 
                
                
                
    result = subprocess.run([
            "python", "src/main.py",
            "--format", "solidity",
            "--patch", patch_file,
            "--contract-file", contract_file,
            "--main-contract", contract_name
        ], cwd="evaluator", capture_output=True, text=True, check=True)
        
    print(f"\n[Patch on line {original_line}] Evaluation Results:")
    print(f"Inserted Require: {generated_require}")
    print(result.stdout)

    return False


                