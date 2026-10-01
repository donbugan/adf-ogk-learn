# Test fixtures

Synthetic input files for exercising every path through `pl_copy_fleet_vehicles`.
All data is invented (`TST` vehicle IDs); none of it comes from the original source file.

## How to run

1. Upload the file to `raw/fleet/`.
2. Debug the pipeline (activity runtime, data flow debug off) with:
   - `source_file` = the fixture name
   - `sink_file` = `test_<fixture name>` so copy-branch outputs don't overwrite each other
3. Record the run ID and outcome in the **Actual** column.

## Test matrix

| # | File | What it tests | Expected | Actual (run ID) |
|---|---|---|---|---|
| 01 | `01_valid_clean.csv` | Happy path | Guard passes, no nulls, copy writes 3 rows. Succeeded. | |
| 02 | `02_blank_trailing_row.csv` | Blank-row defect | Guard passes, 1 null row, data flow writes 3 rows, report written. Succeeded. | |
| 03 | `03_empty.csv` | Zero-byte file | Guard fails on size 0, failure report, `SOURCE_FILE_INVALID`. **Verify:** Get Metadata may itself error on column count for an empty file. | |
| 04 | `04_header_only.csv` | Header, no rows | Guard passes (size > 0, 17 columns), copy writes a header-only file. Succeeded. **Known gap.** | |
| 05 | `05_semicolon_delimited.csv` | Wrong delimiter | Reads as 1 column, guard fails, `SOURCE_FILE_INVALID`. | |
| 06 | `06_extra_column.csv` | Column added | 18 columns, guard fails, `SOURCE_FILE_INVALID`. | |
| 07 | `07_renamed_columns.csv` | Columns renamed, same count | Guard passes (17 columns), no nulls, copy writes renamed headers. Succeeded. **Known gap.** | |

Missing file: no fixture needed. Run with `source_file` = `nope.csv`.
Expected: guard fails with `exists=False`, `SOURCE_FILE_INVALID`.
