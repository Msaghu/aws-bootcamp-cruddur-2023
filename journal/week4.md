# Week 4 — Postgres and RDS

## Introduction

**What is AWS Relational Database Service(RDS)?**
- Allows you to create and scale relational databases in the cloud.
- RDS runs on virtual machines (can’t log in to the OS or SSH in).
- AWS handles admin tasks for you like hardware provisioning, patching & backups.
- RDS is not serverless — (one exception Aurora Serverless)
- Allows you to control network access to your database
- Offers encryption at rest — done with KMS (data stored, automated backups, read replicas and snapshots all encrypted)
- AWS Aurora is the managed version of SQL databases that is fully managed by AWS.
- When create a database we need to be sure that it has been created in the same region where our account is.
- You can create and modify a DB instance by using the AWS Command Line Interface (AWS CLI), the Amazon RDS API, or the AWS Management Console.
- Amazon RDS is responsible for hosting the software components and infrastructure of DB instances and DB cluster. We are responsible for query tuning, which is the process of adjusting SQL queries to improve performance.
- We can run our DB instance in several Availability Zones, an option called a Multi-AZ deployment. When we choose this option, Amazon automatically provisions and maintains one or more secondary standby DB instances in a different Availability Zone. Your primary DB instance is replicated across Availability Zones to each secondary DB instance.
- We use security groups to control the access to a DB instance. It does so by allowing access to IP address ranges or Amazon EC2 instances that you specify.

**Supported RDS DataBase engines**
- A DB engine is the specific relational database software that runs on your DB instance. Amazon RDS currently supports the following engines:

-MariaDB

-Microsoft SQL Server

-MySQL

-Oracle

-PostgreSQL

**Why AWS RDS Postgres over AWS Aurora?**
- For the purposes , we went for our use case and so that we can be better acquinted with SQL databases.

## Prerequisites
1. AWS Free Tier account
2. AWS CLI installed on your local environment
3. Knowledge of SQL and PostgreSQL.

## Use Cases
- Postgresql is a type of Relational Database System.
- A Relational Database System maintains the following ACID principle:
1. Atomicity
2. Consistency
3. Isolation
4. Durability

## Tasks
1. Provision an RDS instance
2. Temporarily stop an RDS instance
3. Remotely connect to RDS instance
4. Programmatically update a security group rule
5. Work with UUIDs and PSQL extensions and Create a schema SQL bash script file
7. Write bash scripts for database operations
9. Implement a postgres client for python using a connection pool
11. Troubleshoot common SQL errors
12. Implement a Lambda that runs in a VPC and commits code to RDS
13. Work with PSQL json functions to directly return json from the database
14. Correctly sanitize parameters passed to SQL to execute
  
# Spin up an PostgreSQL RDS(Relational Database System) 
### Step 1 - Provision an RDS instance via the AWS Console
- We will first have to spin up an RDS instance on AWS then stop it.
1. Search for RDS and choose **Create database**
2. On **Engine options**, choose Postgres
3. Choose the **Free tier** check box
4. Choose the **Instance configuration**
5. For **Storage**, leave the default option.
6. For **Connectivity** and **Network type** leave the default options.
7. For **Public Access** , allow public access because we are in development stage and we want to avoid associated costs that we might incur if we run it in private access.
8. Use the **Default VPC** security group.
9. For **Database port**, leave it as the default 5432(can be changed to another port number for security)
10. For **Database authentication**, aloow for password authentication.
11. As for Monitoring, so that we can see 
12. We will turn off Backup, which is whnen AWS takes a snapshot of th DB for backup whuich reduces costs 
13. Enable **Encryption**
14. Do not enable **Log exports**
15. Do not **Enable Deletion protection**, which for production should be turned on for backup purposes.

