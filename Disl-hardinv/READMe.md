## How to find full contract info in DISL

The following will give you the contract in our DISL-HardInv dataset that has a original_idx column with `54575` (foreign key to row in ). 
```SQL
SELECT *
FROM decomposed
LIMIT 1 OFFSET 54575;
```