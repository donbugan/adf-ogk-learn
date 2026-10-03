SELECT COUNT(*)                                                         AS staged_rows, 
  COUNT(Vehicle_ID)                                                     AS rows_with_key
FROM stg.fleet_vehicles;

SELECT COUNT(*)                                                         AS target_rows FROM dbo.fleet_vehicles;

SELECT COUNT(*)                                                         AS target_rows
     , SUM(CASE WHEN Updated_At_UTC > Created_At_UTC THEN 1 ELSE 0 END) AS rows_updated
FROM dbo.fleet_vehicles;
