# Week 5 — DynamoDB and Serverless Caching
Hi guys! Welcome back to week 5!! It getting hotter in the kitchen but lets learn about a few definitions today.
This week will be learning about NoSQl Databases and the different types that exist.
- Then we will learn about NoSQL databases in AWS, which in our case is DynamoDB. So lets start!!

 
## Introduction
**What is NoSQL**
- A flexible document management system for key-value,document, tabular and graphs.
- Non-relational, distributed and scalable. and partition tolerant and 

**Why use NoSQL?**
- Application Development Productivity.
- Large scale data
- They mainatin perfomance no matter the scale of  

**What are the characteristics of NoSQL databases?**
- Non-relational
- Distributed system that can manage large scale data while maintaining high throughput and availability.
- Scalable

**What are the differences between Non-Relational vs Relational Databases?**
| ---Non-Relational Databases---  | ---Relational Databases |
- NOT ONLY tables with fixed columns and rows vs Tables with fixed columns and rows
- Flexible schema vs Fixed Schema
- Scales out(horizontally scaling) vs Scales up(vertical scaling)

**What are the types of NoSQL database types?**
- key-value,
- document, 
- tabular and 
- graphs
- Multi-model type

**Advantages of DynamoDB**
- Fast
- Consistent perfomance
- Easily Scalable 

## Prerequisites
1. Make sure that the following environment variables have been set so that we can securely reference them in our code without exposing important information
- AWS REGION
- 

## Business Use Cases for DynamoDB
1. Will be used with our application for message caching
2. To create Amazon DynamoDB table for developers to use for their Web Application in AWS to allow for ***uninterrupted flow for a large amount of traffic in microseconds.***
3. For ***milli-second response times***, we add a Amazon DynamoDB Accelerator (DAX) to improve the response time of the DynamoDB tables that has been linked to the Web Application in AWS.

## Tasks
- Data modelling (Single Table Design) to determine relationships in our  DynamoDB table.
- Launch DynamoDB local
- Seed our DynamoDB tables with data from ChatGPT
- Write AWS SDK code for DynamoDB to query and scan put-item, for predefined endpoints
- Create a production DynamoDB table
- Update our backend app to use the production DynamoDB

## Data modelling (Single Table Design) to determine relationships in our  DynamoDB table.
**Step 1 - DynamoDB Data Modelling**
A flat table as we do not have joins as is the case with Relational databases.
For this use case, we will use Single Table Design so that all the related data(the conversations) are stored in a single table design. This technique ensures that data is fetched very fast and reliably. Since similar items are stored in the same table, it reduces complexity in the application

***Access Patterns***
1. **PATTERN A - A single conversation within the DM** - Determines the habit that a user will most likely use i.e to view messages in the dms, sort messages in descending order and only for the messages with the 2 users.
2. **Pattern B - List of Conversations(all dms)s** - Shows message groups so that users can see a list of all messages with other users i.e DMs.
3. **Pattern C - Create a new message** - Creates a new message in a new message group. 
4. **Pattern D - Update message for the last message group** - Creates a new message in an existing message group

This means that our DynamoDB table needs the following code to differentiate the access patterns:
```
my_message_group = {
    'pk': {'S': f"GRP#{my_user_uuid}"},
    'sk': {'S': last_message_at},
    'message_group_uuid': {'S': message_group_uuid},
    'message': {'S': message},
    'user_uuid': {'S': other_user_uuid},
    'user_display_name': {'S': other_user_display_name},
    'user_handle':  {'S': other_user_handle}
}

other_message_group = {
    'pk': {'S': f"GRP#{other_user_uuid}"},
    'sk': {'S': last_message_at},
    'message_group_uuid': {'S': message_group_uuid},
    'message': {'S': message},
    'user_uuid': {'S': my_user_uuid},
    'user_display_name': {'S': my_user_display_name},
    'user_handle':  {'S': my_user_handle}
}

message = {
    'pk':   {'S': f"MSG#{message_group_uuid}"},
    'sk':   {'S': created_at},
    'message': {'S': message},
    'message_uuid': {'S': message_uuid},
    'user_uuid': {'S': my_user_uuid},
    'user_display_name': {'S': my_user_display_name},
    'user_handle': {'S': my_user_handle}
}
```

