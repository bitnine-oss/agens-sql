# Agens-SQL
----------------------
Agens-SQL is the nation's first integrated database package of PostgreSQL which is an open source DBMS and the extension modulues of it. Agens-SQL 1.0 is built on PostgreSQL 9.4. It is a stable and verified integrated database package which anyone can use for free.

## Agens-SQL architecture
Agens SQL integrated database solution is packaged in various modules based on the PostgreSQL DBMS. When utilizing the packaging, any extension module can be enable immediate use. These modules will be sorted by open source community and developed more. Then they will be included in the overall package.
- Free scalable
	* Easy expansion through the community
	* Users and Developers can join
- Many possibilities
	* The interface with the various feature that utilizes the open source
	* Providing a variety of functions such as redundancy, data transfer
- Manageability
	* Management tool using the Agens Manager
	* Monitoring system through the POWA

## Agens-SQL strength
- Scalable DBMS packages with the variety open source modules
	* Agens-SQL is based on PostgreSQL and provides open source packages as selective form for convenience and stability. Having a reputation for an open source version of Oracle, existing users of Oracle can use PostgreSQL easily without much difference. Diverse packages for indispensable functions - Replication, Failover, Connection Pooling, and so forth - are provided as well.
- Suitability of Data
	* ACID transaction
	* Serializable isolation level
	* MVCC model
	* Transacational DDL
- Stable Replication, Failover
	* Failover feature
	* Streaming replication
	* Slony-I
	* PgBouncer
	* pgpool-II
- Diverse functions
	* Observance ofANCI-SQLstandard
	* PL Language
	* BI/DW feature
	* Window function
	* Data mining feature
- Extension functions
	* PostGIS
	* pg_hint_plan
	* RFC (Remote Function Call)
- Security modules
	* SSL Certificate
	* Kerberos
	* System of Roles and Privileges

## Agens-SQL integrated package
Agens-SQL 1.0 offers convenient and variety of functions in managing or operating a PostgreSQL DB. The list of packages included in the integrated packages is as follows.

- pgpool-II
	- Pgpool-II is a middleware that works between PostgreSQL servers and PostgreSQL database client.
	- It improves system's overall throughput by means of Connection Pooling and Load Balancing, in addition to high-availability using the replication function.
	- It's license information, [here](https://github.com/bitnine-oss/agens-sql/blob/master/pgpool-II-3.4.2/COPYING)

- PostGIS
	- PostgGIS adds support for geographic objects to efficiently implement as a spatial database extender.
	- It also adds support for geographic objects allowing location queries to be run in SQL.
	- It's license information, [here](https://github.com/bitnine-oss/agens-sql/blob/master/postgis-2.1.7/COPYING)

- PgBouncer
	- PgBouncer is a lightweight connection pooler for PostgreSQL.
	- When client connects, via Session pooling, server connection will be assigned to it for the whole duration it stays connected. When client disconnects, the server connection will be put back into pool. Thus the overhead when the session and the server are connected can be reduced- Server connection is assigned to client only during a transaction via Transactino pooling. When PgBouncer notices that transaction is over, the server will be put back into pool.
	- Statement pooling enforces "autocommit" mode on client, mostly targeted for PL/Proxy.
	- It's license information, [here](https://github.com/bitnine-oss/agens-sql/blob/master/pgbouncer-1.5.5/COPYRIGHT)

- PGQ
	- PGQ, a Queueing Solution, will solve asynchronous batch processing of live transactions.
	- When you're doing many INSERT/DELETE/UPDATE of rows in a transaction during batch processing, and you want to trigger some actions before COMMIT, it will do asynchronously without blocking the live transaction.
	- It's license information, [here](no link)

- PL/Proxy
	- PL/Proxy is a database partitioning system implemented as PL Language.
	- The proxy function will be created with same signature as remote function to be called, so only destination info needs to be specified inside proxy function body.
	- It's license information, [here](https://github.com/bitnine-oss/agens-sql/blob/master/plproxy-2.5/COPYRIGHT)

- pg_hint_plan
	- The user can add hint phrases and then pg_hint_plan controls execution plan with hinting phrases.
	- It's license information, [here](https://github.com/ossc-db/pg_hint_plan/blob/master/COPYRIGHT)

- POWA(POstgresql Workload Analyzer)
	- PoWA is PostgreSQL Workload Analyzer that gathers performance stats and provides real-time charts and graphs to help monitor and tune your PostgreSQL servers.
	- It's license information, [here](https://github.com/bitnine-oss/agens-sql/blob/master/powa-archivist-REL_2_0_0/LICENSE.md)

- Pgloader
	- Pgloader loads data into PostgreSQL using the COPY streaming protocol, and doing so with separate data of MySQL, SQLite, or dBase.
	- It's license information, [here](https://github.com/bitnine-oss/agens-sql/blob/master/pgbouncer-1.5.5/COPYRIGHT)

- Orafce
	- Orafce is a module with all Oracle functions and operators compatible with Oracle.
	- It's license information, [here](https://github.com/bitnine-oss/agens-sql/blob/master/orafce-3_1/COPYRIGHT.orafce)

- etc.
	- Other package's information see each the package folder.

## License
copyright (c) 2014-2015, Bitnine Inc.

All right reserved.

1. Redistributions of Source Code must retain the copyright notices as they appear in each Source Code file, these license terms, and the disclaimer/limitation of liability set forth as paragraph 4 below.

2. Redistributions in binary form must reproduce the Copyright Notice, these license terms, and the disclaimer/limitation of liability set forth as paragraph 4 below, in the documentation and/or other materials provided with the distribution. For the purposes of binary distribution the "Copyright Notice" refers to the following language:
"Copyright (c) 2014-2015 Bitnine, Inc. All rights reserved."

3. All redistributions must comply with the conditions imposed by the University of California on certain embedded code, which copyright Notice and conditions for redistribution are as follows:

	* (a) Copyright (c) 1996-2015, The PostgreSQL Global Development Group
Copyright (c) 1994, The Regents of the University of California

	* (b) Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met :

		* (i) Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

		* (ii) Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

		* (iii) Neither the name of the Bitnine Inc. nor the University of California nor names of their contributors may be used to endorse or promote products derived from this software without specific prior written permission. The name "Agens" is a trademark of Bitnine Inc.

4. IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATIONS TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
