# Decisions (Before and During)
## Caveat
 - Portfolio project on an Azure free trial; decisions favour minimal cost.
   
## Storage
 - Plain Blob, ADLS Gen2 to be configured in future branch.
 - This is currently a single file pipeline.

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
 - ls_, ds_, pl_, act_, trg_, `df_` underscores.
    - Single `act_` prefix for all activity types.
    - `trg_` for triggers, `df_` for dataflows.
 - ADF doesn't allow dashes in linked service, dataset or data flow names.
 - Data flow stream names allow letters and numbers only (ADF constraint), so streams use camelCase: `src`, `flt`, `snk`.
 - Revisit if names become ambiguous as the pipeline grows.

## Source Data and Formatting
 - CSV over Excel as source.
 - Keeps the first pipeline simple; an Excel source comes later.
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
 - **Alternative** A single writer (data flow on every run) is consistent by construction but starts a cluster every run. Revisit if cost stops being the constraint.
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
