--Create "permanent" table in tempdb.
DROP TABLE IF EXISTS tempdb.guest.IndexIncludeColumnStats;
CREATE TABLE tempdb.guest.IndexIncludeColumnStats (
	DatabaseId INT,
	SchemaName SYSNAME,
	TableName SYSNAME,
	IndexName SYSNAME,
	IncludeColumnName SYSNAME,
    QueryStoreUseCount BIGINT NOT NULL
		CONSTRAINT DF_QSUseCount DEFAULT(0),
	PlanCacheUseCount BIGINT NOT NULL
		CONSTRAINT DF_PCUseCount DEFAULT(0),
);

CREATE CLUSTERED INDEX Idx_clus_IndexIncludeColumnStats
ON tempdb.guest.IndexIncludeColumnStats(DatabaseId, SchemaName, TableName, IndexName)
WITH(DATA_COMPRESSION = ROW);

--Iterate through databases and write inidex meta data for INCLUDE columns to a single table.
--This is reasonably fast.
TRUNCATE TABLE tempdb.guest.IndexIncludeColumnStats;

DECLARE @TSql VARCHAR(2000) = 'USE [?]; 

IF DB_NAME() IN (''master'', ''model'', ''msdb'', ''tempdb'')
	RETURN;

INSERT INTO tempdb.guest.IndexIncludeColumnStats(DatabaseId, SchemaName, TableName, IndexName, IncludeColumnName)
SELECT
	DB_ID() AS DatabaseId,
	s.name AS SchemaName,
	o.name AS TableName,
	i.name AS IndexName,
	c.name AS IncludeColumnName
FROM sys.indexes AS i
INNER JOIN sys.index_columns AS ic
	ON i.index_id = ic.index_id 
	AND i.object_id = ic.object_id
INNER JOIN sys.columns AS c
	ON ic.object_id = c.object_id 
	AND ic.column_id = c.column_id
INNER JOIN sys.objects AS o
	ON i.object_id = o.object_id
INNER JOIN sys.schemas AS s
	ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
AND ic.is_included_column = 1
ORDER BY s.name, o.name, i.name, c.name';

EXEC sp_MSforeachdb @TSql;