### Step 2 - Use the AWS CLI in Gitpod to create a RDS instance and create a Cruddur database in the instance
- Run ``aws sts get-caller-identity``` in the terminal to make sure that our values have been set.
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
***(make sure to add a letter at the end of the region to make it an AZ i.e us-east-1 to us-east-1a)***

### Step 3 - Temporarily stop the RDS instance
- Switch over to the AWS Console and view the creation process of the database instance. 
- When the database instance has been fully created, the status will read created.
- Click into the Database instance and in the Actions tab ***Stop temporarily***, it is stopped for 7 days (be sure to check on it after 7 days).

# Work with UUIDs and PSQL extensions and Create a schema SQL bash script file
### Step 4 - Remotely connect to RDS instance
#### Create a local Cruddur Database in PostgreSQL
- Start up Docker compose ***(docker compose up)***, then open the Docker extension and make sure that Postgres has started up,**(we added Postgres into the Docker-compose file in the earlier weeks i.e the snippet below)**.
```
  dynamodb-local:
    # https://stackoverflow.com/questions/67533058/persist-local-dynamodb-data-in-volumes-lack-permission-unable-to-open-databa
    # We needed to add user:root to get this working.
    user: root
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal
  db:
    image: postgres:13-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - '5432:5432'
    volumes: 
      - db:/var/lib/postgresql/data
```

- Open the Postgres bash then, to be able to run psql commands inside the database instance we created above, we need to install psql locally**(this means in our current Gitpod environment)**then run the following commands:
```
sudo apt update
sudo apt install -y postgresql-client-12 OR
sudo apt install -y postgresql-client-13/14
psql -Upostgres --host localhost
psql -h hostname -p portNumber -U userName dbName -W
(When it prompts for password enter: ***password***)
```
- Where the parameters are explained below:

h — The host name of your DB instance (“localhost” if the DB is running on your local machine). If you’re attempting to connect to an RDS database, the host name will be the endpoint (URL) of the instance on which the database is running. This is found in the “Connectivity” panel of the specific database, under the “RDS” service on the Amazon Web Console.

- Then to list existing databases in our RDS instance, we run
```\l```
- To create a new database called **cruddur** we will run
``` CREATE database cruddur; ```

#### Create a Connection URL to the local Cruddur Database in PostgreSQL
- As opposed to how we created the Database schema manually in our [Postgresql Databases blogpost](https://dev.to/msaghu/free-aws-bootcamp-week-4-part-2-postgresql-databases-59ig) tutorial , here we will import it/use a schema made for us as we are using the AWS managed version of Postgres.
- Since our Database will be used to store information, it will be useful in the backend.
- We will therefore create a new folder called **db** in the backend-flask folder, then we will create a file in the folder called **schema.sql**, [backend-flask/db/schema.sql](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/db/schema.sql)
-Paste the following into the ```schema.sql```, to create **UUID(along random string that allows us to obscure items in our lists/db thus making it more secure than using a linear string)**
```
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

***LONG METHOD (where we input the password each time)***
- To create the extension located in the schema.sql file, change(cd) into backend-flask then run the following command(if prompted for password enter password):
```
cd backend-flask/
psql cruddur < db/schema.sql -h localhost -U postgres   =====> this will create an extension from schema.sql
```

***SHORT METHOD USING A CONNECTION URL STRING(where we do not have to input the password each time)***
- To be able to get into our cruddur database(the short method). Run the following in the terminal(This will show that it works):
```
psql postgresql://postgres:password@localhost:5432/cruddur 
OR
psql postgresql://postgres:password@127.0.0.1:5432/cruddur
```

***OR, Set it as an environment variable***

- In the terminal, paste the following in the terminal(we should still be in backend-flask):
```
export CONNECTION_URL="postgresql://postgres:password@127.0.0.1:5432/cruddur"
psql $CONNECTION_URL
```

- In the terminal, paste in the following (we should still be in backend-flask) to set as an environment variable:
```
gp env CONNECTION_URL="psql postgresql://postgres:password@127.0.0.1:5432/cruddur"
```

