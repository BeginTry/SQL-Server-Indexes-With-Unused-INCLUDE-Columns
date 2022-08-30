# SQL Server Indexes With Unused INCLUDE Columns

This repository of T-SQL scripts attempts to identify INCLUDE columns in non-clustered indexes that are not being referenced, and could presumably be removed from the index definition. The scripts are as follows:

<h3>01 Create, Populate Table.sql</h3>
Creates and populates a "permanent" table within [tempdb]. This could easily be renamed, if desired (just ensure it is renamed in all scripts). The script iterates through all databases, inserting a row for every INCLUDE column of every index.

<h3>02 Update Table from Plan Cache.sql</h3>
Scans the plan cache for every query plan, finding every ColumnReference of every IndexScan operation. Corresponding rows in the "permanent" table have their [PlanCacheUseCount] value incremented.

<h3>03 Update Table from Query Store.sql</h3>
Iterates through all databases, scans Query Store for every query plan, finding every ColumnReference of every IndexScan operation. Corresponding rows in the "permanent" table have their [PlanCacheUseCount] value incremented.

<h3>04 Results.sql</h3>
A simple query showing all of the INCLUDE columns in the "permanent" table that have zero plan cache references and zero Query Store references.
