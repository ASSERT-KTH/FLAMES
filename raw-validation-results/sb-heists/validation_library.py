import os
import json
import subprocess
import csv
import pandas as pd

def get_files(directory):
    """
    Recursively get all Solidity files in the given directory.
    Args:
    - directory (str): Path to the directory to search for Solidity files.
    Returns:
    - all_files (list): A list of tuples containing the full path and file name of each Solidity file.
    """
    all_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".sol"):
                all_files.append((os.path.join(root, file),file))
    return all_files

def find_occurrences(file_path, search_text):
    """
    Search for occurrences of a specific text in a file and return the content and line numbers.
    Args:
    - file_path (str): Path to the file to search.
    - search_text (str): Text to search for in the file.
    Returns:
    - content (str): The content of the file.
    - line_numbers (list): A list of line numbers (1-based) where the text occurs.
    """
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
    
    Args:
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

def find_function_bounds(code: str, target_line: int) -> tuple[int, int]:
    """
    Given Solidity code and a target line, returns the start and end line (1-based)
    of the function (or contract) enclosing the target line.
    Args:
        code (str): The Solidity code as a string.
        target_line (int): The 1-based line number to find the enclosing function or contract for.
    Returns: (entry_line, end_line)
    """
    lines = code.splitlines()
    target_line -= 1  # zero-based

    for i in range(target_line, -1, -1):
        if "function" in lines[i] or "contract" in lines[i]:
            # Find the opening brace
            brace_line = -1
            for j in range(i, len(lines)):
                if "{" in lines[j]:
                    brace_line = j
                    break
            if brace_line == -1:
                continue

            # Count braces from the brace_line
            brace_count = 0
            for k in range(brace_line, len(lines)):
                brace_count += lines[k].count("{")
                brace_count -= lines[k].count("}")
                if brace_count == 0:
                    # Check if target_line is within scope
                    if brace_line <= target_line <= k:
                        return brace_line + 1, k + 1  # +1 to convert to 1-based
                    else:
                        break

    raise ValueError("No enclosing function or contract found")


def insert_empty_line(code: str, line_number: int) -> str:
    """
    Inserts an empty line at the specified 1-based line number.
    Args:
        code (str): The original Solidity code as a string.
        line_number (int): The 1-based line number where the empty line should be inserted.
    Returns:
        str: The modified Solidity code with an empty line inserted.
    """
    lines = code.splitlines()

    if line_number < 1 or line_number > len(lines) + 1:
        raise ValueError("Line number out of range")

    lines.insert(line_number - 1, "")
    return "\n".join(lines)


def print_json_report(folder, data):
    """
    Writes the compilation reports to a JSON file.
    Args:
        folder (str): Path to the JSON file where the reports will be written.
        data (dict or list): Data to be written to the JSON file.
    """

    if os.path.exists(folder):
        os.remove(folder)
    # Write the compilation reports to the file
    with open(folder, "w") as file:
        json.dump(data, file, indent=4)

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

def get_directory_name(file_name, search_root):
    """
    Searches for a file in the given directory and returns the name of the directory containing it.
    Args:
        file_name (str): Name of the file to search for.
        search_root (str): Root directory where the search will be performed.
    Returns:
        str: Name of the directory containing the file, or None if not found.
    """
    for root, dirs, files in os.walk(search_root):
        if file_name in files:
            return os.path.basename(root)
    return None


