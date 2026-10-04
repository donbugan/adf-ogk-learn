# Decisions (Before and During)
## Caveat
 - Portfolio project on an Azure free trial; decisions favour minimal cost.
   
## Storage
 - Plain Blob, ADLS Gen2 to be configured in future branch.
 - Each pipeline processes a single file, named by the `source_file` parameter per run.

## Infrastructure 
 - Locally-Redundant Storage.
 - Sample data doesn't need a second region.
 - Geo-Redundant Storage roughly doubles the cost.
 - South Africa North for everything. Matches the factory and keeps data in-country.
 - Public network access, account key auth.

## Security
 - Account key used for data access through the linked service.
 - Factory's managed identity granted Storage Blob Data Contributor on the `reports` container only, not the storage account.
 - Least privilege: the factory can write reports without an account key, and nothing else.
 - Production would move data access to Key Vault or managed identity as well.

## Naming Conventions

|Pattern | component|
|---|---|
|Linked Service |`ls_` |
|Dataset |`ds_`|
|Pipeline |`pl_` |
|Activity |`act_` |
|Trigger |`trg_`|
|Dataflow |`df_` |
|Dataflow stream names |camelCase: `src`, `flt`, `snk` |

 - ADF doesn't allow dashes in linked service, dataset or data flow names.
 - Additional conventions will be added as required.

## Source Data and Formatting
 - CSV over Excel as source.
 - Keeps the first pipeline simple; an Excel source may come later.
 - Export with UK regional format and General number format.
 - SA locale gave semicolon delimiters, comma decimals and currency text (R2 019).
 
## Data Quality
 - Keep the blank-row defect in the source.
 - **Reason** Kept as test data for a data quality rule, to be handled in the pipeline instead of patched upstream.
 - Defects are detected before the copy, so bad rows never reach `curated` unhandled.
 - Detection uses Lookup + Filter. Get Metadata was ruled out: it reports file properties, never rows.
 - Lookup returns at most 5,000 rows / 4 MB. Fine for this file; larger files need a data flow or SQL.
 - Known, harmless defects (e.g. fully blank rows):
    - Reporting built.
    - Automatic fix built (data flow).
    - **Assumption** Silence from the data provider is consent.
 - Structural changes (columns added, removed, renamed) are not auto-fixed.
    - Enforced: schema validation on the data flow source fails the run if columns differ.
    - Report on failure built for file-level checks (missing, empty, column count).
    - Quarantine of the failing file not yet built.
 - Sink quoting: Quote everything, per the default behaviour.
 - Pipeline will benefit from a different validation heuristic:
    - Currently there is no number validation.
    - Everything is quoted:
       - CSV carries no types, so every column maps as String.
       - Quoting all values reinforces that for downstream tools.

## Output Writers
 - Two writers to `curated`: copy activity for clean files, data flow for files with defects.
 - **Reason** Cost. Clean runs avoid starting a Spark cluster.
 - **Trade-off** The two writers must produce identical output.
 - **Constraint** The copy activity cannot disable `quoteAllText` (confirmed by run failure), so the data flow sink was set to quote all values to match.
 - **Verified** A byte-for-byte comparison of both outputs found two differences:
    - Line endings: copy wrote `\r\n`, data flow `\n`. Fixed by setting the curated dataset's row delimiter to `\n`.
    - Header quoting: the data flow quotes the header; the copy activity does not. Documented, not fixed.
    - Data rows are identical.
 - **Alternative** A single writer (data flow on every run) is consistent by construction but starts a cluster every run. Cost may remain a constraint.
 - Data flow output name is fixed (`vehicles_curated.csv`); `sink_file` only affects the copy branch.

## Data Flows
 - Schema drift off on source and sink.
 - Single partition, single output file. Fine for a small file; slower at scale.
 - Compute size Small.
 - Logging Verbose while testing; switch to Basic once stable.
 - Built with debug off; debug switched on only to test, then off. Debug bills while on, used or not.