### Launch DynamoDB local
**Step 2 - Start up DynamoDB locally**
- In the backend-flask directory, install Boto3(the AWS python SDK) in our backend by pasting line 2 into ```backend-flask/requirements.txt``` and running line 3 in the terminal :
``` 
boto3
pip install -r requirements.txt
```
- Boto3 is the AWS SDK for Python that allows us to use Python in AWS tp create, configure and manage AWS.
- Run ```Docker-compose up``` to start up Dynamo-db local.
- We will now create new folders in backend-flask to store the utility scripts: 
- In the existing ```backend-flask/bin``` directory, create a new folder named ```/db``` and move all the scripts for the Postgres database only
- In the existing ```backend-flask/bin``` directory, create a new folder named ```/rds``` and move the remaining rds script file for the AWS RDS Postgres database update-cognito-ids scripts .
- In the existing ```backend-flask/bin``` directory, create a new folder named ```backend-flask/bin/ddb ``` for the DynamoDB database only,
- In docker-compose.yml make sure to set CONNECTION_URL: "postgresql://postgres:password@db:5432/cruddur" . 
- Whenever we run ```docker-compose up``` and run the setup script, we create a local Postgres database named ```cruddur``` with 2 tables, USERS and . 

### Bash script changes for the Postgres database
**Step 3 -  Creating a new user in the Seed Bash Script**
- We will be creating a new user in the seed.sql as we are working with the users data queried from the local Postgres database named cruddur that we created in week 5.
- Added a new user in the ```backend-flask/db/seed``` , make sure that the vaulues reflect you as one of the users, andrew as a test and the new user Londo
- [backend-flask/db/seed](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/db/seed.sql)

**Step 4-  List existing users in Cognito**
- In week 4 we created users in AWS Cognito, we will now be using the same users in our application, however we need to make sure they exist, therefore the following script will show the created users from AWS Cognito.
- We will create a new file in cognito , ```backend-flask/bin/cognito/list-users``` :
- [backend-flask/bin/cognito/list-users](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/cognito/list-users)

**Step 5-  Update cognito user ids in Postgres with values from AWS Cognito**
- Once we confirm that the users exist, we will now need to update the values of their AWS Cognito IDs into our local postgres table.
- First, we can also confirm that our users exist locally too by first accessing our Postgres table(run the following script ```./bin/db/connect```) then running the following commands in postgres:
```
\dt
\x auto
SELECT * FROM users;
\q
```

- We can now create a new file ```backend-flask/bin/db/update_cognito_user_ids```, then run the file to update the value of MOCK with the values of their AWS Cognito IDs. 
```
#!/usr/bin/env python3

import boto3
import os
import sys

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..'))
sys.path.append(parent_path)
from lib.db import db

def update_users_with_cognito_user_id(handle, sub):
    sql = """
    UPDATE public.users
    SET cognito_user_id = %(sub)s
    WHERE
      users.handle = %(handle)s;
  """
    db.query_commit(sql, {
        'handle': handle,
        'sub': sub
    })


def get_cognito_user_ids():
    userpool_id = os.getenv("AWS_COGNITO_USER_POOL_ID")
    client = boto3.client('cognito-idp')
    params = {
        'UserPoolId': userpool_id,
        'AttributesToGet': [
            'preferred_username',
            'sub'
        ]
    }
    response = client.list_users(**params)
    users = response['Users']
    dict_users = {}
    for user in users:
        attrs = user['Attributes']
        sub = next((a for a in attrs if a["Name"] == 'sub'), None)
        handle = next(
            (a for a in attrs if a["Name"] == 'preferred_username'), None)
        dict_users[handle['Value']] = sub['Value']
    return dict_users


users = get_cognito_user_ids()

for handle, sub in users.items():
    print('----', handle, sub)
    update_users_with_cognito_user_id(
        handle=handle,
        sub=sub
    )
```

- Now add ```python "$bin_path/db/update_cognito_user_ids"``` as the last line of ```backend-flask/bin/db/setup```, so that ```bin/db/update_cognito_user_ids``` automatically runs whenever we set up our local postgres table when we run ```/bin/db/setup``` i.e
```
#! /usr/bin/bash

set -e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-setup"
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

bin_path="$(realpath .)/bin"

source "$bin_path/db/drop"
source "$bin_path/db/create"
source "$bin_path/db/schema-load"
source "$bin_path/db/seed"
python "$bin_path/db/update_cognito_user_ids"
```

