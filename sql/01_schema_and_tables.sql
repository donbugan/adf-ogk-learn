--create the staging schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg')
    EXEC('CREATE SCHEMA stg');
GO

DROP TABLE IF EXISTS stg.fleet_vehicles;
CREATE TABLE stg.fleet_vehicles (
    Vehicle_ID                    VARCHAR(100) NULL
    , Registration_No	            VARCHAR(100) NULL
    , Vehicle_Category	          VARCHAR(100) NULL
    , Department	                VARCHAR(100) NULL
    , Depot_Location	            VARCHAR(100) NULL
    , Purchase_Date	              VARCHAR(100) NULL
    , Odometer_KM	                VARCHAR(100) NULL
    , Fuel_Type	                  VARCHAR(100) NULL
    , Monthly_Fuel_Cost_R	        VARCHAR(100) NULL
    , Maintenance_Cost_YTD_R      VARCHAR(100) NULL
    , Breakdowns_YTD	            VARCHAR(100) NULL
    , Downtime_Days_YTD	          VARCHAR(100) NULL
    , Last_Service_Date	          VARCHAR(100) NULL
    , Next_Service_Due	          VARCHAR(100) NULL
    , Status    	                VARCHAR(100) NULL
    , Driver_Assigned	            VARCHAR(100) NULL
    , Utilization_Hours_Monthly   VARCHAR(100) NULL
);

IF OBJECT_ID('dbo.fleet_vehicles', 'U') IS NULL
CREATE TABLE dbo.fleet_vehicles (
    Vehicle_ID                  VARCHAR(10)    NOT NULL CONSTRAINT PK_fleet_vehicles PRIMARY KEY
    , Registration_No           VARCHAR(15)    NOT NULL CONSTRAINT UQ_fleet_vehicles_registration_no UNIQUE
    , Vehicle_Category          VARCHAR(50)    NOT NULL
    , Department                VARCHAR(50)    NOT NULL
    , Depot_Location            VARCHAR(50)    NOT NULL
    , Purchase_Date             DATE           NOT NULL
    , Odometer_KM               INT            NOT NULL
    , Fuel_Type                 VARCHAR(10)    NOT NULL CONSTRAINT CK_fleet_vehicles_fuel_type CHECK (Fuel_Type IN ('Petrol', 'Diesel'))
    , Monthly_Fuel_Cost_R       DECIMAL(10, 2) NOT NULL CONSTRAINT CK_fleet_vehicles_monthly_fuel_cost CHECK (Monthly_Fuel_Cost_R >= 0)
    , Maintenance_Cost_YTD_R    DECIMAL(10, 2) NOT NULL CONSTRAINT CK_fleet_vehicles_maintenance_cost CHECK (Maintenance_Cost_YTD_R >= 0)
    , Breakdowns_YTD            INT            NOT NULL
    , Downtime_Days_YTD         INT            NOT NULL
    , Last_Service_Date         DATE           NOT NULL
    , Next_Service_Due          DATE           NOT NULL
    , OPS_STATUS                VARCHAR(20)    NOT NULL CONSTRAINT CK_fleet_vehicles_operational_status CHECK (OPS_STATUS IN ('In Service', 'Under Maintenance', 'Decommissioned'))
    , Driver_Assigned           VARCHAR(3)     NOT NULL CONSTRAINT CK_fleet_vehicles_driver_assigned CHECK (Driver_Assigned IN ('Yes', 'No'))
    , Utilization_Hours_Monthly DECIMAL(5, 1)  NOT NULL
    , Created_At_UTC            DATETIME2(0)   NOT NULL CONSTRAINT DF_fleet_vehicles_created_at DEFAULT (SYSUTCDATETIME())
    , Updated_At_UTC            DATETIME2(0)   NOT NULL CONSTRAINT DF_fleet_vehicles_updated_at DEFAULT (SYSUTCDATETIME())
);