## Timeouts
 - `act_create_report` timeout reduced from the 12-hour default to 30 minutes, to cap cost if anything hangs.
 - `act_cleanse_fleet_vehicles` timeout reduced to 30 minutes for the same reason.
 - In `pl_copy_fleet_vehicles_tosql`, Get Metadata, the copy and the merge Lookup are set to 10 minutes. A 56-row load takes seconds.

## Triggers
 - `trg_copy_fleet_vehicles` started once to verify a scheduled run, then stopped to avoid cost.
 - If restarted, the interval must account for data flow cost on runs with defects.

## Repo Visibility
 - Public after review.
 - Linked service JSON holds a credential reference, not the key; factory JSON holds identifiers only.

## Pipeline Parameters
 - Source and sink file names parameterised, sink name always explicit.
 - Without one, ADF generates a name dynamically, which could be undesirable.

## Failure Handling
 - Source file validated before any rows are read: exists, size > 0, 17 columns (Get Metadata).
 - Get Metadata is the right tool here: file properties, not rows.
 - **Pattern** Guard clause: an If whose True branch fails the run, placed in front of the existing chain. ADF does not allow an If inside another If.
 - **Null-safe access** For a missing file, Get Metadata returns only `exists`. `output?.size` returns null instead of an error.
 - **Fail must be last** A failed activity followed by a completion or failure arrow that succeeds counts as handled, and the run continues. Found by testing: with the arrow reversed, the run carried on to the Lookup.
 - Report before Fail, connected by a completion arrow, so the Fail runs even if the report cannot be written.
 - Failure report values for size and columns are quoted strings, so a missing file still produces valid JSON.
 - Work done on a feature branch (`feature/failure-handling`), merged to `main` by pull request.

## SQL Sink: Database
 - Azure SQL Database, free offer: 100,000 vCore seconds and 32 GB a month.
 - Overage billing disabled. When the free amount is used up the database pauses until the next month, so it cannot generate a charge.
 - Serverless, South Africa North. Same region as the factory and the storage account.
 - **Constraint** The region chosen for the first free database applies to every free database in the subscription.
 - One database, with different staging and target schemas: (`stg`, `dbo`).

## SQL Sink: Security
 - Microsoft Entra-only authentication on the server. SQL logins are disabled.
 - The factory connects with its system-assigned managed identity. The linked service JSON holds a server name and a database name, and no secret.
 - Factory permissions: `db_datareader`, `db_datawriter`, and `EXECUTE` on `dbo.usp_merge_fleet_vehicles` only.
 - Firewall: Azure services allowed, plus one client IP for the query editor.
 - **Trade-off** Public endpoint. Production use warrants a private endpoint.

## SQL Sink: Staging and Target
 - Staging is permissive: 17 nullable `VARCHAR(100)` columns, the file's column names, no keys, no constraints.
 - **Reason** Every row in the file must be able to land, including bad ones, so that they can be counted and reported. A constraint on staging would fail the whole copy and leave nothing to inspect.
 - Target is strict: typed columns, all `NOT NULL`, primary key on `Vehicle_ID`, unique `Registration_No`, named `CHECK` constraints.
 - Staging keeps the file's column name `Status`; the target calls it `OPS_STATUS`. The rename happens in the merge, so the copy can map columns by name.
 - Audit columns `Created_At_UTC` and `Updated_At_UTC` on the target, in UTC.
 - Staging is dropped and recreated by the setup script. The target is created only if it does not exist and is never dropped by a script.

## SQL Sink: Constraints
 - `CHECK` constraints on the column, in place of lookup tables, for fuel type, status and driver flag.
 - **Reason** A handful of stable values and 55 rows. A lookup table adds a join and a second object for no benefit at this size.
 - **Alternative** At volume, a lookup (dimension) table with a small integer key stores less and lets a new value be added with an `INSERT`.
 - SQL Server has no `ENUM` type; a `CHECK` with an `IN` list is the equivalent.
 - Constraint values were taken from a profile of the source file:
   - distinct values, maximum lengths, blanks, minimum and maximum ([tools/profiler.ps1](../tools/profiler.ps1)).
 - **Found by profiling** The first status list, written from memory, would have rejected 23 of 55 rows.
   - **Initial Cost checks** `> 1000` and `> 7500` would have rejected real rows.
   - The file's lowest fuel cost is 0. Both became `>= 0`.
   - Fuel type allows `Petrol` and `Diesel`. The file contains no other value; a new fuel type needs an `ALTER TABLE`.
 - **Design choices**:
   - `Driver_Assigned` stays `VARCHAR(3)` with a Yes/No check. **Alternative** `BIT`, converted in the merge.
   - `Vehicle_Category` has no constraint. Categories are the list most likely to grow.
 - Every constraint is named, so error messages are readable and constraints can be altered by name.

