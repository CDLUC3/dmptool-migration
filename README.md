# dmptool-migration
SQLMesh code to facilitate data migration from the old Rails DMP Tool to the new JS system

Requirements:
- python3
- mysql client
- duckdb

## Setup
Create a python virtual environment:
```
python3 -m venv venv
```

Install dependencies:
```
pip install -r requirements.txt
```

Create a `.env` file with the following variables, customizing where appropriate:
```bash
MYSQL_DATABASE=migration
MYSQL_HOST=localhost
MYSQL_TCP_PORT=3306
MYSQL_USER=user
MYSQL_PWD=password
```

## Moving your source database to the same server as your target database

SQLMesh requires that your source database and target database reside on the same server. If you need to move your source database to the same server as your target database, you can use `mysqldump` and `mysql` to export and import the database.
For example:
```shell
# Dump the source database
mysqldump -h [host] -P [port] -u [username] -p [database] \
  --single-transaction --quick --skip-lock-tables --lock-tables=false --set-gtid-purged=OFF \
  --tables annotations departments identifiers languages plans orgs phases question_options questions questions_themes registry_orgs research_domains roles sections templates themes users users_perms \
  > ~/source_db.sql

# Create the target database on the new server
mysql -u [username] -p -P [port] -h [host] -e "CREATE DATABASE source_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Import the source database dump into the new server
mysql -u [username] -p -P [port] -h [host] source_db < ~/source_db.sql
```
This does not work for mysql v9, so be sure to install v8!
Note that you may need to use `127.0.0.1` instead of `localhost` for the host to avoid socket connection issues.

## Setting up the ROR staging table (All the ROR records from the ROR data file)

To create the `ror_staging` table you must add the ROR JSON data file to the `./data` directory and run the `python3 ./scripts/transform_ror.py` script to transform the JSON data into a format suitable for loading into MySQL. 

First make sure the `migration.ror_staging` table exists:
```sql
CREATE TABLE IF NOT EXISTS `migration.ror_staging` (
  `uri` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `provenance` varchar(16) NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `displayName` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `searchName` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `funder` tinyint(1) NOT NULL DEFAULT '0',
  `fundrefId` varchar(255) DEFAULT NULL,
  `homepage` varchar(255) DEFAULT NULL,
  `domain` varchar(255) DEFAULT NULL,
  `acronyms` json DEFAULT NULL,
  `aliases` json DEFAULT NULL,
  `types` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

Then run the following commands to transform and load the ROR data:
```bash
# Transform the ROR data by extracting only the info we want
> python3 ./scripts/transform_ror.py
# Load the transformed ROR data into DuckDB and mount as a table in MySQL
> set -a; source .env; set +a
> duckdb ':memory:' < ./scripts/load_ror_staging.sql
```

## TODO: Cleanup of old data before migration

Clean up `registry_orgs` and `orgs` table which has around 135 entries. Run the following query, then merge them manually based on `displayName`:
```
SELECT displayName, count(id) AS id_count
FROM migration.affiliations
GROUP BY displayName
HAVING id_count > 1;
```

## Extract and Transform the data from the source database using SQLMesh

Run SQLMesh plan in a dev environment:
```bash
sqlmesh plan [environment name]
```

Run SQLMesh plan in the prod environment:
```bash
sqlmesh plan
```

## Load the transformed data into the target database

Munually run the SQL statements in the [Final Migrations file](docs/FinalMigrationSteps.sql) against the target database to load the transformed data.
