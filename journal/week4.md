# Week 4 — Postgres and RDS

## Introduction

**Why AWS RDS Postgres over AWS Aurora?**

## Prerequisites
1. AWS Free Tier account
2. AWS CLI on your local environment
3. Knowledge of SQL and PostgreSQL.

## Use Cases
- Postgresql is a type of Relational Database System.
- A Relational Database System maintains the following ACID principle:
1. Atomicity
2. Consistency
3. Isolation
4. Durability

## Tasks
- Provision an RDS instance
- Temporarily stop an RDS instance
- Remotely connect to RDS instance
- Programmatically update a security group rule
- Write several bash scripts for database operations
- Operate common SQL commands
- Create a schema SQL file by hand
- Work with UUIDs and PSQL extensions
- Implement a postgres client for python using a connection pool
- Troubleshoot common SQL errors
- Implement a Lambda that runs in a VPC and commits code to RDS
- Work with PSQL json functions to directly return json from the database
- Correctly sanitize parameters passed to SQL to execute
 
 
### Security for Amazon RDS and Postgres
**What are the different types of Amazon RDS Databse Engines?**
- Amazon Aurora
- MySQL
- MariaDB
- PostreSQL
- Oracle
- Microsoft SQL Server

**Security best practises - AWS**
- Use VPCs: Use Amazon Virtula Private Cloud to create a private netwrok for your RDS instance. This helps prevent unauthorized access to your instance from the public internet.
- Compliance standard is what the business requires.
- RDS Instances should only be in the AWS region that you are legally allowed to be holding user data in.
- Amazon Oranisations SCP - to manage RDS deletion, RDS creation, region lock, RDS encryption enforced.
- AWS CloudTrail is enabled and monitored to trigger alerts on malicious RDS behaviour by an identity in AWS.
- Amazon Guard Duty is enabled in the account and region of RDS.

**Security best practises - Application/Developer**
- RDS instance to use appropriate authentication - Use IAM authentication, kerberos 
- Database User Lifecycle Management - Create, Modify, Delete Users
- Security Group to be restrictedonly to known IPs
- Not have RDS be internet accessible
- Encryption in Transit for comms between Apps and RDS
- Secret Management - Master user password can be used with AWS Secrets Manager to automatically rotate the secrets for the Amazon RDS.

### Spin up an PostgreSQL RDS(Relational Database System) via the AWS Console
**Step 1 - Provision an RDS instance**
- We will first have to spin up an RDS instance on AWS then stop it.
1. Search for RDS and choose **Create database**
2. On **Engine options**, choose Postgres
3. Choose the **Free tier** check box
4. Choose the **Instance configuration**
5. For **Storage**, leave the default option.
6. For **Connectivity** and **Network type** leave the default options.
7. For **Public Access** , allow public access
8. Use the **Default VPC** security group.
9. For **Database port**, leave it as the default 5432
10. For **Database authentication**, aloow for password authentication.
11. As for Monitoring, so that we can see 
12. We will turn off Backup, which is whnen AWS takes a snapshot of th DB for backup whuich reduces costs 
13. Enable **Encryption**
14. Do not enable **Log exports**
15. Do not **Enable Deletion protection**, which for production should be turned on for backup purposes.


### Provision RDS Instance
**Step 2 - Use the AWS CLI in Gitpod to create a RDS instance and create a Cruddur database in the instance**
- Use the following command to create an RDS instance via the CLI, notice that the commands follow the set up in Step 1.
```
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username cruddurroot \
  --master-user-password milkyway2023 \
  --allocated-storage 20 \
  --availability-zone us-east-1a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```

- Switch over to the AWS Console and view the creation process of the database instance. 
- When the database instance has been fully created, the status will read created.
- Click into the Database instance and in the Actions tab Stop temporarily, it is stopped for 7 days (be sure to check on it after 7 days).
 
### Remotely connect to RDS instance
**Step 3 - Create a local Cruddur Database in PostgreSQL**
- Start up Docker compose, then open the Docker extension and make sure that Postgres has started up,( we added Postgres into the Docker-compose file in the earlier weeks).
- Open the Postgres bash then, to be able to run psql commands inside the database instance we created above, run the following commands:
```
sudo apt update
sudo apt install -y postgresql-client-12
psql -Upostgres --host localhost
(When it prompts for password enter: ***password***
```

- Then to list existing databases run ```\l```
- To create a new database called cruddur we will run
``` CREATE database cruddur; ```

- As opposed to how we created the Database schema manually in our Dev.to tutorial , link below, here we will import it/ use a premade
- Since our Database will be used to store information, it will be useful in the backend.
- We will therefore create a new folder called **db** in the backend-flask folder, then we will create a file in the folder called **schema.sql**
-Paste the following into the schema.sql 
```
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```
***LONG METHOD (where we do not have to input the password each time)***
- To create the extension located in the schema.sql file, change(cd) into backend-flask then run the following command(if prompted for password enter password):
```
cd backend-flask/
psql cruddur < db/schema.sql -h localhost -U postgres   =====> this will create an extension from schema.sql
```

