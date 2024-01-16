import os
import re

def remove_require_statements(directory_path, output_directory_path):

    for root, dirs, files in os.walk(directory_path): 
        for file_name in files:
            if file_name.endswith('.sol'):
                file_path = os.path.join(root, file_name)
                with open(file_path, 'r') as file:
                    content = file.readlines()
                
                line_numbers = [] 

                for i, line in enumerate(content):
                    if re.match(r'^\s*require\s*\(', line):
                        line_numbers.append(i)
                
                if len(line_numbers) == 0:
                    continue
                # Remove 'require' statements
                for i, line in enumerate(line_numbers):
                    # Remove the line
                    label = content[:line] + content[line+1:]
                    # Create a folder if necessary
                    folder_path = os.path.join(output_directory_path, file_name.split('.')[0])
                    os.makedirs(folder_path, exist_ok=True)
                    # Save the file without the '.sol' suffix
                    with open(f"{folder_path}/{i}.sol", "w") as file:
                        file.writelines(label)
                
                # Save the original file
                with open(f"{folder_path}/{file_name}", "w") as file:
                    file.writelines(content)

                # Save file removing all require statements
                label = [x for i, x in enumerate(content) if i not in line_numbers]
                with open(f"{folder_path}/all.sol", "w") as file:
                    file.writelines(label)
        break
                    

    return line_numbers
                    
# Usage example

if __name__ == '__main__':
    remove_require_statements('contracts', 'labels')