### Creating DynamoDB Utility SCripts
- In the existing ``backend-flask/bin``` directory, create a new folder named ```ddb```, which will store our scripts for DynamoDB.
- In Dynamodb, we create tables instead of databases. Therefore one of the scripts will be, ```schema-load```, ```seed```, ```drop```.

**Step 6 -  Creating Schema-load Bash Script**
- We will then create the ```schema-load``` script, [backend-flask/bin/ddb/schema-load](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ddb/schema-load) .
- This script creates a DynamoDB table called 'cruddur-messages'.
- Change the permissions of the schema-load bash script file by running, in the terminal:
```chmod u+x bin/ddb/schema-load```
- Ensure that dynamodb local is running by making sure it is not commented out in the Docker-compose file then start up Docker-compose again. 
- Run in the terminal ```./bin/ddb/schema-load```

**Step 7 -  Creating List-tables Bash Script**
- In the ddb folder, create a new file named ```list-tables```, [backend-flask/bin/ddb/list-tables](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ddb/list-tables)
- Which lists our tables i.e makes sure that the table(s) we created in step 6 actually exists in AWS(we can also confime this from the AWS CLI).
- Change the permissions of the list-tables bash script file, then running in the terminal:
```
chmod u+x bin/ddb/list-tables
./bin/ddb/list-tables
``` 

**Step 8 -  Creating Drop-tables Bash Script**
-  In the ddb folder, create a new file named ``drop``, [backend-flask/bin/ddb/drop](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ddb/drop) to drop our table(s).
- Change the permissions of the list-tables bash script file by running, in the terminal:
```
chmod u+x bin/ddb/drop-tables
./bin/ddb/drop-tables
```

**Step 9 -  Creating Seed Bash Script**
-  In the ddb folder, create a new file named ``seed`` to seed/put data into our table(s), [backend-flask/bin/ddb/seed](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ddb/seed).
-  From the code, we can see that the access patterns listed above have been implemented and so has the conversation.
-  It also utilizes the access patterns to assign the appropriate user name to the ongoing conversation.
-  If yopu decide to use this code, please make sure to change the appropriate values to your own i.e name.

**Step 10 -  Creating Scan Script**
- In the ddb folder, create a new file named ``scan`` to make sure that seeding our  DynamoDB table(s) actually happened , [backend-flask/bin/ddb/scan](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ddb/scan)

**Step 11 - Creating a patterns folder in ddb**
-  In the ddb folder, create a new folder named ```patterns```.
-  In the ddb/patterns folder, create a new file named ```get-conversations```. The script [backend-flask/bin/ddb/patterns/get-conversations](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ddb/patterns/get-conversations) will query the table and then will get our conversations that we had with the uuid, ```message_group_uuid = "5ae290ed-55d1-47a0-bc6d-fe2bc2700399"``` for a particular time period and will then print the consumed capacity.
-  In the ddb/patterns folder, create a new file named ```list-conversations```.
The script [backend-flask/bin/ddb/patterns/list-conversations](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ddb/patterns/list-conversations). This will list all the conversations that a user with a particular user uuid has had by querying the table and print the items returned by the query.
- Change the permissions of the scan bash script file by running, in the terminal:
```
chmod u+x bin/ddb/patterns/get-conversations
./bin/ddb/patterns/get-conversations
```

- To get the value of 
"my_user_uuid = "1506fa16-d775-4808-9f46-456661029af2", in the terminal, make sure that we are in backend-flask folder and run ```./bin/db-connect``` , then in the cruddur prompt, run :
```
SELECT uuid, handle from users;
```
***(this value will always have to be updated whenever we seed the database because the uuid is ever-changing and the )***
- Change the permissions of the scan bash script file by running, in the terminal:
```
chmod u+x bin/ddb/patterns/list-conversations
./bin/ddb/patterns/list-conversations
```

### Update our backend app to use the production DynamoDB and to implement the conversations
**Step 12 - Creating **
- Paste the following code in create ```backend-flask/lib/ddb.py```
```
# when we want to return a a single value
  def query_value(self,sql,params={}):
    self.print_sql('value',sql,params)

    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql,params)
        json = cur.fetchone()
        return json[0]

