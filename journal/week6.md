# Week 6 — Deploying Containers with ECS and Fargate

What are Health checks?
What is AWS ECR and its benefits?
What is AWS ECS, Fargate and what are its benefits?
What is AWS Route 53?

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

## Tasks
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
A repository is where you store your Docker or Open Container Initiative (OCI) images in Amazon ECR. Each time you push or pull an image from Amazon ECR, you specify the repository and the registry location which informs where to push the image to or where to pull it from.
- We will be pulling a Python image from Dockerhub and push it to a hosted version of ECR. We do this so that different versions of python do not interfere with our application.
- In AWS ECR, we can create a private repository uasing the following steps:
- AMAZON ecr > Create Repository > In General settings, in Visibility settings choose ```Private``` > Enter your preferred ```Repository name``` > Enable ```Tag immutability``` (prevents image tags from being overwritten by subsequent image pushes using the same tag) > Create Repository.
- Now let's do this via the AWS CLI in Gitpod. 

#### Create a Private Repository via the CLI
- To create a repository ```cruddur-python``` in ECR:
```
aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
  ```
#### Log in to ECR via CLI
 - Login to our ECR repo we created abovefor the Python base-image so that we can push images to the repository.
 
 ```
 aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
 ```
#### Set URL
- We will now set path for the address that will map to our ECR IP
```
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"
echo $ECR_PYTHON_URL
```

# Push our container images to ECR
### Step 2: Push a Python Image to the container we created above for the backend 
#### Pull Python Image from Dockerhub
- Pull the python image from Dockerhub to our local environment , then confirm that its downloaded/pulled
```
docker pull python:3.10-slim-buster 
docker images
```
#### Tag the Python image pulled above
```docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster```
#### Push the Python image to ECR
```docker push $ECR_PYTHON_URL:3.10-slim-buster```
#### Prepare our Flask App to use the python image from ECR
- We will copy URI from the ECR python image into our Dockerfile so that we now use the image stored in ECR i.e the first line of the Dockerfile:
```nbjhg```
#### Docker compose up
- Run docker compose up for the backend and the Database.
- To test that the application is now running, launch the backend service then paste in ```/api/health-check```, should return : 
``` { success: True } ```

### Step 3: Push a Python Image to the conatiner we created above for Flask
- Create Repo
```aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```

#### Set URL
```
export ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"
echo $ECR_BACKEND_FLASK_URL
```

#### Build image
 ```
 docker build -t backend-flask .
 ```
 
#### Tag Image
 ```
 docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest
 ```

#### Push image
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
***{The CruddurServiceExecutionPolicy must also have the following rules which can be created inline via the console or added as lined to the JSON policy document:
 ecr:GetAuthorizationToken,
 ecr:BatchCheckLayerAvailability,
 ecr:GetDownloadUrlForLayer,
 ecr:BatchGetImage,
 logs:CreateLogStream,
 logs:PutLogEvents
 }***

### Step 7: Create and attach a CloudWatchFullAccess policy 
- We will add another policy, ```CloudWatchFullAccessPolicy``` [aws/policies/cloudwatch-fullaccess-policy.json]() and attach it to the ```CruddurServiceExecutionRole``` and run the following in the terminal to create the policy and attach it to the role simultaneously:
```
aws iam put-role-policy \
  --policy-name CloudWatchFullAccessPolicy \
  --role-name CruddurServiceExecutionRole \
  --policy-document file://aws/policies/cloudwatch-fullaccess-policy.json
```
OR you can also do this(if you dont want to create the JSON policy document THEN attach it to the file).
```
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurServiceExecutionRole
```

### Step 8: Create a CruddurTaskRole and attach a Sessions Manager policy 
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
- Attach an existing AWS policy, ```CloudWatch FullAccess``` to the CruddurTaskRole via the CLI.
```
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurTaskRole
```

### Step 10: Create a write policy for the XRAY Daemon to the SSM Task Role
- Attach an existing AWS policy, ```AWSXRayDaemonWriteAccess``` to the CruddurTaskRole via the CLI.
```
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess --role-name CruddurTaskRole
```

### Step 11: Create a task definition file(this defines how we provision an application)
- A task definition is like a blueprint for your application. Each time you launch a task in Amazon ECS, you specify a task definition. The service then knows which Docker image to use for containers, how many containers to use in the task, and the resource allocation for each container.
- Create a Task definition json file in , [aws/task-definitions/backend-flask.json]()
***{Make sure to change the values in the file as per your account, check from Docker compose file, and the image we created in the ECR repo for the backend}***