## SQL Sink: Merge
 - One stored procedure, no parameters. It merges whatever the copy has just staged, as a set.
 - Rows with an empty `Vehicle_ID` are excluded from the merge and counted as rejected.
 - `TRY_CONVERT` on the nine typed columns (three dates, three integers, three decimals). A value that cannot be converted becomes NULL where a plain conversion would abort the statement.
 - The load never deletes from the target. There is no `WHEN NOT MATCHED BY SOURCE` clause.
 - **Reason** Retention. A vehicle missing from one file keeps its record; retired vehicles stay in the source with status `Decommissioned`. Removal is a deliberate action outside the pipeline.
 - **Found by review** With a delete clause, loading a 4-row test fixture or an empty file would have removed every other vehicle from the target.
 - The update does not touch `Vehicle_ID` or `Created_At_UTC`.
 - **Verified** First run: 55 rows merged. Second run: still 55 rows, all 55 updated, none inserted. The merge is safe to rerun.
 - The procedure returns one row: `staged_rows`, `rejected_blank_key`, `merged_rows`. `SET NOCOUNT ON` hides the row-count message, so the procedure reports its own counts.
 - `CREATE OR ALTER`, so the script can be rerun.

## SQL Sink: Pipeline
 - A separate pipeline, `pl_copy_fleet_vehicles_tosql`. The original pipeline is unchanged, so the repo shows both approaches to the same defect.
 - The file guard (Get Metadata, If, failure report, Fail) is kept.
 - Lookup, Filter and the null-rows If are left out. Finding blank keys moved into SQL, which has no 5,000-row limit.
 - Pre-copy script `DELETE FROM stg.fleet_vehicles;`.
 - **Reason** `TRUNCATE TABLE` needs `ALTER` permission on the table. `DELETE` works with `db_datawriter`, and the speed difference on 56 rows is nil.
 - Explicit column mapping in the copy. A renamed source column fails the copy with an error that names the column.
 - The procedure is called from a Lookup activity.
 - **Reason** The Stored Procedure activity reports success or failure only and discards result sets. The Lookup exposes the returned row to the report as `output.firstRow`.
 - The copy activity's own data consistency verification is left off. The pipeline's reconciliation report covers it.
 - Report runs after the merge succeeds, same Web activity pattern as the original pipeline.
 - Work done on a feature branch (`feature/sql-sink`), merged to `main` by pull request.

## SQL Sink: Transient Faults
 - The serverless database pauses when idle. The first connection after that is refused and wakes it; a retry succeeds. Observed in the query editor on 3 October 2026: refused at 18:55, succeeded at 18:57 (SAST).
 - A wake-up statement in SQL cannot help: no statement runs while the connection is refused.
 - Copy and merge Lookup: 3 retries, 30 seconds apart.
 - Retrying the merge is safe because it is verified as rerunnable.
 - **Trade-off** A real failure in the merge, such as a constraint violation, fails four times before the run stops.

## SQL Sink: Scripts
 - SQL lives in `sql/`, numbered in run order. Setup, security, procedure and checks are separate files.
 - The `EXECUTE` grant sits in the procedure's file. **Reason** In the security file it ran before the procedure existed and failed on an empty database.
 - Scripts are rerunnable: `IF NOT EXISTS` for the schema and user, `DROP TABLE IF EXISTS` for staging, `IF OBJECT_ID(...) IS NULL` for the target, `CREATE OR ALTER` for the procedure.
 - **Not yet done** Automated deployment of the scripts.
