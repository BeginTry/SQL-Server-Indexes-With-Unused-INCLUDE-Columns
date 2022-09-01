/*
	Load query plans from cache into separate table.
*/
DECLARE @PlanCache INT = -1;	--"Magic number" to be used as a database_id.

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

INSERT INTO tempdb.dbo.QueryPlans
	(DatabaseId, QueryPlan)
SELECT @PlanCache, p.query_plan
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS p
GO
