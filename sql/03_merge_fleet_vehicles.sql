MERGE INTO dbo.fleet_vehicles AS target
USING (
       SELECT Vehicle_ID
        , Registration_No
        , Vehicle_Category
        , Department      
        , Depot_Location 
        , Fuel_Type
        , Status
        , Driver_Assigned
        , TRY_CONVERT(date, Purchase_Date)                       AS Purchase_Date
        , TRY_CONVERT(date, Last_Service_Date)                   AS Last_Service_Date
        , TRY_CONVERT(date, Next_Service_Due)                    AS Next_Service_Due
        , TRY_CONVERT(int, Odometer_KM)                          AS Odometer_KM
        , TRY_CONVERT(int, Breakdowns_YTD)                       AS Breakdowns_YTD
        , TRY_CONVERT(int, Downtime_Days_YTD)                    AS Downtime_Days_YTD
        , TRY_CONVERT(decimal(10, 2), Monthly_Fuel_Cost_R)       AS Monthly_Fuel_Cost_R
        , TRY_CONVERT(decimal(10, 2), Maintenance_Cost_YTD_R)    AS Maintenance_Cost_YTD_R
        , TRY_CONVERT(decimal(5, 1), Utilization_Hours_Monthly)  AS Utilization_Hours_Monthly
       FROM stg.fleet_vehicles WHERE Vehicle_ID IS NOT NULL
) AS source
ON (target.Vehicle_ID = source.Vehicle_ID)
WHEN MATCHED THEN
    UPDATE SET 
        target.Registration_No	            = source.Registration_No
        , target.Vehicle_Category	        = source.Vehicle_Category
        , target.Department	                = source.Department
        , target.Depot_Location	            = source.Depot_Location
        , target.Purchase_Date	            = source.Purchase_Date
        , target.Odometer_KM	            = source.Odometer_KM
        , target.Fuel_Type	                = source.Fuel_Type
        , target.Monthly_Fuel_Cost_R	    = source.Monthly_Fuel_Cost_R
        , target.Maintenance_Cost_YTD_R     = source.Maintenance_Cost_YTD_R
        , target.Breakdowns_YTD	            = source.Breakdowns_YTD
        , target.Downtime_Days_YTD	        = source.Downtime_Days_YTD
        , target.Last_Service_Date	        = source.Last_Service_Date
        , target.Next_Service_Due	        = source.Next_Service_Due
        , target.OPS_STATUS    	            = source.Status
        , target.Driver_Assigned	        = source.Driver_Assigned
        , target.Utilization_Hours_Monthly  = source.Utilization_Hours_Monthly
        , target.Updated_At_UTC             = SYSUTCDATETIME()
WHEN NOT MATCHED THEN 
    INSERT (
        Vehicle_ID, Registration_No, Vehicle_Category, Department, 
        Depot_Location, Purchase_Date, Odometer_KM, Fuel_Type, 
        Monthly_Fuel_Cost_R, Maintenance_Cost_YTD_R, Breakdowns_YTD, Downtime_Days_YTD, 
        Last_Service_Date, Next_Service_Due, OPS_STATUS, Driver_Assigned, 
        Utilization_Hours_Monthly, Created_At_UTC, Updated_At_UTC
    ) VALUES (
        source.Vehicle_ID, source.Registration_No, source.Vehicle_Category, source.Department, 
        source.Depot_Location, source.Purchase_Date, source.Odometer_KM, source.Fuel_Type, 
        source.Monthly_Fuel_Cost_R, source.Maintenance_Cost_YTD_R, source.Breakdowns_YTD, source.Downtime_Days_YTD, 
        source.Last_Service_Date, source.Next_Service_Due, source.Status, source.Driver_Assigned, 
        source.Utilization_Hours_Monthly, SYSUTCDATETIME(), SYSUTCDATETIME()
    );
