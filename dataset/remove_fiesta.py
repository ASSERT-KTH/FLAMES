import os
import shutil

def remove_files_in_big_folder(big_folder, small_folder):
    # Get the list of files in the small folder
    small_files = set(os.listdir(small_folder))

    # Iterate through the files in the big folder
    for file_name in os.listdir(big_folder):
        file_path = os.path.join(big_folder, file_name)

        # Check if the file exists in the small folder
        if file_name in small_files:
            # Remove the file from the big folder
            os.remove(file_path)
            print(f"Removed: {file_path}")

# Replace these paths with the actual paths to your big and small folders
big_folder_path = "/Users/gabrielemorello/Code/FLAMES/dataset/raw"
small_folder_path = "/Users/gabrielemorello/Code/smart-contract-downloader/fiesta_json"

remove_files_in_big_folder(big_folder_path, small_folder_path)

