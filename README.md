# adf-ogk-learn
## Naming conventions

- Linked services are named with prefix `ls_`.
 
-  Containers are directly named `raw` and `curated`.

- Pipelines are named with prefix `pl_`.

- Pipeline activities are named with prefix `act_`.
  - Single `act_` prefix for all activity types;
  - revisit if names become ambiguous as the pipeline grows.

- Datasets are named with prefix `ds_`.

- Triggers are named with prefix `trg_`.

## Components

### Pipeline

- `pl_copy_fleet_vehicles` copies a CSV from the `raw` container (dataset `ds_fleet_vehicles_csv`) to the `curated` container (dataset `ds_fleet_vehicles_curated`), using the copy activity `act_copy_fleet_master`.

- File names are pipeline parameters, supplied at run time:
  - `source_file`, default `Vehicle_Master.csv`
  - `sink_file`, default `vehicles_curated.csv`

- The source file was uploaded manually.

### Trigger

- `trg_copy_fleet_vehicles` runs `pl_copy_fleet_vehicles` every 3 hours (South Africa Standard Time), passing the default file names.

- Currently **stopped**. It was started once to verify a scheduled run (56 rows in, 56 out), then stopped to avoid cost.

### Validation

- A defect was found during run verification as 56 rows in the run recorded against 55 rows in the source file. 

- The pipeline read in a blank row at the end of the file.

- This data quality issue is directly from the XLSX worksheet used to export Vehicle Master Data from.

### Known Defect
#### What: The source export included an empty trailing row.

#### Mitigation (Planned): check for blanks in one of 3 ways:
1. Mapping data flow with a Filter step 

   Cost: Spark cluster, with dollar based cost implications unless the debug time-to-live is set to low.
   
2. Validation in the pipeline: Lookup or Get Metadata activity and If Condition that fails the run or alerts on issues with the file.

   Detection only.

   Cost: Cheap.
   
3. Database sink that can be filtered in SQL. (Warehouse production standard to be followed).

   Cost: Azure SQL database with possible dollar cost implications

## Cost Management

- This repo will take advantage of free credits of $200 until free trial ends in 30 days.

- Budget alert created at $10/month.
