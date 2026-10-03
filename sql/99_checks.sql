-- Expect 56 and 55 after loading Vehicle_Master.csv (one blank trailing row).
SELECT COUNT(*)                                                         AS staged_rows, 
  COUNT(Vehicle_ID)                                                     AS rows_with_key
FROM stg.fleet_vehicles;

-- Expect 55 after the merge.
SELECT COUNT(*)                                                         AS target_rows FROM dbo.fleet_vehicles;

-- Expect 55 and 55 after running the merge a second time.
SELECT COUNT(*)                                                         AS target_rows
     , SUM(CASE WHEN Updated_At_UTC > Created_At_UTC THEN 1 ELSE 0 END) AS rows_updated
FROM dbo.fleet_vehicles;
