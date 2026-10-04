# Profile the source file before writing constraints.
# Run from the folder that holds the file.
# The output is not committed: it describes the real data.

$v = Import-Csv .\Vehicle_Master.csv

# 1. Distinct values and counts for the closed-set columns
'Status', 'Fuel_Type', 'Driver_Assigned', 'Vehicle_Category' | ForEach-Object {
    "--- $_"
    $v | Group-Object $_ | Select-Object Name, Count | Format-Table -AutoSize
}

# 2. Longest value and number of blanks per column
#    @( ) forces an array, so a single match still has a Count (Windows PowerShell 5.1).
$v[0].PSObject.Properties.Name | ForEach-Object {
    $col = $_
    [pscustomobject]@{
        Column = $col
        MaxLen = ($v | ForEach-Object { $_.$col.Length } | Measure-Object -Maximum).Maximum
        Blanks = @($v | Where-Object { [string]::IsNullOrWhiteSpace($_.$col) }).Count
    }
} | Format-Table -AutoSize

# 3. Minimum and maximum of the two cost columns, rows with a key only
'Monthly_Fuel_Cost_R', 'Maintenance_Cost_YTD_R' | ForEach-Object {
    $col = $_
    $v | Where-Object Vehicle_ID | ForEach-Object { [decimal]$_.$col } |
        Measure-Object -Minimum -Maximum |
        Select-Object @{ n = 'Column'; e = { $col } }, Minimum, Maximum
}

# 4. Duplicate keys: both counts should be 0
'Vehicle_ID', 'Registration_No' | ForEach-Object {
    "--- duplicates in $_"
    @($v | Where-Object Vehicle_ID | Group-Object $_ | Where-Object Count -gt 1).Count
}
