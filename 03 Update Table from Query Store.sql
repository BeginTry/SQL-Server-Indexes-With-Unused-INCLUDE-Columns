--Iterate through databases, examine every query plan in Query Store,
--and update the "perm" table accordingly.
--NOTES: 
	--TRIM() function is used (requires SQL 2017 or greater).
	--Databases that do not have Query Store enabled will not cause the script to fail.
	--System databases are excluded.
	--THIS WILL MOST LIKELY BE HORRIFICALLY SLOW.
DECLARE @TSql VARCHAR(2000) = 'USE [?]; 

IF DB_ID() <= 4
	RETURN;

DECLARE @Msg NVARCHAR(MAX) = ''Processing Query Store for '' + QUOTENAME(DB_NAME());
RAISERROR(@Msg, 14, 1) WITH NOWAIT;
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET DEADLOCK_PRIORITY HIGH;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @QueryPlan XML;
DECLARE curPlans CURSOR READ_ONLY FAST_FORWARD FOR
	SELECT TRY_CAST(p.query_plan AS XML) AS query_plan
	FROM sys.query_store_plan p WITH(NOLOCK);

OPEN curPlans;
FETCH NEXT FROM curPlans INTO @QueryPlan;

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRAN;
	;WITH XMLNAMESPACES (DEFAULT ''http://schemas.microsoft.com/sqlserver/2004/07/showplan'')
	UPDATE iics SET iics.QueryStoreUseCount = QueryStoreUseCount + 1
	FROM @QueryPlan.nodes(''//IndexScan'') AS i(idx)
	CROSS APPLY idx.nodes(''.//ColumnReference'') AS x(c)
	CROSS APPLY (
		SELECT
			TRIM(''[]'' FROM idx.value(''(Object/@Database)[1]'', ''VARCHAR(128)'')) AS DatabaseName,
			TRIM(''[]'' FROM idx.value(''(Object/@Schema)[1]'', ''VARCHAR(128)'')) AS SchemaName,
			TRIM(''[]'' FROM idx.value(''(Object/@Table)[1]'', ''VARCHAR(128)'')) AS TableName,
			TRIM(''[]'' FROM idx.value(''(Object/@Index)[1]'', ''VARCHAR(128)'')) AS IndexName,
			c.value(''(@Column)[1]'', ''VARCHAR(128)'') AS ColumnName
	) AS nm
	JOIN tempdb.guest.IndexIncludeColumnStats iics
		ON iics.DatabaseId = DB_ID(nm.DatabaseName)
		AND iics.SchemaName = nm.SchemaName
		AND iics.TableName = nm.TableName
		AND iics.IndexName = nm.IndexName
		AND iics.IncludeColumnName = nm.ColumnName
	COMMIT;

	FETCH NEXT FROM curPlans INTO @QueryPlan;
END

CLOSE curPlans;
DEALLOCATE curPlans;
';

EXEC sp_MSforeachdb @TSql;
