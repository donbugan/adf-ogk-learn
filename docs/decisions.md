# Decisions (Before and During)
## Caveat
 - This is a learning repo.
 - Decisions recorded in this document are geared towards this.
 - The goal is to keep cost to a minimum or within the free thresholds for ADF.
   
## Storage
 - Plain Blob, ADLS Gen2 to be configured in future branch.
 - This is currently a single file pipeline.

## Infrastructure 
 - Locally-Redundant Storage.
 - Learning data doesn't need a second region.
 - Geo-Redundant Storage roughly doubles the cost.
 - South Africa North for everything. Matches the factory and keeps data in-country.
 - Public network access, account key auth.

## Security
 - Production would move to Key Vault or the factory's managed identity.

## Naming Conventions
 - ls_, ds_, pl_, act_, underscores.
 - ADF doesn't allow dashes in linked service, dataset or data flow names.

## Source Data and Formatting
 - CSV over Excel as source.
 - Keeps the first pipeline simple; an Excel source comes later.
 - Export with UK regional format and General number format.
 - SA locale gave semicolon delimiters, comma decimals and currency text (R2 019).
 
## Data Quality
 - Keep the blank-row defect in the source.
 - Kept as test data for a data quality rule, to be handled in the pipeline instead of patched upstream.
 - Sink quoting: Quote everything, per the default behaviour.
 - Pipeline will benefit from a different validation heuristic:
    - Currently there is no number validation.
    - Everything is quoted:
       - CSV carries no types, so every column maps as String.
       - Quoting all values reinforces that for downstream tools.

## Repo Visibility
 - Public after review.
 - Linked service JSON holds a credential reference, not the key; factory JSON holds identifiers only.

## Pipeline Parameters 
 - Source and sink file names parameterised, sink name always explicit.
 - Without one, ADF generates a name dynamically, which could be undesirable.
