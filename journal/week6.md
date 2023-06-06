# Week 6 — Deploying Containers with ECS and Fargate

What are Health checks?

# Perfoming Health checks on our Cruddur application
- To ensure the health of our Cruddur application, we would need to deploy health checks at various instances to ensure that it is running optimally.
- The various stages are:
1. At the Load Balancer level
2. At the container level
3. Of the RDS instance

{Before starting these stepos, make sure to start your RDS instance in AWS}

## Perform health checks on our RDS instance
- In ```backend-flask/db``` create a new file ```/test``` [backend-flask/db/test](_)
- This will tell us if health check was successful on our local postgres DB.
- Since we are now running in production, we will add production to the test script.
- This will connect us to our container.
- 
| un env }

## Perform health checks on our Flask App

# Prepare containers to be deployed to Fargate

## For Base image python
Create repository in ECR
```
aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
  ```
 
 ## Log in to ECR 
 ```
 aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
 ```
 
 ## Set URL
 ```
 export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"
echo $ECR_PYTHON_URL
```

## Pull Python Image from Dockerhub
```
docker pull python:3.10-slim-buster
```

## Tag the Python image pulled above
```docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster```

## Push the Python image to ECR
```docker push $ECR_PYTHON_URL:3.10-slim-buster```

## Prepare our Flask App to use the python image from ECR
Copy URI from ECR python

### Docker compose up
Run docker compose up for select services

## For Flask
Create Repo
```aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```

Set URL
```
export ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"
echo $ECR_BACKEND_FLASK_URL
```
 
 Build image
 ```
 docker build -t backend-flask .
 ```
 
 Tag Image
 ```
 docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest
 ```
 
 Push image
 ```
 docker push $ECR_BACKEND_FLASK_URL:latest
 ```

Register Task Definitions
- Create Parameter Store from Syetms manager to create parameters that will enable us to conceal sensitive information
- We will ensure that the items listed below have been set as environment variabels(i.r ruun env |  grep AWS_JHGGK<JK) to make sure that they have been set in your system.
- Then run the following commands in the terminal.
```
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/CONNECTION_URL" --value $PROD_CONNECTION_URL
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```

- Check that the values have been set in ```AWS Systems Manger > Parameter Store``` to make sure that the values were correctly set.

Create an ECS role and attach a policy that will allow ECS to execute tasks
- In policies, create a service execution role, ```CruddurServiceExecutionRole``` [aws/policies/service-assume-role-execution-policy.json]() and run the following in the terminal to create the role:
```
aws iam create-role \    
--role-name CruddurServiceExecutionRole  \   
--assume-role-policy-document file://aws/policies/service-assume-role-execution-policy.json
```
- Confirm that the role was created in the AWS IAM console.
- We will now create a policy, ```CruddurServiceExecutionPolicy``` [aws/policies/service-execution-policy.json]() and attach it to the ```CruddurServiceExecutionRole``` and run the following in the terminal to create the policy and attach it to the role simultaneously:
```
aws iam put-role-policy \
  --policy-name CruddurServiceExecutionPolicy \
  --role-name CruddurServiceExecutionRole \
  --policy-document file://aws/policies/service-execution-policy.json
```
- We will add another policy, ```CloudWatchFullAccessPolicy``` [aws/policies/cloudwatch-fullaccess-policy.json]() and attach it to the ```CruddurServiceExecutionRole``` and run the following in the terminal to create the policy and attach it to the role simultaneously:
```
aws iam put-role-policy \
  --policy-name CloudWatchFullAccessPolicy \
  --role-name CruddurServiceExecutionRole \
  --policy-document file://aws/policies/cloudwatch-fullaccess-policy.json
```

