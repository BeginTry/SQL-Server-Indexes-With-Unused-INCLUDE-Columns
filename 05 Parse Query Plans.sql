/*
	Parse the table of query plans in batches of X rows, and update 
	table [IndexIncludeColumnStats] accordingly for any INCLUDE columns found.
	THIS WILL LIKELY BE SOMEWHAT SLOW. (NOCOUNT is set to OFF to provide some feedback.)

	You can run this query in a separate window to track progress:
		SELECT p.IsParsed, COUNT(*)
		FROM tempdb.dbo.QueryPlans p 
		GROUP BY p.IsParsed
*/
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT OFF;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WHILE EXISTS (SELECT * FROM tempdb.dbo.QueryPlans p WHERE p.IsParsed = 0)
BEGIN
	BEGIN TRAN;
	DROP TABLE IF EXISTS #QueryPlans;
	SELECT TOP(200) p.QueryPlanId, p.DatabaseId, p.QueryPlan
	INTO #QueryPlans
	FROM tempdb.dbo.QueryPlans p 
	WHERE p.IsParsed = 0
	ORDER BY p.QueryPlanId;

	;WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
	IndexReferenceGroups AS
	(
		SELECT 
			p.DatabaseId AS QueryPlanSourceId,
			DB_ID(nm.DatabaseName) AS DatabaseId,
			nm.SchemaName, nm.TableName,
			nm.IndexName, nm.ColumnName,
			COUNT(*) AS RefCount
		FROM #QueryPlans p
		CROSS APPLY p.QueryPlan.nodes('//IndexScan') AS i(idx)
		CROSS APPLY idx.nodes('.//ColumnReference') AS x(c)
		CROSS APPLY (
			SELECT
				PARSENAME(idx.value('(Object/@Database)[1]', 'VARCHAR(128)'), 1) AS DatabaseName,
				PARSENAME(idx.value('(Object/@Schema)[1]', 'VARCHAR(128)'), 1) AS SchemaName,
				PARSENAME(idx.value('(Object/@Table)[1]', 'VARCHAR(128)'), 1) AS TableName,
				PARSENAME(idx.value('(Object/@Index)[1]', 'VARCHAR(128)'), 1) AS IndexName,
				c.value('(@Column)[1]', 'VARCHAR(128)') AS ColumnName
		) AS nm
		GROUP BY p.DatabaseId, nm.DatabaseName, nm.SchemaName, nm.TableName, nm.IndexName, nm.ColumnName
	)
	UPDATE iics SET 
		iics.QueryStoreUseCount = QueryStoreUseCount + CASE WHEN irg.QueryPlanSourceId > 0 THEN irg.RefCount ELSE 0 END,
		iics.PlanCacheUseCount = PlanCacheUseCount + CASE WHEN irg.QueryPlanSourceId < 0 THEN irg.RefCount ELSE 0 END
	FROM IndexReferenceGroups irg
	JOIN tempdb.dbo.IndexIncludeColumnStats iics
		ON iics.DatabaseId = irg.DatabaseId
		AND iics.SchemaName = irg.SchemaName
		AND iics.TableName = irg.TableName
		AND iics.IndexName = irg.IndexName
		AND iics.IncludeColumnName = irg.ColumnName

	UPDATE p SET p.IsParsed = 1
	FROM tempdb.dbo.QueryPlans p
	JOIN #QueryPlans t
		ON t.QueryPlanId = p.QueryPlanId
	COMMIT;
END
GO