- Register the Task definition for the backend-flask
```
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
```
- Check the Task definitions in ```AWS ECS > Task definitions``` to ensure its been created in the console(REVISIONS will always update when we change the file therefore always make sure to push changes that you make in the file to ECS to use the newer file)

# Create a Load Balancer, VPCs and Security groups for the Front-end and Baceknd services 
### Step 12: Prepare our backend container to be deployed to Fargate
#### Creating a default VPC 
(All these commands should be run in workspace/aws-bootcamp-cruddur)
- Create a default VPC via the terminal/CLI, i.e find the default VPC and return its VPC ID if True.
```
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```

#### Creating a Security Group
- Create a security group via the terminal/CLI
```
export CRUD_SERVICE_SG=$(aws ec2 create-security-group \
  --group-name "crud-srv-sg" \
  --description "Security group for Cruddur services on ECS" \
  --vpc-id $DEFAULT_VPC_ID \
  --query "GroupId" --output text)
echo $CRUD_SERVICE_SG
```

#### Allow HTTP requests
- Allow ingress of HTTP requests using port 80, on the CRUD_SERVICE_SG security group we created above,paste into the terminal:
```
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_SERVICE_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

#### Install Sessions Manager plugin for Linux and access the ECS cluster via the CLI 
- In the terminal, paste in and enter:
```
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
```

- Then:
```sudo dpkg -i session-manager-plugin.deb```
- To verify that it was successfully installed, type:
``` session-manager-plugin```

- Then in ```gitpod.yml``` add the follwoing line to make sure that its set up installed everytime we launch the environment:
```
```

#### Create a Load Balancer via the console
- Go to EC2 console > Click on ```Load Balancers``` > From the console choose ```Aplication Load balancer```

### Step 13: Prepare our Frontend Container to be deployed to Fargate


# Launch our ECS Fargate container via the CLI
### Step 14: Options for creating our ECS cluster for the backend-flask
#### Option 1: Create our ECS cluster via the console 
- Choose clusters > Choose the ```cruddur``` cluster > Choose ```create``` > Choose Launch type ```FARGATE``` > Choose the platform version as ```LATEST``` > Choose the Deployment configuration ```Service``` >  Choose Family ```backend-flask``` > Revision ```2(LATEST) ``` > Choose Service type ```Replica``` >
Desired tasks ```1``` 

#### Option 2: Create our ECS cluster via the CLI 
- Create a new file in ```aws/json``` use the following [aws/json/service-backend-flask]()
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

- Get the ```securityGroup IDs``` and the ```subnet IDs``` from the ***AWS EC2 > Network and Security > Security Groups*** console and paste into the code above or use the CLI
- To get VPC ID
```
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```
-  To fill in the ***subnet IDs*** above run the following in the CLI and copy the values(optionally you can look in the console)
```
export DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets  \
 --filters Name=vpc-id,Values=$DEFAULT_VPC_ID \
 --query 'Subnets[*].SubnetId' \
 --output json | jq -r 'join(",")')
echo $DEFAULT_SUBNET_IDS
```

- In the terminal,paste and run:
```
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
```

#### Create a Sessions Manager script that will allow 
- We can access the ECS cluster container using the bash terminal to view the status of the cluster tasks and to check to make sure that the container is healthy.:
```
aws ecs execute-command \
  --region $AWS_REGION \
  --cluster cruddur \
  --task <task ARN ID> \
  --container backend-flask \
  --command "/bin/bash" \
  --interactive