```

- In gitpod.yml add in:
```
name: flask
command: |
  cd backend-flask
  pip install -r requirements.txt
```

- In the ```bin/ddb/seed file```, add/replace the last line with:
```psql $NO_DB_CONNECTION_URL -c "drop database IF EXISTS cruddur;"```

- In the terminal, run ```pip install -r requirements.txt``` then run Docker compose up in the terminal.
- Open our front-end application in a new tab and try to sign in.
- Switch to the messages tab.
- Create a DynamoDB object by creating a ddb.py file in the backend-flask/lib folder, as [backend-flask/lib/ddb.py](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/lib/ddb.py) . 
- 
- In the list-conversation file, paste in  ```'ScanIndexForward': False,```:
- Change into the ```backend-flask directory``` and in the terminal paste in line 2:
```
aws cognito-idp list-users --user-pool-id-(paste in user id here)
```

- We need to set the cognito user pool environment, so we will first retrieve the cognito user pool id for the cruddur-user-pool and then set it as an environment variable by entering in the terminal:
```
export AWS_COGNITO_USER_POOL_ID="valuevaluevalue"
gp env AWS_COGNITO_USER_POOL_ID="valuevaluevalue"
env | grep AWS_COGNITO
```

- We will then update it in the backend by editing the Docker-compose file(to hard code it into the backend file):
```
AWS_COGNITO_USER_POOL_ID: "${AWS_COGNITO_USER_POOL_ID}"
```

**Step 13 - Updating user authentication in our frontend **
- We will create a new file in the frontend-react-js callled CheckAuth.js which we will import in other files that will allow us to authentoicate our users.
- The file [frontend-react-js/src/lib/CheckAuth.js](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/src/lib/CheckAuth.js) will be added to:
1. [frontend-react-js/src/pages/MessageGroupsPage.js](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/src/pages/MessageGroupsPage.js)
2. [frontend-react-js/src/components/MessageForm.js](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/src/components/MessageForm.js)
3. [frontend-react-js/src/pages/HomeFeedPage.js](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/src/pages/HomeFeedPage.js)
4. [frontend-react-js/src/pages/MessageGroupPage.js](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/src/pages/MessageGroupPage.js)
5. 

**Step 14 - Create message **
- Since we can now authenticate users, we can now implement sending messages. As we had earlier dicussed in the Data modelling video, our messages are created in/with DynamoDB thus we will be utilizing the ```ddb.py``` file we created above.

### Implementing DynamoDB Stream with AWS Lambda
**Step 15 - Creating our DynamoDB table in production**
- To ensure that our table is now created in AWS, we will now comment  out ```AWS_ENDPOINT_URL``` in docker-compose.yml, then run compose up and run ./bin/db/setup to restart our Postgres table. 
- In  ```./bin/ddb/schema-load``` we will add in a Global Secondary Index (GSI) and then we will run our DynamoDB in production so that we can also create in AWS. Run ```./bin/ddb/schema-load prod```.
- Go to our AWS console then in DynamoDB > Tables > cruddur-messages > Turn on DynamoDB stream, choose "new image"
- On AWS in the VPC console, create an endpoint named cruddur-ddb, choose services with DynamoDB, and select the default VPC and route table
- We can now create a function, therefore in AWS Lambda console, create a new function named ```cruddur-messaging-stream``` and enable VPC in its advanced settings; then paste in the code [aws/lambdas/cruddur-messaging-stream.py](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/aws/lambdas/cruddur_messaging_stream.py) and deploy the code as a function.
- We can now add an IAM role and attach a permission of ```AWSLambdaInvocation-DynamoDB``` 


### Security best practises for DynamoDB
**Types of Access to DynamoDB**
- Using Internet Gateway.
- Using VPC/Gateway Endpoints
- DynamoDB Accelerator(DAX)
- Cross Account

**Security best Practises - AWS**
Amazon Dynamodb is part of an  account NOT a virtual Network
- Use VPC endpoints: Use Amazon VPC to create a private network from our application or Lambda to a DynamoDB . This prevents unauthorized access to the instance from the public internet.
- Data Security & Compliance: Compliance standard should be followed for the business requirements.
- Amazon DynamoDB should only be in the AWS region that we are legally allowed to hold user data in.
- Amazon organizations SCP - to manage DynamoDB Table deletion, DynbamoDB creation, region lock.
- AWS CloudTrail is enabled & monitored to trigger appropriate alerts on malicious DynamoDB behaviour by an identity in AWS.
- AWS Config rules is enabled in the account and region of DynamoDB.

**Security best Practises - Application**
AWS recommends using Client side encryption when storing sensitive information. But dynamoDB should not be used to store sensitive information, RDS databases should be used instead to store sensitive information for long periods.
- DynamoDB to use appropriate Authentication - Use IAM Roles/ AWS Cognito Identity Pool (Avoid IAM Users/Groups).
- DynamoDB User Lifecycle Management - Create, Modify, Delete Users.
- AWS IAM roles instead of individual users to access and manage DynamoDB.
- DAX Service9IAM) Role to have Read Only Access to DynamoDB.
- Not have DynamoDB be accessed from the internet(use VPC endpoints instead).
- Site-to-Site VPN or Direct Connect for Onpremise and DynamoDB Access.
- Client side encryption is recommended by Amazon for DynamoDB.

# Errors I have encountered so far and how i resolved them #
## 1. While running ./bin/cognito/list-users ## 
```Traceback (most recent call last):
  File "/workspace/aws-bootcamp-cruddur-2023/backend-flask/./bin/cognito/list-users", line 26, in <module>
    dict_users[handle['Value']] = sub['Value']
               ~~~~~~^^^^^^^^^
