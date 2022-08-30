--Any INCLUDE columns not referenced in the plan cache,
--and not referenced in Query Store are good candidates 
--to remove from the index definition
SELECT DB_NAME(iics.DatabaseId) AS DatabaseName,
	iics.SchemaName,
	iics.TableName,
	iics.IndexName,
	iics.IncludeColumnName
FROM tempdb.guest.IndexIncludeColumnStats iics
WHERE QueryStoreUseCount = 0
AND PlanCacheUseCount = 0
ORDER BY DB_NAME(iics.DatabaseId), iics.SchemaName, iics.TableName, iics.IndexName, iics.IncludeColumnName;