Create a Sessions Manager role and attach a policy 
- In policies, create a task role, ```CruddurTaskRole``` [aws/policies/service-assume-role-ssm-task-policy.json]() and run the following in the terminal to create the role:
```
aws iam create-role \
    --role-name CruddurTaskRole \
    --assume-role-policy-document file://aws/policies/service-assume-role-ssm-task-policy.json
```
- Confirm that the role was created in the AWS IAM console.
- We will now create a policy, ```SSMAccessPolicy``` [aws/policies/ssm-task-policy.json]() and attach it to the ```CruddurTaskRole``` and run the following in the terminal to create the policy and attch it to the role simultaneously:
```
aws iam put-role-policy \
  --policy-name SSMAccessPolicy \
  --role-name CruddurTaskRole \
  --policy-document file://aws/policies/ssm-task-policy..json
```

Create CloudWatch FullAccess policies to the SSM Task Role
```
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurTaskRole
```

Create a write policy for the XRAY Daemon to the SSM Task Role
```
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess --role-name CruddurTaskRole
```

Create a task definition file(this defines how we provision an application)
- Create a Task definition json file in , [aws/task-definitions/backend-flask.json]()
{Make sure to change the values in the file as per your account}

- Register the Task definition for the backend-flask
```
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
```
- Check the Task definitions in ```AWS ECS > Task definitions``` to ensure its been created

# Create our ECS cluster 
## Create our ECS cluster via the console (minute 1:32:16)
- Create a default VPC via the terminal
```
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```

- Create a security group via the CLI
```
export CRUD_SERVICE_SG=$(aws ec2 create-security-group \
  --group-name "crud-srv-sg" \
  --description "Security group for Cruddur services on ECS" \
  --vpc-id $DEFAULT_VPC_ID \
  --query "GroupId" --output text)
echo $CRUD_SERVICE_SG
```

- Choose clusters > Choose the ```cruddur``` cluster > Choose ```create``` > Choose Launch type ```FARGATE``` > Choose the platform version as ```LATEST``` > Choose the Deployment configuration ```Service``` >  Choose Family ```backend-flask``` > Revision ```2(LATEST) ``` > Choose Service type ```Replica``` >
Desired tasks ```1``` 

- Insatll sessions manager plugin for Linux
```
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
```

- Then
```sudo dpkg -i session-manager-plugin.deb```
- To verify that it was successfully installed
``` session-manager-plugin```
- 
- Access the ECS bash to view the status of the cluster 
```
aws ecs execute-command \
  --region $AWS_REGION \
  --cluster cruddur \
  --task <task ARN> \
  --conatiner backend-flask \
  --command "/bin/bash" \
  --interactive
```

## Create our ECS cluster via the CLI 
- OR the default VPC
```
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```

-  to fill in the subnet section below run the following in the CLI and copy the values(optionally you can look in the console)
```
export DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets  \
 --filters Name=vpc-id,Values=$DEFAULT_VPC_ID \
 --query 'Subnets[*].SubnetId' \
 --output json | jq -r 'join(",")')
echo $DEFAULT_SUBNET_IDS
```


- create a new file in ```aws/json``` use the following [aws/json/service-backend-flask]()
```
{
    "cluster": "cruddur",
    "launchType": "FARGATE",
    "desiredCount": 1,
    "enableECSManagedTags": true,
    "enableExecuteCommand": true,
    "networkConfiguration": {
      "awsvpcConfiguration": {
        "assignPublicIp": "ENABLED",
        "securityGroups": [
          "sg-0f40b229443a0484b"
        ],
        "subnets": [
          "subnet-094cc4c02ce0ef450",
          "subnet-0d5df2de4f694655b",
          "subnet-0047f95522e4d005b",
          "subnet-0ccf39fa8d7ecea5a",
          "subnet-0c1abd9d2b57576d6",
          "subnet-0e0fcd33f084bf3be"
        ]
      }
    },
    "propagateTags": "SERVICE",
    "serviceName": "backend-flask",
    "taskDefinition": "backend-flask"
  }
  ```

Create an ECS cluster with service connect from the CLI
- create a new file in ```aws/json``` use the following [aws/json/service-backend-flask.json]()

Create a Load Balancer via the console
- Go to EC2 console > Click on ```Load Balancers``` > From the console choose ```Aplication Load balancer```
- 