def print_txt_report(folder, data):
    """
    Writes the compilation reports to a text file.
    Args:
        folder (str): Path to the text file where the reports will be written.
        data (list): List of tuples containing contract name, contract code, and line number.
    """

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
    """
    Evaluates the given patch on the specified contract lines.
    Args:
        contract_lines (list): List containing the contract name and other details.
        patch (tuple): A tuple containing the replaced contract, original line number, and generated require statement.
    Returns:
        tuple: A tuple containing a boolean indicating if thre were no test and the test result.
    """
    if not os.path.exists("/Users/mojtabae/projects/FLAMES/raw-validation-results/sb-heists/evaluation_results"):
        os.makedirs("/Users/mojtabae/projects/FLAMES/raw-validation-results/sb-heists/evaluation_results")

    
    contract_name = contract_lines[0]

    contract_file = find_contract_path("/Users/mojtabae/projects/FLAMES/raw-validation-results/sb-heists/smartbugs-curated/0.4.x/contracts/dataset", contract_name)

    test_file = find_contract_path("/Users/mojtabae/projects/FLAMES/raw-validation-results/sb-heists/smartbugs-curated", contract_name.replace(".sol", "_test.js"))
    if not test_file:
        return True, None
    
    print(f"\n=== Evaluating patches for contract: {contract_name} ===")
        
    replaced_contract = patch[0]
    original_line = patch[1]
    generated_require = patch[2]


    tempdir = "/Users/mojtabae/projects/FLAMES/raw-validation-results/sb-heists/evaluation_results"

    patch_file = os.path.join(tempdir, f"{contract_name}_patch_line_{original_line}.sol")

    

    with open(patch_file, "w") as pf:
        pf.write(replaced_contract) 
                
                
                
    result = subprocess.run([
            "python3", "src/main.py",
            "--format", "solidity",
            "--patch", patch_file,
            "--contract-file", contract_file,
            "--main-contract", contract_name
        ], cwd="evaluator", capture_output=True, text=True, check=True)
        
    print(f"\n[Patch on line {original_line}] Evaluation Results:")
    print(f"Inserted Require: {generated_require}")
    #print(result.stdout)
    test_result = {
        "Sanity_Test_Success": True,
        "Exploit_Covered": False
    }
    #print(result.stdout)
    print('Results for this run: ')
    print(result.stdout)
    if "Sanity Test Failures:" in result.stdout:
        test_result["Sanity_Test_Success"] = False
    if "Exploit Test Failures:" in result.stdout:
        test_result["Exploit_Covered"] = True
        

    return False, test_result

def create_csv_if_not_exists(file_name, headers):
    """
    Creates a CSV file with the specified headers if it does not already exist.
    - Uses UTF-8 with BOM for encoding
    - Uses semicolon as delimiter for Excel compatibility
    Args:
        file_name (str): The name of the CSV file to create.
        headers (list): A list of headers for the CSV file.
    Returns:
        None
    Raises:
        FileExistsError: If the file already exists.
    """
    
    with open(file_name, mode='w', newline='', encoding='utf-8-sig') as file:
        writer = csv.DictWriter(
            file,
            fieldnames=headers,
            delimiter=';',          
            quoting=csv.QUOTE_MINIMAL
        )
        writer.writeheader()
    print(f"CSV file '{file_name}' created successfully in Excel-friendly format.")
 
 


def append_row(file_name, headers, row_data):
    """
    Appends a row to a CSV file formatted for Excel:
    - Uses UTF-8 with BOM for encoding
    - Uses semicolon as delimiter
    - Creates header if file doesn't exist
    """
    file_exists = os.path.exists(file_name)

    with open(file_name, mode='a', newline='', encoding='utf-8-sig') as file:
        writer = csv.DictWriter(
            file,
            fieldnames=headers,
            delimiter=';',           # semicolon for Excel compatibility
            quoting=csv.QUOTE_MINIMAL
        )

        if not file_exists:
            writer.writeheader()

        # Ensure all headers are present
        row_filled = {key: row_data.get(key, '') for key in headers}
        writer.writerow(row_filled)

    print(f"Row written to '{file_name}' (Excel-friendly format).")

def save_patches_by_strategy(
    output_dir,
    contract_name,
    strategy_patch_map
):
    """
    Salva le patch per un contratto in file separati per strategia.
    
    :param output_dir: Directory base dove salvare i file
    :param contract_name: Nome del contratto Solidity
    :param strategy_patch_map: Dizionario con chiavi = strategia (es. 'VL', 'pre'),
                               e valori = stringhe di codice patchate
    """
    contract_dir = os.path.join(output_dir, contract_name.replace(".sol", ""))
    os.makedirs(contract_dir, exist_ok=True)

    for strategy, patch_code in strategy_patch_map.items():
        patch_filename = f"{strategy}.sol"
        patch_path = os.path.join(contract_dir, patch_filename)

        with open(patch_path, 'w') as f:
            f.write(patch_code)

def produce_dataframe_from_csv(file_path):
    """
    Reads a CSV file and returns a pandas DataFrame.
    
    Args:
        file_path (str): Path to the CSV file.
    
    Returns:
        pd.DataFrame: DataFrame containing the data from the CSV file.
    """
    df = pd.read_csv(file_path, delimiter=';')
    return df