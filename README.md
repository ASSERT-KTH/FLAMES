# FLECS

## Dataset

### Addresses extraction

To get the initial list of contracts we select the addresses of the contracts that are the destination of at least one transaction from the BigQuery dataset `bigquery-public-data.crypto_ethereum.transactions` and we store them in a CSV file.

```
    SELECT contracts.address, COUNT(1) AS tx_count
    FROM `bigquery-public-data.crypto_ethereum.contracts` AS contracts
    JOIN `bigquery-public-data.crypto_ethereum.transactions` AS transactions 
            ON (transactions.to_address = contracts.address)
    GROUP BY contracts.address
    ORDER BY tx_count DESC
```

this query is taken from [smartbugs-wild repository](https://github.com/smartbugs/smartbugs-wild) and adapted to the new table.

The resulting file is in `dataset/addresses.csv`

### Source code retrieval

To retrieve the source code we go through the list of addresses and we use Etherscan APIs to check if the source code is verified and if it is we download it. The script is in `dataset/scripts/get_contracts.py` the results are in `dataset/data/contracts/`

2566 688
11341 2619
0x13bd972b0bfaefc9538a43c1fda11d71c720cd47