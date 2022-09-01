/*
	Create a "permanent" table to hold all query plans.
*/
DROP TABLE IF EXISTS tempdb.dbo.QueryPlans;
CREATE TABLE tempdb.dbo.QueryPlans (
	QueryPlanId INT IDENTITY NOT NULL
		CONSTRAINT PK_QueryPlans PRIMARY KEY,
	DatabaseId INT NOT NULL,
	QueryPlan XML,
    IsParsed BIT NOT NULL
		CONSTRAINT DF_QueryPlans_Parsed DEFAULT(0)
) WITH(DATA_COMPRESSION = PAGE);

CREATE INDEX Idx_QueryPlans_Parsed
ON tempdb.dbo.QueryPlans(IsParsed)
WITH(DATA_COMPRESSION = ROW);
GO