***SHORT METHOD (where we do not have to input the password each time)***
- To be able to get into our cruddur database(the short method). Run the following in the terminal(This will show that it works):
```
psql postgresql://postgres:password@localhost:5432/cruddur 
OR
psql postgresql://postgres:password@127.0.0.1:5432/cruddur
```

***OR***

- In the terminal, paste the following in the terminal(we should still be in backend-flask):
```
export CONNECTION_URL="postgresql://postgres:password@127.0.0.1:5432/cruddur"
psql $CONNECTION_URL
```

- In the terminal, paste in the following (we should still be in backend-flask) to set as an environment variable:
```
gp env CONNECTION_URL="psql postgresql://postgres:password@127.0.0.1:5432/cruddur"
```

**Common PostgreSQL commands**
```
\x on -- expanded display when looking at data
\q -- Quit PSQL
\l -- List all databases
\c database_name -- Connect to a specific database
\dt -- List all tables in the current database
\d table_name -- Describe a specific table
\du -- List all users and their roles
\dn -- List all schemas in the current database
CREATE DATABASE database_name; -- Create a new database
DROP DATABASE database_name; -- Delete a database
CREATE TABLE table_name (column1 datatype1, column2 datatype2, ...); -- Create a new table
DROP TABLE table_name; -- Delete a table
SELECT column1, column2, ... FROM table_name WHERE condition; -- Select data from a table
INSERT INTO table_name (column1, column2, ...) VALUES (value1, value2, ...); -- Insert data into a table
UPDATE table_name SET column1 = value1, column2 = value2, ... WHERE condition; -- Update data in a table
DELETE FROM table_name WHERE condition; -- Delete data from a table
```

### Step 4 - Bash Scripting
- We will create 3 new files in backend-flask folder so that we can run bash scripts that enable us to quickly manage our databases; ```db-create, db-seed, db-drop, db-schema-load```
- In the terminal run 
``` whereis bash```

