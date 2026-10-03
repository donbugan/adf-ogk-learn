--create the factory user and roles
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'adf-ogk-learn')
BEGIN
    EXEC('CREATE USER [adf-ogk-learn] FROM EXTERNAL PROVIDER'); 
END;

ALTER ROLE db_datareader ADD MEMBER [adf-ogk-learn]; 
ALTER ROLE db_datawriter ADD MEMBER [adf-ogk-learn];
GO

GRANT EXECUTE ON OBJECT::dbo.usp_merge_fleet_vehicles TO [adf-ogk-learn];
GO