TypeError: 'NoneType' object is not subscriptable
```

2. While running ./bin/db/update_cognito_user_ids 
```Traceback (most recent call last):
  File "/workspace/aws-bootcamp-cruddur-2023/backend-flask/./bin/cognito/list-users", line 26, in <module>
    dict_users[handle['Value']] = sub['Value']
               ~~~~~~^^^^^^^^^
TypeError: 'NoneType' object is not subscriptable
```

SOLUTION
3. While trying to connect to my postgres database, the records/users had been added twice from my cognito user pool id and when i tried dropping the Cruudur postgres datase database I woul encounter this error
```
== db-drop
ERROR:  database "cruddur" is being accessed by other users
DETAIL:  There are 4 other sessions using the database.
```

From the discord channel, a tip dropped there suggested using this command
```
REVOKE CONNECT ON DATABASE cruddur FROM public;
ALTER DATABASE cruddur allow_connections = off;
SELECT pg_terminate_backend(pg_stat_activity.pid
) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'cruddur'; DROP DATABASE cruddur;
```
I connected to the database by:
```./bin/db/connect```
then once in the cruddur database, run the command above.
When i tried running ```./bin/db/drop``` once again it worked.
Thus i ran, ```./bin/db/setup```, then ./bin/cognito/list-users

## 2. Messages for Londo will not update ##
- Incase we try updating messages for Londo, then we can manually update a dummy Cognito ID for him
```
./bin/db/connect
UPDATE public.users SET cognito_user_id = 'f73f4b05-a59e-468b-8a29-a1c39e7a2222' WHERE users.handle = 'bayko';
\q
```

## 3. Getting -ve time values on our messages ##
While the messages would show in our application, they would show negative times thus meaning when we posted new messages they wouldn't be displayed on our timeline.
A helpful bootcamper suggested editing this line in ```backend-flask/bin/ddb/seed```
```
change this line 
  created_at = (now + timedelta(minutes=i)).isoformat()
to
  created_at = (now + timedelta(hours=-3) + timedelta(minutes=i)).isoformat()
```
- Then drop the database and recreate it then seed it using these steps:
```
./bin/ddb/drop cruddur-messages 
./bin/ddb/load-schema 
./bin/ddb/seed
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

## Next Steps - Additional Homework Challenges
1. Add a caching layer using Momento Severless Cache
What are primary keys?
What are partition keys?
What are base tables?
What is a GSI?-Global Secondary Index
What are LSI? Local Secondary Indexes
GSI vs LSI?
4kb in read 1kb in writes.


**RESOURCES**
1. [NoSQL DynamoDB Workbench](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/workbench.html)
2. [AWS SDK Boto3 Python DynamoDB Documentation]([https://boto3.amazonaws.com/v1/documentation/api/latest/guide/dynamodb.html](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/dynamodb/client/create_table.html))
3. PartQL
4. No-SQL Workbench