# Write bash scripts for database operations
### Step 5 - Bash Scripting
- We will create 3 new files in backend-flask folder so that we can run bash scripts that enable us to quickly manage our databases; ```db-create, db-seed, db-drop, db-schema-load```
- In the terminal run to get the path of bash in our environment and paste in as the first line of our files:
``` whereis bash```

- Copy the path into all the three files above. Remember to create a shabang(#!) at the beginning of all the files that will indicate that they are bash files. The files will look like:
``` #! /usr/bin/bash ```

- Create the db-create file by pasting in ;
```
#! /usr/bin/bash
```

- To enable us to run the files as scripts, we need to be able to change their permissions so that they are executable, we can do this by running the following command for all the 3 files:
```
chmod u+x bin/db-create
chmod u+x bin/db-drop
chmod u+x bin/db-schema-load 
```

**DB_DROP - A script to drop an existing database**

- Therefore, if we want to get into psql with the command without going into our cruddur database, we will paste the following into our ```/backend-flask/bin/db-drop``` script:
```
#! /usr/bin/bash

echo "db-drop"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<< "$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "DROP DATABASE cruddur;"
```

- Then we can execute/run the script by pasting into the terminal, to delete the cruddur database:
```
./bin/db-drop
```

***If we are still connected to the database we accessed above , we cannot drop it thus the command above will give an error, because we are still in the cruddur database(remember the command we ran above?):
```
echo $CONNECTION_URL   (output)======>postgresql://postgres:password@127.0.0.1:5432/cruddur
```
***

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
schema_path ="$(real_path .)/db/schema.sql"

echo $schema_path

psql $CONNECTION_URL cruddur < $chema.sql
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

# Interact with the Postres database

**To install the Python postgresql client**
- We will install the binaries by pasting the following into ```requirements.txt``
```
psycopg[binary]
psycopg[pool]
```

- Then running ```pip install -r requirements.txt``` in the terminal.

**Database Connection pools**
- We will now create a **connection pool**(connection pooling is the process of having a pool of active connections on the backend servers. These can be used any time a user sends a request. Instead of opening, maintaining, and closing a connection when a user sends a request, the server will assign an active connection to the user.)
- Create a file called in lib called, ```db.py``` [backend-flask/lib/db.py]((https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/lib/db.py) and paste in:
```
from psycopg_pool import ConnectionPool
import os

#lets postgres change sql to json
def query_wrap_object(self, template):
  sql = f"""
  (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
  {template}
  ) object_row);
  """
  return sql

#lets postgres change sql to json
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

- Then pass it in our ```docker-compose file``` by passing in the connection string, environment section:
``` CONNECTION_URL: "${CONNECTION_URL}" ```

- Then pass it in ```home-activities.py```:
```from lib.db import pool```
and add in
```
sql = query_wrap_array("""
SELECT * FROM activities
""")
with pool.connection() as conn:
        with conn.cursor() as cur:
          cur.execute(sql)
          # this will return a tuple
          # the first field being the data
          json = cur.fetchall()
      return json[0]
```

- Then run ```docker compose up```
- Check that the backend container is running
- Remove the logging by X-Ray by commenting it out in ```app.py``` and in ```home-activities.py```
***If we get the errors in the backend check that the connection url was passed into the container***
- In ```home-activities.py``` paste in the follwoing code block:
```
results = db.query_array_json("""
      SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC    
    """)
##    span.set_attributes("app.result_length", len(results))
    return results
```
- Our frontend application via the tab should show a query as a post with the username

  
### STEP 9 - Connecting to the Cruddur Database Production RDS instance
- We will turn on our database via the AWS RDS console 
- Then we will change our database password within the console.
- In the terminal, run ```echo $PROD_CONNECTION_URL``` and copy the output provided.

#### Testing remote access to the RDS instance
- Then to test remote access , we will paste the command below ***(this is the output from echo $PROD_CONNECTION_URL)*** in the terminal then, change the passwordpassword item to the password of your choosing.
***@cruddur-db-instance.czz1cuvepklc.ca-central-1.rds.amazonaws.com is the RDS Endpoint port (get this value from the RDS console page of the cruddur database)***
``` 
postgresql://cruddurroot:passwordpassword@cruddur-db-instance.czz1cuvepklc.ca-central-1.rds.amazonaws.com:5432/cruddur
```

- Then set it as an envrionment variable in the system by:
```
export PROD_CONNECTION_URL="postgresql://cruddurroot:passwordpassword@cruddur-db-instance.czz1cuvepklc.ca-central-1.rds.amazonaws.com:5432/cruddur"

gp env PROD_CONNECTION_URL="postgresql://cruddurroot:passwordpassword@cruddur-db-instance.czz1cuvepklc.ca-central-1.rds.amazonaws.com:5432/cruddur"

env | grep PROD 
```

- Test that you can connect to the database by running in the terminal:
```
psql $CONNECTION_URL
then
psql $PROD_CONNECTION_URL
```

- The first line will work but the second will hang until we add an inbound rule for the RDS instance Security Group.

#### Edit the VPC inbound rules
- Determine our Gitpod IP address by running in the terminal (run line 1) then set it as an environment variable using line 2:
```
curl ifconfig.me
export GITPOD_IP=$(curl ifconfig.me)
echo $GITPOD_IP
```
- Copy the output and paste it as the ip address in the AWS inbound rules section.
- To enable it, we need to edit the inbound rules for the RDS VPC.
- Go to the AWS RDS Console and in the ```Connectivity``` section, choose it then click on ```inbound rules```
- We will edit the inbound rules, add **TYpe** as PostgreSQL ,>  **Source** as Custom and add the IP as the value of ***echo $GITPOD_IP***> Decsription as **GITPOD**

- Running ```psql $PROD_CONNECTION_URL``` in the terminal will now work.
***Incase you are still unable to access the database using $PROD_CONNECTION_URL, try changing the following $PROD_CONNECTION_URL variable(instead of cruddurroot, we use root)
export PROD_CONNECTION_URL="postgresql://root:passwordpassword@cruddur-db-instance.czz1cuvepklc.ca-central-1.rds.amazonaws.com:5433/cruddur"
gp env PROD_CONNECTION_URL="postgresql://root:passwordpassword@cruddur-db-instance.czz1cuvepklc.ca-central-1.rds.amazonaws.com:5433/cruddur"***

#### Permanently setting the GITPOD.IO variables for the Security group
- Change the values with the appropriate vaules of the ```security group id``` and ```security group rule id```, which you will get from the AWS Console for the Security group that was created above.
- Paste the following into the terminal to set:
```
export DB_SG_ID="sg-56fghfghhhhghghhghg"
gp env DB_SG_ID="sg-56fghfghhhhghghhghg"

export DB_SG_RULE_ID="sgr-76cgcgvbvbnvnvnvnn"
gp env DB_SG_RULE_ID="sgr-76cgcgvbvbnvnvnvnn"
```

- Create an inbound rule that allows internet from evrywhere, 0.0.0.0/0 and test that it is changed when we run the code below:
```
aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```
***For $DB_SG_ID-copy the Security Group ID from the Security group we created above,
For $DB_SG_RULE_ID-copy the Security Group Rule ID for the rule that allows the traffic from our GITPO/environment IP address***
- To make sure that this Security group is always updated, we will create a bash script from the code abive to always update its IP whenever we spin up a new Gitpod environment.
- Create a script in [bin/rds-update-sg-rule](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/tree/main/bin/rds):
```
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="rds-update-sg-rules"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```
-Change its permissions to make its executable
- In ```Gitpod.yml``` add the bash script so that it runs everytime we start up the environment:
```
command: |
      export GITPOD_IP=$(curl ifconfig.me)
      source  "$THEIA_WORKSPACE_ROOT/bin/rds/update-sg-rules"
```
- Whenever we restart a new environment and run ```./bin/db-connect prod```, it will successfully connect(as long as RDS is on in the AWS console).

  
# Implementing a Custom authorizer for Cognito
### STEP 10 - Cognito Post Confirmation Lambda
- Created a Lambda in the AWS LAMBDA console called ```cruddur-post-confirmation```
- Create a new file in the aws folder named [aws/cruddur-post-confirmation](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/aws/lambdas/cruddur-post-confirmation) and paste in:

```
import json
import psycopg2

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    print('userAttributes')
    print(user)

    user_display_name   = user['name']
    user_email          = user['email']
    user_handle         = user['preferred_username']
    user_cognito_id     = user ['sub']

    try:
        conn = psycopg2.connect(os.getenv('CONNECTION_URL'))
        cur = conn.cursor()
     
        sql = f"""
          "INSERT INTO users (
            display_name, 
            email,
            handle, 
            cognito_user_id
            )
           VALUES(
             {user_display_name}, 
             {user_email}, 
             {user_handle},
             {user_cognito_id}
            )"
        """
        cur.execute(sql)
        conn.commit() 

    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        
    finally:
        if conn is not None:
            cur.close()
            conn.close()
            print('Database connection closed.')

    return event
```

- In the Configuration tab in the Lambda function console, paste in the environment variable for the database:

```
env | grep PROD   ===> copy the ouptut and paste it into Lambda
```

- Add a Layer in the Code tab.
- In the AWS Cognito console, trigger the Lambda function by clickin in the ```User pool properties``` tab then choose ```Add Lambda trigger```.
***(Add Lambda triggerInfo
You can customize your users' experience by using Lambda functions to respond to authentication and authorization events. Use up to 10 different Lambda triggers to filter sign-ups and sign-ins, modify and import users, add custom authentication flows, and more. In addition, you can use Lambda function logging for deeper insight into trigger activity.)***

- Choose the trigger type as **Sign up**
- Choose **Post confirmation trigger**
- Choose ```cruddur-post-confirmation```, which is the Lambda function created above and create the trigger.
- Go back to AWS Lambda console and refresh. Choose the **Monitor Tab** to make sure that the trigger works whenever a sign up is made, this will always be displayed via the logs. Choose the **logs** tab

- This will redirect you to AWS CloudWatch, choose the log groups
- Then choose ```AWS/lambda/cruddur-post-confirmation``` tab and view the logs.
- We will then set the VPC for the cruddur function in lambda otherwise when we try to sign up, it will always time out.

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

### Security for Amazon RDS and Postgres
**Security best practises - AWS**
- Use VPCs: Use Amazon Virtual Private Cloud to create a private netwrok for your RDS instance. This helps prevent unauthorized access to your instance from the public internet. While creat9ing security groups, NEVER allow inbound traffic from the internet, but rather only from known IP adderesses.
- Compliance standard is what the business requires.
- RDS Instances should only be in the AWS region that you are legally allowed to be holding user data in.
- Amazon Organisations SCP - to manage RDS deletion, RDS creation, region lock, RDS encryption enforced.
- AWS CloudTrail is enabled and monitored to trigger alerts on malicious RDS behaviour by an identity in AWS.
- Amazon Guard Duty is enabled in the account and region of RDS.

**Security best practises - Application/Developer**
- RDS instance to use appropriate authentication - Use IAM authentication, kerberos 
- Database User Lifecycle Management - Create, Modify, Delete Users
- Security Group to be restricted only to known IPs
- Should not have the RDS be internet accessible
- Encryption in Transit for comms between Apps and RDS
- Secret Management - Master user password can be used with AWS Secrets Manager to automatically rotate the secrets for the Amazon RDS.

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

## Next Steps - Additional Homework Challenges



**RESOURCES**
1. [AWS RDS CLI - Documentation](https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html)
2. [Postgres Connection RUL](https://stackoverflow.com/questions/3582552/what-is-the-format-for-the-postgresql-connection-string-url)
3. [Postgres Python drivers session 3](https://www.tutorialspoint.com/postgresql/postgresql_python.htm#:~:text=The%20PostgreSQL%20can%20be%20integrated,and%20stable%20as%20a%20rock.)
