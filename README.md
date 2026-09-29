# adf-ogk-learn
## Components
### Pipeline
Uploaded CSV source file landed into Azure Blob Storage under raw schema
Landed in sink as ds_fleet_curated under curated schema

### Validation
Pipeline check for empty rows (16 commas)

### Known Defect
#### What: Blank row inadvertently imported
#### Mitigation: check for blanks in one of 3 ways:
1. Mapping data flow with a Filter step
   Cost: Spark cluster, with dollar based cost implications unless the debug time-to-live is set to low.
   
2. Validation in the pipeline: Lookup or Get Metadata activity and If Condition that fails the run or alerts on issues with the file.
   Detection only.
   Cost: Cheap, and it teaches control flow.
3. Database sink that can be filtered in SQL. Warehouse built to learn production standards.
   Cost: Azure SQL database with possible dollar cost implications

## Cost Management
This repo will take advantage of free credits of $200 until free trial ends in 30 days.
