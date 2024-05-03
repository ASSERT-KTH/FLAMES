import os 
import json
from tqdm import tqdm

input_folder = 'smart-contract-fiesta/flattened'
output_folder = 'fiesta_json'
error_file = 'error.txt'

for dir in tqdm(os.listdir(input_folder)):
    address = '0x' + dir

    try:
        metadata = json.load(open(os.path.join(input_folder, dir, "metadata.json")))

        if os.path.isfile(os.path.join(input_folder, dir, "contract.json")):
            with open(os.path.join(input_folder, dir, "contract.json")) as f:
                source = '{' + f.read() + '}'
        elif os.path.isfile(os.path.join(input_folder, dir, "main.sol")):
            with open(os.path.join(input_folder, dir, "main.sol")) as f:
                source = f.read()

        contract = {
            "SourceCode": source,
            "ABI": "",
            "ContractName": metadata["ContractName"],
            "CompilerVersion": metadata["CompilerVersion"],
            "OptimizationUsed": metadata["OptimizationUsed"],
            "Runs": metadata["Runs"],
            "ConstructorArguments": metadata.get("ConstructorArguments", ""),
            "EVMVersion": metadata.get("EVMVersion", ""),
            "Library": metadata.get("Library", ""),
            "LicenseType": metadata.get("LicenseType", ""),
            "Proxy": metadata.get("Proxy", ""),
            "Implementation": metadata.get("Implementation", ""),
            "SwarmSource": metadata.get("SwarmSource", ""),
        }

        # Save output to json file
        with open(os.path.join(output_folder, address + '.json'), 'w') as outfile:
            json.dump(contract, outfile)
    except Exception as e:
        with open(error_file, 'a') as errorfile:
            errorfile.write(dir + '\n')
    