--Any INCLUDE columns not referenced in the plan cache,
--and not referenced in Query Store are good candidates 
--to remove from the index definition
SELECT DB_NAME(iics.DatabaseId) AS DatabaseName,
	iics.SchemaName,
	iics.TableName,
	iics.IndexName,
	iics.IncludeColumnName
FROM tempdb.dbo.IndexIncludeColumnStats iics
WHERE QueryStoreUseCount = 0
AND PlanCacheUseCount = 0
ORDER BY DB_NAME(iics.DatabaseId), iics.SchemaName, iics.TableName, iics.IndexName, iics.IncludeColumnName;

--STRING_AGG requires SQL 2017 or greater.
;WITH AggragatedIndexColumns AS
(
	SELECT DB_NAME(iics.DatabaseId) AS DatabaseName, iics.SchemaName, iics.TableName, iics.IndexName, 
		STRING_AGG(CAST(
			CASE 
				WHEN iics.QueryStoreUseCount + iics.PlanCacheUseCount = 0 
					THEN QUOTENAME(iics.IncludeColumnName)
				ELSE NULL END AS VARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY iics.IncludeColumnName) AS UnusedIncludeColumns,
		STRING_AGG(CAST(
			CASE 
				WHEN iics.QueryStoreUseCount + iics.PlanCacheUseCount > 0 
					THEN QUOTENAME(iics.IncludeColumnName)
				ELSE NULL END AS VARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY iics.IncludeColumnName) AS UsedIncludeColumns
	FROM tempdb.dbo.IndexIncludeColumnStats iics
	GROUP BY iics.DatabaseId, iics.SchemaName, iics.TableName, iics.IndexName
	--ORDER BY iics.DatabaseId, iics.SchemaName, iics.TableName, iics.IndexName
)
SELECT *
FROM AggragatedIndexColumns i
WHERE i.UnusedIncludeColumns IS NOT NULL
ORDER BY i.DatabaseName, i.SchemaName, i.TableName, i.IndexName
