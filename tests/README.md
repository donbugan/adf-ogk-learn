# Test fixtures

Synthetic input files for exercising every path through `pl_copy_fleet_vehicles`.
All data is invented (`TST` vehicle IDs); none of it comes from the original source file.

## How to run

1. Upload the file to `raw/fleet/tests/fixtures/`.
2. Debug the pipeline (activity runtime, data flow debug off) with:
   - `source_file` = `tests/fixtures/<fixture name>`
   - `sink_file` = `test_<fixture name>` so copy-branch outputs don't overwrite each other
3. Record the pipeline run ID and outcome in the **Actual** column.

## Test matrix

Run on 1–2 October 2026. Run IDs are pipeline run IDs from Monitor > Pipeline runs > Debug.

| # | File | What it tests | Expected | Actual | Run ID |
|---|---|---|---|---|---|
| 01 | `01_valid_clean.csv` | Happy path | Guard passes, no nulls, copy writes 3 rows. Succeeded. | As expected. | `5f6c064c-75a4-47a1-b3eb-13a78bae9fc4` |
| 02 | `02_blank_trailing_row.csv` | Blank-row defect | Guard passes, 1 null row, data flow writes 3 rows, report written. Succeeded. | As expected. Report: 4 rows checked, 1 flagged. Output: header + 3 rows. | `2033317f-b771-4f21-b270-e4d56f1c57c1` |
| 03 | `03_empty.csv` | Zero-byte file | Guard fails on size 0, failure report, `SOURCE_FILE_INVALID`. | As expected. Get Metadata does not error on an empty file: it returns size 0 and column count 0. | |
| 04 | `04_header_only.csv` | Header, no rows | Guard passes (size > 0, 17 columns), copy writes a header-only file. Succeeded. **Known gap.** | As expected: 0 rows read, 0 rows copied, 266-byte header-only file written to `curated`. Gap confirmed. | |
| 05 | `05_semicolon_delimited.csv` | Wrong delimiter | Reads as 1 column, guard fails, `SOURCE_FILE_INVALID`. | As expected: size 695, 1 column. Report written. | `0d56fa04-2d20-49b6-8c94-544bcda830da` |
| 06 | `06_extra_column.csv` | Column added | 18 columns, guard fails, `SOURCE_FILE_INVALID`. | As expected: size 714, 18 columns. | |
| 07 | `07_renamed_columns.csv` | Columns renamed, same count | Guard passes (17 columns), no nulls, copy writes renamed headers. Succeeded. **Known gap.** | **Differs.** Guard passes, then the Filter fails: `Vehicle_ID` doesn't exist (renamed to `VehicleId`). Nothing written, but no report. Protection is accidental: renaming a column other than `Vehicle_ID` would pass. | |
| — | `nope.csv` (no fixture) | Missing file | Guard fails with `exists=False`, `SOURCE_FILE_INVALID`. | As expected. Report written. | |
| 09 | (unplanned) | Tab character in file name | — | Get Metadata fails with 400 Bad Request. The guard never runs, so no failure report. Found by accident. | |

## Findings

- **Header-only files pass.** Fix: check the Lookup's row count is above 0, using the same guard pattern.
- **Renamed columns are caught only by accident**, when the renamed column is `Vehicle_ID`. Fix: compare Get Metadata's `structure` field (column names) with the expected list.
- **Malformed file names bypass the guard.** Fix: a failure arrow from Get Metadata to a failure report, then a Fail, keeping the Fail last.