- Copy the path into all the three files above. Remember to create a shabang(#!) at the beginning of all the files that will indicate that they are bash files. The files will look like:
``` #! /usr/bin/bash ```

- Create the db-create file by pasting in ;
```
#! /usr/bin/bash

```

- To enable us to run the files as scripts, we need to be able to change their permissions so that they are executable, we can do this by running the following command on all the 3 files:
```
chmod u+x bin/db-create
chmod u+x bin/db-drop
chmod u+x bin/db-schema-load 
```

- We can test that the db-drop script is working by running:
``` ./bin/db-drop ```

- As we can see the command above will give an error, because we are still in the cruddur database(remember the command we ran above?):
```
echo $CONNECTION_URL   (output)======>postgresql://postgres:password@127.0.0.1:5432/cruddur
```

**DB_DROP - A script to drop an existing database**

- Therefore, if we want to get into psql with the command without going into our cruddur database, we will paste the following into our ```db-drop``` script:
```
#! /usr/bin/bash

echo "db-drop"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<< "$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "DROP DATABASE cruddur;"
```

- Then we can execute/run the sript by pasting into the terminal, to delete the cruddur database:
```
./bin/db-drop
```

**DB_CREATE - A shell to create a database**

- To use a script to create a cruddur database(again), paste the follwong in the ```db-create``` file:
```
#! /usr/bin/bash

echo "db-create"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<< "$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "CREATE DATABASE cruddur;"
```

- Run ```./bin/db-create```

**DB_SCHEMA-LOAD - A shell script to load the schema for the existing database**

- To load the schema, paste the following in db-schema-load
```
#! /usr/bin/bash

echo "db-schema-load"

psql $CONNECTION_URL cruddur < db/schema.sql
```

- Run ```./bin/db-schema-load```

**DB_CONNECT - A shell script to connect to the existing database**

- Create a db-connect file and paste
```
#! /usr/bin/bash

psql $CONNECTION_URL 
```

***For all the 3 bash scripts remember to change their permissions first otherwise running them will give permission denied i.e for the ```db-connect``` file***
***```chmod u+x ./bin/db-connect 
then run 
./bin/db-connect```***

### STEP 5 - Making the output nicer

- To make the bash script nicer, paste in ```db-schema-load```
```
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"
```

### STEP 6 - Making the output nicer
- To create tables within our database, paste the code into the ```schema.sql``` file:
```
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;

CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text,
  handle text,
  cognito_user_id text,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```

- The drop table lines will make sure that if there are any existing tables in the database, they are deleted first before the new tables are created.

### STEP 7 - Seeding/Adding data to the tables
- To add data, we will create a new file within db called seed.sql and add in the code below:
```
-- this file was manually created
INSERT INTO public.users (display_name, handle, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown' ,'MOCK'),
  ('Andrew Bayko', 'bayko' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
```

- Also create a file db-seed in our bash script files.
- Make sure to change permissions for the file in the terminal using:
```chmod u+x ./bin/db-seed```

- Then run ```./bin/db-seed``` in the terminal

### STEP 8 - Connect to the database using the Databse explorer
- We will now need to connect to our database,(via the short method i.e calling the db-connect script);
- I the terminal, run ```./bin/db-connect```
- Once we are in the cruddur databse, run
```
\dt                                         =====> to view all tables
SELECT * FROM cruddur;                       =====> to show all culumns/fields in the cruddur DB
\ x on
\ x auto 
```

- Choose Database explorer from the left hand side of the console, click on the + tab , then 
choose database type as postgres
type in cruddur as the connection name
username should be postgres and port 5432
type in password as password
then enter cruddur as databases
then click connect

- If we attempt to drop the database using the script from the terminal, we will find that it 
the response will be that other connections are using it, as shown in the point above.

**DB_SESSIONS - A shell script to see active connections**
- To see other connections/sessions accesing our db, we will create a new script ```db-sessions```  and paste the code:
```
#! /usr/bin/bash

CYAN='\035[1;36m'
NO_COLOR='\035[0m'
LABEL="db-sessions"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

if ["$1" = "prod" ]; then
    echo "using production"
    URL=$PROD_CONNECTION_URL
else
    URL=$CONNECTION_URL
fi

NO_DB_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_URL -c "select pid as process_id, \
       usename as user,  \
       datname as db, \
       client_addr, \
       application_name as app,\
       state \
from pg_stat_activity;"
```

- We will then execute, ```./bin/db-sessions``` in the terminal to see the live connections.
- We can disable the connection from the Database explorer and then run ```./bin/db-sessions``` to see see if the se3rvice is still active.
- Use DOCKER_COMPOSE UP to forcefully kill all the sessions.(not recommended).


**DB_SETUP - A shell script to see speedup our workflow(Create DBs faster)**
- To enable us to execute commands faster, we will create a new script ```db-setup``` and paste in 
```
#! /usr/bin/bash

CYAN='\035[1;36m'
NO_COLOR='\035[0m'
LABEL="db-setup"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

bin_path="$(realpath .)/bin/"

source "$bin_path/db-drop"
source "$bin_path/db-create"
source "$bin_path/db-schema-load"
source "$bin_path/db-seed"
```

**To install the Python postgresql client**
- We will install the binaries by pasting the following into ```requirements.txt``
```
psycopg[binary]
psycopg[pool]
```

- Then running ```pip install requirements.txt``` in the terminal.

**Database Creation pool**
- We will now create a **connection pool**(connection pooling is the process of having a pool of active connections on the backend servers. These can be used any time a user sends a request. Instead of opening, maintaining, and closing a connection when a user sends a request, the server will assign an active connection to the user.)
- Create a file called in lib called, ```db.py``` (backend-flask/lib/db.py) and paste in:
```
from psycopg_pool import ConnectionPool
import os

def query_wrap_object(self, template):
  sql = f"""
  (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
  {template}
  ) object_row);
  """
  return sql

def query_wrap_array(self, template):
  sql =  f"""
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  """
  return sql

connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)
```

- Then pass it in our docker-compose file by passing in the connection string:
``` CONNECTION_URL: "${PROD_CONNECTION_URL}" ```

- Then pass it in ```home-activities.py```:
```from lib.db import pool```



### STEP 9 - Cognito Post Confirmation Lambda
- Created a Lambda in AWS LAMBDA called ```cruddur-post-confirmation```
- 









**Errors encountered**
- When running ./bin/db-schema-load this was the error that I was encountering(i had begun video 2? the next day):
``` 
== db-schema-load
== db-schema-load
/workspace/aws-bootcamp-cruddur-2023/backend-flask/db/schema.sql
./bin/db-schema-load: line 13: [: =: unary operator expected
psql: error: could not connect to server: No such file or directory
        Is the server running locally and accepting
        connections on Unix domain socket "/var/run/postgresql/.s.PGSQL.5432"?
```

## Next Steps - Additional Homework Challenges



**RESOURCES**
1. [AWS RDS CLI - Documentation](https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html)
2. [Postgres Connection RUL](https://stackoverflow.com/questions/3582552/what-is-the-format-for-the-postgresql-connection-string-url)
3. [Postgres Python drivers session 3](https://www.tutorialspoint.com/postgresql/postgresql_python.htm#:~:text=The%20PostgreSQL%20can%20be%20integrated,and%20stable%20as%20a%20rock.)
