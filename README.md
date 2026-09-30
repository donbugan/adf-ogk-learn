# adf-ogk-learn
## About

### A portfolio project: 
 - Azure Data Factory pipeline built from scratch.
 - Version-controlled in Git, with data quality checks and reporting.

### Execution Steps:
- A CSV is uploaded manually to the `raw` container in Azure Blob Storage.
- The pipeline reads every row and checks for rows with an empty `Vehicle_ID`.
- Clean file: it is copied to the `curated` container.
- Null rows found: nothing is copied, and a JSON report of what was found is written to the `reports` container.
- Work in progress: a cleansing step to remove bad rows and deliver the clean file is next.

Design choices and trade-offs are recorded in [docs/decisions.md](docs/decisions.md).
  
## Naming conventions

- Linked services are named with prefix `ls_`.
 
-  Containers are directly named `raw`, `curated` and `reports`.

- Pipelines are named with prefix `pl_`.

- Pipeline activities are named with prefix `act_`.
  - Single `act_` prefix for all activity types;
  - revisit if names become ambiguous as the pipeline grows.

- Datasets are named with prefix `ds_`.

- Triggers are named with prefix `trg_`.

## Components

### Pipeline

- `pl_copy_fleet_vehicles` checks the source file before copying it:
  1. `act_lookup_fleet_source` reads every row of the file in `raw`.
  2. `act_filter_nulls` keeps rows where `Vehicle_ID` is empty.
  3. `act_if_null_rows_found` branches on whether any were found.
     - **False (clean file):** `act_copy_fleet_master` copies the file to `curated`.
     - **True (defects found):** `act_create_report` writes a JSON report to `reports/<run_id>.json`. Nothing is copied to `curated` yet; the cleanse step is in progress.

- File names are pipeline parameters, supplied at run time:
  - `source_file`, default `Vehicle_Master.csv`
  - `sink_file`, default `vehicles_curated.csv`

- The source file was uploaded manually.

### Trigger

- `trg_copy_fleet_vehicles` runs `pl_copy_fleet_vehicles` every 3 hours (South Africa Standard Time), passing the default file names.

- Currently **stopped**. It was started once to verify a scheduled run (56 rows in, 56 out), then stopped to avoid cost.

### Report

- Written by a Web activity calling Blob Storage directly, authenticated with the factory's managed identity (write access to `reports` only).
- Contains: source file, run ID, run time (UTC), the rule applied, the action taken, rows checked, rows flagged, and the flagged rows themselves.

### Validation

- A defect was found during run verification as 56 rows in the run recorded against 55 rows in the source file. 

- The pipeline read in a blank row at the end of the file.

- This data quality issue is directly from the XLSX worksheet used to export Vehicle Master Data from.

### Known Defect
#### What: The source export included an empty trailing row.

#### Mitigation: three approaches
1. Mapping data flow with a Filter step. **In progress** (cleanse step).

   Cost: Spark cluster, billed while debug is on. Keep the debug time-to-live low.

2. Validation in the pipeline: Lookup, Filter and If Condition, with a report on defects found. **Built.**

   Detection only. Get Metadata was ruled out: it reads file properties, not rows.

   Cost: Cheap.

3. Database sink that can be filtered in SQL. **Planned.**

   Cost: Azure SQL database with possible dollar cost implications.

## Cost Management

- This repo will take advantage of free credits of $200 until free trial ends in 30 days.

- Budget alert created at $10/month.
