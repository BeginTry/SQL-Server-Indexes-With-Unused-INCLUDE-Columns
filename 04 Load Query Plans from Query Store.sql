/*
	Iterate through databases. If Query Store is enabled, load query plans into separate table.
	NOTES: 
		Databases that do not have Query Store enabled will not cause the script to fail.
		System databases are excluded.
		THIS WILL LIKELY BE SOMEWHAT SLOW. (RAISERROR(@Msg, 10, 1) WITH NOWAIT will provide some feedback.)
*/
DECLARE @TSql VARCHAR(2000) = 'USE [?]; 

IF DB_ID() <= 4
	RETURN;
ELSE IF EXISTS 
(
	SELECT *
	FROM master.sys.databases d 
	WHERE d.name = DB_NAME()
	AND d.is_query_store_on = 0
)
	RETURN;

DECLARE @Msg NVARCHAR(MAX) = ''Inserting Query Store plans for '' + QUOTENAME(DB_NAME());
RAISERROR(@Msg, 10, 1) WITH NOWAIT;
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET DEADLOCK_PRIORITY HIGH;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

ALTER DATABASE [?] SET QUERY_STORE = OFF;

INSERT INTO tempdb.dbo.QueryPlans
	(DatabaseId, QueryPlan)
SELECT DB_ID(), TRY_CAST(p.query_plan AS XML) AS query_plan
FROM sys.query_store_plan p WITH(NOLOCK);

ALTER DATABASE [?] SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);
';

EXEC sp_MSforeachdb @TSql;
