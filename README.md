# SQL Server Indexes With Unused INCLUDE Columns

This repository of T-SQL scripts attempts to identify INCLUDE columns in non-clustered indexes that are not being referenced, and could presumably be removed from the index definition. The scripts are as follows:

<h4>01 Create, Populate Table.sql</h4>
Creates a "permanent" table within [tempdb] and populates it with meta data for all nonclustered index INCLUDE columns.

<h4>02 Create Table.sql</h4>
Creates a "permanent" table to hold all query plans.

<h4>03 Load Query Plans from Plan Cache.sql</h4>
Loads query plans from plan cache into a table.

<h4>04 Load Query Plans from Query Store.sql</h4>
Loads query plans from Query Store in every database (if enabled/on) into a table.

<h4>05 Parse Query Plans.sql</h4>
Parses the table of query plans, and updates a table when INCLUDE columns are found.

<h4>06 Results.sql</h4>
Queries that help analyze the results.

<h3>Credits</h3>
Many thanks to Jonathan Kehayias (<a href="https://twitter.com/SQLPoolBoy">Twitter</a> | <a href="https://www.sqlskills.com/blogs/jonathan/">Blog</a>) for his guidance with the scripts. He helped me with the XML parsing/syntax that identified index scans and their column references.