```

- Alternatively, we can create a Sessions Manager script that will allow us to connect to our backend bash using a script .
- Create a new file ```connect-to-backend-service``` in [backend-react/bin/ecs/connect-to-backend-service]()
- Change the permissions on the file in the terminal :
```
chmod u+x ./bin/ecs/connect-to-backend-service
```

- Execute the command in the terminal to connect to the container:
```
./bin/ecs/connect-to-backend-service <task ARN ID> backend-flask
```

- 

#### Create an ECS cluster with service connect from the CLI
- create a new file in ```aws/json``` use the following [aws/json/service-backend-flask.json]()

### Step 15: Create our ECS cluster for the backend-flask
#### Build Frontend image locally 
- Switch to ```frontend-react``` and paste in the following code:
```
docker build \
--build-arg REACT_APP_BACKEND_URL="https://4567-$GITPOD_WORKSPACE_ID.$GITPOD_WORKSPACE_CLUSTER_HOST" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="us-east-hgghnmjdgs" \
--build-arg REACT_APP_CLIENT_ID="jhgfjgdfjhdgfvdhmnvbfg" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```
- Ispect the container using
``` docker inspect <container id>```

#### Connect to the Frontend ECS cluster container
- Create a new file, ```frontend-react-js``` in ```backend-flask/bin/ecs```, [backend-flask/bin/ecs/connect-to-frontend-react-js]().
- In the terminal, run ```chmod u+x ./bin/ecs/connect-to-frontend-react-js```.
- Then to connect run ```./bin/ecs/connect-to-service <task-id/arn number of the service ```
- Test curl localhost:3000

#### Create a task definition for the Front-end container
- To create a task in the container, we will:
- Create a new file, ```frontend-react-js.json``` in ``aws-task-definitions```, [backend-flask/bin/ecs/frontend-react-js.json]().
- In the terminal, run ```chmod u+x ./bin/ecs/frontend-react-js.json```.
- In task-defintion, make sure to add in the ```health-check``` in the json file, at the container level:
```
```

#### Register Task definition for the Front-end container

```
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/frontend-react-js.json
```

#### Create our ECS cluster via the console for the Frontend-react
- Paste in the code into the terminal to provision a container for the front end, without a Load Balancer.
```
aws ecs create-service --cli-input-json file://aws/json/service-frontend-react-js.json
```
- Login AWS ECS clusters to make sure that its been launched.

#### Create a Security group that will allow requests to the Frontend container form the Load Balancer
- In the AWS ECS console, in the front-end-react Networking tab, ```Security Groups``` > Choose ```Edit inbound rule``` > Add in a port range ```3000``` for the frontend Load Balancer > Add in a port range ```4567``` for the backend Load Balancer

#### Run the Frontend image
- We will run the container before we can test it.
``` docker run --rm -p 3000:3000 -it frontend-react-js ```

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

# Create a custom domain with SSL and Route53
### Step : Create a Hosted zone in Route 53
- In the AWS console, go to Route 53 > Go to ***Hosted zones*** > Select ***Create a hosted zone*** > In ***Hosted zone configuration/Domain name*** add in cruddur.com > In ***Type*** choose Public hosted zone then choose ***Create hosted zone***
- Open the ```cruddur.com``` page to view the nameservers.
- If you had bought a domain from a vendor eg GoDaddy, open their name servers page and paste in the values of the nameservers to your domain from Godaddy.

### Create a record
- In the AWS console, go to Route 53 > Go to the cruddur.com host zone and click ***Create record*** > In Quick create record, select ***A record*** > Choose ***alias*** and Route traffic to the Application Load Balancer we created earlier > Select region wehere we created the LB


### Step : Create an SSL certificate with AWS Certificate Manager
- In the AWS console, go to AWS Certificate Manager > Choose ***Request certificate*** > Choose ***Request a public certificate*** > Choose Next then in Request Public certificate page, Add in your ***Domain name*** (that you created in the step above) > In Validation method, choose ***DNS validation*** > In ***Key algorithm*** leave it as the default > Choose ***Request***.
- While the certificate in creating, we can click into it and choose ***Create DNS records in Amazon Route 53*** 

## ECS Security best practises
### Business Use cases of of AWS ECS
1. Deploying an application to a container using AWS ECS.

### Security challenges with AWS Fargate
1. Infrastructure is AWS managed thus no visilibility of infrastructure.
2. Ephemeral resources make it hard to do triage/forensics for detectewd threats.
3. No file/network monitoring.
4. Cannot run traditional security agents.
5. User can run unverified container images.
6.  Containers can run as root and with elevated priviledges(when working with Linux systems, this can be very dangerous as root priviledges give users unlimited access to your entire system thus they can delete important running systems).

### Amazon ECS - Security Best practises
1. 

## Additional homework challenges
1. Create a hosted zone with the AWS CLI
2. Make a b ash script that automatically gives the VPC ID and SuBNET IDS.


## Aditional links 
1. [Security in AWS ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html)
