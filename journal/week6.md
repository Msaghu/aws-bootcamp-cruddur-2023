# Week 6 — Deploying Containers with ECS and Fargate

What are Health checks?

### AWS ECS Launch types 
1. Use Elastic Load Balancers(ELBs) + Auto Scaling groups
2. Amazon ECS architecture - Use Elastic Load Balancers(ELBs) + Amazon ECS Cluster
3. Using AWS Fargate - Elastic Load Balancers(ELBs) + Amazon ECS Cluster

# Architecture Description
- A custom VPC with 6 public subnets that route on to the internet, this week's AWS resources attempt to use this custom VPC.
- An ECS Fargate cluster running a single service for the backend flask application
- The backend flask application container image is hosted in a private ECR repo
- The target services are using ECS Connect
- An internet facing application Elastic Load Balancer is serving the backend flask application on a subnet. The backend flask application runs on port 4567

# Tasks
1. Create an Elastic Container Repository (ECR) 
2. Push our container images to ECR
3. Write an ECS Task Definition file for Fargate
4. Launch our Fargate services via CLI
5. Test that our services individually work
6. Play around with Fargate desired capacity
7. How to push new updates to your code update Fargate running tasks
8. Test that we have a Cross-origin Resource Sharing (CORS) issue

# Create an Elastic Container Repository (ECR) 
### Step 1: Create an Elastic Container Repository(ECR) via the CLI
- We will be pulling a Python image from Dockerhub and push it to a hosted version of ECR. We do this so that different versions of python do not interfere with our application.
- In AWS ECR, we can create a private repository uasing the following steps:
- AMAZON ecr > Create Repository > In General settings, in Visibility settings choose ```Private``` > Enter your preferred ```Repository name``` > Enable ```Tag immutability``` (prevents image tags from being overwritten by subsequent image pushes using the same tag) > Create Repository.
- Now let's do this via the AWS CLI in Gitpod. 

##### Create a Private Repository via the CLI
- To create a repository ```cruddur-python``` in ECR:
```
aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
  ```
##### Log in to ECR via CLI
 - Login to our ECR repo we created abovefor the Python base-image so that we can push images to the repository.
 
 ```
 aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
 ```
##### Set URL
- We will now set path for the address that will map to our ECR IP
```
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"
echo $ECR_PYTHON_URL
```

# Push our container images to ECR
### Step 2: Push a Python Image to the container we created above for the backend 
##### Pull Python Image from Dockerhub
- Pull the python image from Dockerhub to our local environment , then confrim that its downloaded/pulled
```
docker pull python:3.10-slim-buster 
docker images
```
##### Tag the Python image pulled above
```docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster```
##### Push the Python image to ECR
```docker push $ECR_PYTHON_URL:3.10-slim-buster```
##### Prepare our Flask App to use the python image from ECR
- We will copy URI from the ECR python image into our Dockerfile so that we now use the image stored in ECR i.e the first line of the Dockerfile:
```nbjhg```
##### Docker compose up
- Run docker compose up for the backend and the Database.
- To test that the application is now running, launch the backend service then paste in ```/api/health-check```, should return : 
``` { success: True } ```

### Step 3: Push a Python Image to the conatiner we created above for Flask
- Create Repo
```aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```

##### Set URL
```
export ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"
echo $ECR_BACKEND_FLASK_URL
```
  ##### Build image
 ```
 docker build -t backend-flask .
 ```
  ##### Tag Image
 ```
 docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest
 ```
  ##### Push image
 ```
 docker push $ECR_BACKEND_FLASK_URL:latest
 ```
### Step 4: Push a React Image to the container we created above for the frontend


# Write an ECS Task Definition file for Fargate
### Step 5: Create Task and Execution Roles for Task definition
- Create Parameter Store from Systems Manager to create parameters that will enable us to conceal sensitive information
- We will ensure that the items listed below have been set as environment variabels(i.e run env |  grep AWS_JHGGK<JK) to make sure that they have been set in your system.
- Then run the following commands in the terminal.
```
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/CONNECTION_URL" --value $PROD_CONNECTION_URL
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```

- Go to ```AWS Systems Manager > Parameter Store``` to make sure that the values were correctly set.

### Step 6: Create an ECS role and attach a policy that will allow ECS to execute tasks
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

### Step 7: Create a CloudWatchFullAccess policy 
- We will add another policy, ```CloudWatchFullAccessPolicy``` [aws/policies/cloudwatch-fullaccess-policy.json]() and attach it to the ```CruddurServiceExecutionRole``` and run the following in the terminal to create the policy and attach it to the role simultaneously:
```
aws iam put-role-policy \
  --policy-name CloudWatchFullAccessPolicy \
  --role-name CruddurServiceExecutionRole \
  --policy-document file://aws/policies/cloudwatch-fullaccess-policy.json
```
OR you can also do this
```
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurServiceExecutionRole
```
### Step 8: Create a Sessions Manager role and attach a policy 
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

### Step 9: Create CloudWatch FullAccess policies to the SSM Task Role
- Attach an existing AWS policy, ```CloudWatch FullAccess``` via the CLI.
```
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurTaskRole
```

### Step 10: Create a write policy for the XRAY Daemon to the SSM Task Role
- Attach an existing AWS policy, ```CloudWatch FullAccess``` via the CLI.
```
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess --role-name CruddurTaskRole
```

### Step 11: Create a task definition file(this defines how we provision an application)
- Create a Task definition json file in , [aws/task-definitions/backend-flask.json]()
{Make sure to change the values in the file as per your account}

- Register the Task definition for the backend-flask
```
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
```
- Check the Task definitions in ```AWS ECS > Task definitions``` to ensure its been created

# Launch our Fargate services via CLI
### Step 12: Prepare containers to be deployed to Fargate
### Step 13: Create our ECS cluster 
##### Create our ECS cluster via the console (minute 1:32:16)
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

## ECS Security best practises
### Business Use cases of of AWS ECS
1. Deploying an application to a container using AWS ECS.



# Test that our services work individually
- To ensure the health of our Cruddur application, we would need to deploy health checks at various instances to ensure that it is running optimally.
- The various stages are:
1. At the Load Balancer level
2. At the container level
3. Of the RDS instance

{Before starting these stepos, make sure to start your RDS instance in AWS}

### Step 1: Perform health checks on our RDS instance
- In ```backend-flask/db``` create a new file ```/test``` [backend-flask/db/test](_)
- This will tell us if health check was successful on our local postgres DB.
- Since we are now running in production, we will add production to the test script.
- This will connect us to our container.
- Check { env | grep CONNECTION }

### Step 2: Perform health checks on our Flask App
- In ```backend-flask/app.py``` add in new code [backend-flask/app.py](_)
- In ```backend-flask/bin``` create a new file ```/flask```[backend-flask/bin/flask](_)

### Step 3: Create a new CloudWatch log group



### Security challenges with AWS Fargate
1. Infrastructure is AWS managed thus no visilibility of infrastructure.
2. Ephemeral resources make it hard to do triage/forensics for detectewd threats.
3. No file/network monitoring.
4. Cannot run traditional security agents.
5. User can run unverified container images.
6.  Containers can run as root and with elevated priviledges(when working with Linux systems, this can be very dangerous as root priviledges give users unlimited access to your entire system thus they can delete important running systems).

### Amazon ECS - Security Best practises
1. 

