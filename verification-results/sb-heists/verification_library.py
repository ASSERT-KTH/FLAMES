import os
import json


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