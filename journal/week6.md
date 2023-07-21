# Week 6 — Deploying Containers with ECS and Fargate

## Introduction
- Welcome to week 6 and 7 of the Free AWS Bootcamp. This week we will be leveraging the power of AWS to deploy our app as containers, using AWS ECR to register the images and deploying the images as containers using ECS. We will then use AWS route 53 to access the application via the internet. All of this is broken down in the Architecture desription below, but first, lets get into a few basic definitions here.

### Basic Definitions
#### How does the internet work?
- The internet is essentially a type of phonebook in terms of IP addresses.
- Web browsers interact on the internet using IP addresses. However since its virtually impossible to memorise all existing IP addresses of the websites that we like, there needs to be an intermediary that will translate the website names that we provide into an IP address( a format more palatable for a computer). This intermediary is the Domain Name System(DNS).
- So when we search for coolbeans.com:
1. It will first perfor a local lookup
2. Perform a recursive search

##### DNS Records
- This is how the internet does the mapping of a name to an existing IP address. The most common type of DNS record is an:
  
***A Records*** - maps a name to an IPV4 addresses

***AAAA Records***- maps a nme to an IPV6 addresses

***CNAME Records*** - Allows us to route to/map to other domain names as addresses

***MX Records*** - for email addresses , and is set for each mail server by priority.

***NS Records*** - 

##### What is AWS Route 53?
- This a an AWS managed Highly scalable DNS service.
***Fun fact - Route 53 gets its name because port 53 is the protocol for DNS. and DNS uses port 53 both in TCP and UDP.***
- Allows us to use Alias records for AWS resources and we can also purchase domains.

##### What is AWS ECS and what are its benefits?
- Amazon Elastic Container Service (Amazon ECS) is a fully managed container orchestration service that helps you easily deploy, manage, and scale containerized applications. As a fully managed service, Amazon ECS comes with AWS configuration and operational best practices built-in.
- It's integrated with both AWS and third-party tools, such as Amazon Elastic Container Registry and Docker. This integration makes it easier for teams to focus on building the applications, not the environment. You can run and scale your container workloads across AWS Regions in the cloud, and on-premises, without the complexity of managing a control plane.

There are three layers in Amazon ECS:

***Capacity*** - The infrastructure where your containers run

***Controller*** - Deploy and manage your applications that run on the containers

***Provisioning*** - The tools that you can use to interface with the scheduler to deploy and manage your applications and containers

##### Amazon ECS capacity
Amazon ECS capacity is the infrastructure where your containers run. The following is an overview of the capacity options:

***Amazon EC2 instances in the AWS cloud*** - You choose the instance type, the number of instances, and manage the capacity.

***Serverless (AWS Fargate (Fargate)) in the AWS cloud*** - Fargate is a serverless, pay-as-you-go compute engine. With Fargate you don't need to manage servers, handle capacity planning, or isolate container workloads for security.

***On-premises virtual machines (VM) or servers***

##### What is AWS ECR and its benefits?
- A container image holds your application code and all the dependencies that your application code requires to run. Application dependencies include the source code packages that your application code relies on, a language runtime for interpreted languages, and binary packages that your dynamically linked code relies on.
- Container images go through a three-step process.

***Build*** - Gather your application and all its dependencies into one container image.

***Store*** - Upload the container image to a container registry.

***Run*** - Download the container image on some compute, unpack it, and start the application.

##### Why do we make container images complete and static?
- Ideally, a container image is intended to be a complete snapshot of everything that the application requires to function. With a complete container image, you can run an application by downloading one container image from one place. You don't need to download several separate pieces from different locations. Therefore, as a best practice, store all application dependencies as static files inside the container image.

- At the same time, don't dynamically download libraries, dependencies, or critical data during application startup. Instead, include these things as static files in the container image. Later on, if you want to change something in the container image, build a new container image with the changes applied to it.
  
##### What are Load Balancers and Health checks?

##### Networking within AWS

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
9. Adding a CDN layer with AWS CloudFront with a TTL(time to live) and manual invalidation.

# FOR THE BACKEND
# Test that our services work individually
- To ensure the health of our Cruddur application, we would need to deploy health checks at various instances to ensure that it is running optimally.
- The various stages are:
1. At the Load Balancer level
2. At the container level
3. Of the RDS instance

{Before starting these stepos, make sure to start your RDS instance in AWS}

### Step 1: Perform health checks on our RDS instance at the Load Balancer level
#### Create a Load Balancer via the console



### Step 2: Perform health checks on our RDS instance
- In ```backend-flask/bin/db``` create a new file ```/test``` [backend-flask/bin/db/test](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/db/test)
- This will tell us if health check was successful on our local postgres DB.
- Since we are now running in production, we will add production to the test script i.e
```connection_url = os.getenv("PROD_CONNECTION_URL")```.
- Run the script ```bin/rds/update-sg-rule```
- Change the permissions on the script file and connect to our RDS instance:
```
chmod u+x backend-flask/bin/db/test
./backend-flask/bin/db/test
```

- This will connect us to our container.
- Check { env | grep CONNECTION }

### Step 3: Perform health checks on our Flask App
- In ```backend-flask/app.py``` add in new code block to [backend-flask/app.py](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/app.py_) to add a health-check endpoint:
```
@app.route('/api/health-check')
def health_check():
  return {'success': True}, 200
```

- In ```backend-flask/bin``` create a new folder ```/flask```[backend-flask/bin/flask/health-check](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/flask/health-check)
- Change the permissions on the script file and connect to our RDS instance:
```
chmod u+x backend-flask/bin/flask/health-check
./backend-flask/bin/flask/health-check
```

### Step 4: Create a new CloudWatch log group
- In the AWS CLI, paste in the following to create a CloudWatch group with the name ***cruddur*** and the time to store the logs  which will be 1 day:
```
aws logs create-log-group --log-group-name "cruddur"
aws logs put-retention-policy --log-group-name "cruddur" --retention-in-days 1
```

# Create 3 Elastic Container Repositories (ECR) 
### Step 5: Create an Elastic Container Repository(ECR) for Python
#### Option 1: Create a Private Repository Elastic Container Repository(ECR) via the console
- We will be pulling a Python image from Dockerhub and push it to a hosted version of ECR. We do this so that different versions of python do not interfere with our application.
- In AWS ECR, we can create a private repository uasing the following steps:
- AMAZON ecr > Create Repository > In General settings, in Visibility settings choose ```Private``` > Enter your preferred ```Repository name``` > Enable ```Tag immutability``` (prevents image tags from being overwritten by subsequent image pushes using the same tag) > Create Repository.
- Now let's do this via the AWS CLI in Gitpod. 

#### Option 2: Create a Private Repository Elastic Container Repository(ECR) via the  via the CLI
- To create a repository ```cruddur-python``` in ECR:
```
aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
```
#### Log in to ECR via CLI
 - Login to our ECR repo we created above for the Python base-image so that we can push images to the repository.
 
 ```
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
 ```
#### Set URL
- We will now set path for the address that will map to our ECR IP
```
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"
echo $ECR_PYTHON_URL
```

# Push our Python container image to ECR
### Step 6: Push a Python Image to the container we created above for the Backend 
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
Change from
```FROM python:3.10-slim-buster```
to
```FROM 45ghhgghhhhh.dkr.ecr.us-east-1.amazonaws.com/cruddur-python:3.10-slim-buster```
#### Docker compose up
- Run docker compose up for the Backend and the Database only.
- To test that the application is now running, launch the backend service from the Docker container in a new browser tab then add in ```/api/health-check```, at the end. It should return : 
``` { success: True } ```

### Step 7: Create an Elastic Container Repository(ECR) for Flask
- Create Repository ```backend-flask``` in ECR:
```aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```
#### Set URL
```
export ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"
echo $ECR_BACKEND_FLASK_URL
```

### Step 8: Push a Python Image to the container we created above for Flask
#### Build image
 ```
 docker build -t backend-flask .
 ```
#### Tag Image
 ```
 docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest
 ```
#### Push image to ECR
 ```
 docker push $ECR_BACKEND_FLASK_URL:latest
 ```

# Write an ECS Task Definition file for the Backend ECS-Fargate Container
## Task definition
- The task definition is a document that describes what container images to run together, and what settings to use when running the container images. These settings include the amount of CPU and memory that the container needs. They also include any environment variables that are supplied to the container and any data volumes that are mounted to the container. Task definitions are grouped based on the dimensions of family and revision.

## Difference between tasks and services in ECS
- A ***task*** is the instantiation of a task definition within a cluster. You can run a standalone task, or you can run a task as part of a service.
- You can use an Amazon ECS ***service*** to run and maintain your desired number of tasks simultaneously in an Amazon ECS cluster. How it works is that, if any of your tasks fail or stop for any reason, the Amazon ECS service scheduler launches another instance based on your task definition. It does this to replace it and thereby maintain your desired number of tasks in the service. A service is continously running.

### Step 9: Use Parameter Store to store sensitive account information
- From Systems Manager, in Application Management Use Parameter Store to create parameters that will enable us to conceal sensitive information
- We will ensure that the items listed below have been set as environment variabels(i.e run env |  grep AWS_ACCESS_KEY_ID) and so on to make sure that they have been set in your system.
- Then run the following commands in the terminal.
```
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/CONNECTION_URL" --value $PROD_CONNECTION_URL
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```

- Go to ***AWS Systems Manager > Application Management > Parameter Store*** to make sure that the values were correctly set.

### Step 10: Create an ECS role for our Task Definition file and attach a policy that will allow the ECS role to execute the Task Definition
- In policies, create a service execution role, ```CruddurServiceExecutionRole``` [aws/policies/assume-role-execution-policy.json](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/aws/policies/assume-role-execution-policy.json)
- The policy will allow ECS to assume a role to execute the Task Definition file that we will create below:
- Run the following in the terminal to create the role:
```
aws iam create-role \    
--role-name CruddurServiceExecutionRole  \   
--assume-role-policy-document file://aws/policies/service-execution-policy.json
```
- Confirm that the role was created in the AWS IAM console.
- We will now create a policy, ```CruddurServiceExecutionPolicy``` [aws/policies/service-execution-policy.json](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/aws/policies/service-execution-policy.json) and attach it to the ```CruddurServiceExecutionRole``` and run the following in the terminal to create the policy and attach it to the role simultaneously:
```
aws iam put-role-policy \
  --policy-name CruddurServiceExecutionPolicy \
  --role-name CruddurServiceExecutionRole \
  --policy-document file://aws/policies/service-execution-policy.json
```
***{The CruddurServiceExecutionPolicy must also have the following rules which can be created inline via the console or added as lines to the JSON policy document:
 ecr:GetAuthorizationToken,
 ecr:BatchCheckLayerAvailability,
 ecr:GetDownloadUrlForLayer,
 ecr:BatchGetImage,
 logs:CreateLogStream,
 logs:PutLogEvents
 }***

### Step 11: Create and attach a CloudWatchFullAccess policy tpo the existing CruddurServiceExecutionRole
- We will add another policy, ```CloudWatchFullAccessPolicy``` [aws/policies/cloudwatch-fullaccess-policy.json](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/aws/policies/cloudwatch-fullaccess-policy.json) and attach it to the ```CruddurServiceExecutionRole``` and run the following in the terminal to create the policy and attach it to the role simultaneously:
```
aws iam put-role-policy \
  --policy-name CloudWatchFullAccessPolicy \
  --role-name CruddurServiceExecutionRole \
  --policy-document file://aws/policies/cloudwatch-fullaccess-policy.json
```
***OR you can also do this(if you dont want to create the JSON policy document THEN attach it to the file).***
```
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurServiceExecutionRole
```

### Step 12: Create a CruddurTaskRole and attach a Sessions Manager policy 
- In policies, create a task role, ```CruddurTaskRole``` [aws/policies/service-assume-role-ssm-task-policy.json](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/aws/policies/assume-role-ssm-task-policy.json) and run the following in the terminal to create the role:
```
aws iam create-role \
    --role-name CruddurTaskRole \
    --assume-role-policy-document file://aws/policies/service-assume-role-ssm-task-policy.json
```
- Confirm that the role was created in the AWS IAM console.
- We will now create a policy, ```SSMAccessPolicy``` [aws/policies/ssm-task-policy.json](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/aws/policies/ssm-task-policy.json) and attach it to the ```CruddurTaskRole``` and run the following in the terminal to create the policy and attch it to the role simultaneously:
```
aws iam put-role-policy \
  --policy-name SSMAccessPolicy \
  --role-name CruddurTaskRole \
  --policy-document file://aws/policies/ssm-task-policy.json
```

### Step 13: AttachCreate CloudWatchFullAccess policy to the SSM Task Role
- Attach an existing AWS policy, ```CloudWatch FullAccess``` to the ***CruddurTaskRole*** via the CLI.
```
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurTaskRole
```
***OR you can also do this***
```
aws iam put-role-policy \
  --policy-name CloudWatchFullAccessPolicy \
  --role-name CruddurTaskRole \
  --policy-document file://aws/policies/cloudwatch-fullaccess-policy.json
```

### Step 14: Create a write policy for the XRAY Daemon to the SSM Task Role
- Attach an existing AWS policy, ```AWSXRayDaemonWriteAccess``` to the CruddurTaskRole via the CLI.
```
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess --role-name CruddurTaskRole
```

### Step 15: Create a task definition file(this defines how we provision an application)
- A ***task definition*** is like a blueprint for your application. Each time you launch a task in Amazon ECS, you specify a task definition. The service then knows which Docker image to use for containers, how many containers to use in the task, and the resource allocation for each container.
- Create a Task definition json file in , [aws/task-definitions/backend-flask.json](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/aws/task-definitions/backend-flask.json)
***{Make sure to change the values in the file as per your account, check from the Docker compose file, and the image we created in the ECR repo for the backend}***

- Register the Task definition for the backend-flask
```
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
```
- Check the Task definitions in ```AWS ECS > Task definitions``` to ensure its been created in the console ***(REVISIONS will always update when we change the file therefore always make sure to push changes that you make in the Task Definition file to ECS to use the newer file)***

# Prepare our Backend container to be deployed on ECS Fargate
## Create a Load Balancer, VPCs and Security groups for the Backend services 
### Step 15: Creating a default VPC 
(All these commands should be run in workspace/aws-bootcamp-cruddur)
- Create a default VPC via the terminal/CLI, i.e find the default VPC and return its VPC ID if True.
```
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```

#### Creating a Security Group in the default VPC
- Create a security group via the terminal/CLI
```
export CRUD_SERVICE_SG=$(aws ec2 create-security-group \
  --group-name "crud-srv-sg" \
  --description "Security group for Cruddur services on ECS" \
  --vpc-id $DEFAULT_VPC_ID \
  --query "GroupId" --output text)
echo $CRUD_SERVICE_SG
```

#### Edit the Security Group rules to allow inbound PostgreSQL and HTTP requests
- Edit the inbound rules for another existing security group, and in the CLI, add in a new rule to allow access from PostgreSQL and add in a source from the CRUD_SERVICE_SG and name it as CruddurServices.
```
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_SERVICE_SG \
  --protocol tcp \
  --port 4567 \
  --cidr 0.0.0.0/0
```
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
 - name: fargate
    before: |
      curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
      sudo dpkg -i session-manager-plugin.deb
      cd backend-flask
```

#### Create a Load Balancer via the console
- In the AWS console, search for EC2
- Go to ***Load Balancers*** > Choose the ***Application Load Balancer*** > In ***Load balancer name*** add in cruddur-alb > Set it as ***Internet-facing*** > IP address type as ***IPv4*** > In ***Network mapping***, choose all our existing subnets that we created in the default VPC
- Choose ***Create new security group*** as ```cruddur-alb-sg``` > In the description section add ***cruddur-alb-sg*** > Leave VPC as default > In inbound rules, allow traffic from ***HTTP, HTTPS, 4567 and 3000*** source as anywhere

***{We will now edit the rules for the CRUD_SERVICE_SG we created above to only allow traffic from our Load balancer that we have created, from ports 4567.}***
- In Security groups, choose the Security Group we created above in ***crud-srv-sg***. ***This is because we want all incoming traffic to our application to come through the Load balancer only.***
Choose ***Edit the inbound rules*** > Add a new inbound rule > Choose the new rule as the ***cruddur-alb-sg*** > Choose port range as ***4567*** > Name it as ***CruddurALBFrontend***

- Choose the Security group for the ALB as the newly created ***cruddur-alb-sg***
 
***Create a NEW target group***
- In ***Listeners and routing*** > Choose Protocol as ***HTTP*** > Choose Listener on ***port 4567*** > Choose ***Default action as the target group we will create below***
- Add another Listener in ***Listeners and routing*** > Choose Listener details as ***HTTP*** > Choose Listener on ***port 80*** > Choose ***Default actions*** Add action ***Forward to*** to > Choose ***Target group*** as the ***cruddur-frontend*** ECS container > Leave the Security policy as the default recommended
- Add another Listener in ***Listeners and routing*** > Choose Listener details as ***HTTPS*** > Choose Listener on ***port 443*** > Choose ***Default actions*** Add action ***Redirect*** to ***port 443*** > Choose ***Original host, path, query***
- Choose the ACM/TLS certificate we will create below.
- Add another Listener in ***Listeners and routing*** > Choose Listener details as  host hearder as ***api.cruddur.com***  > Choose ***Target group*** as the ***cruddur-backend*** ECS container > Leave the Security policy as the default recommended
- Choose ***Create a Load Balancer***

# Launch our ECS Fargate container via the CLI
### Step 16: Options for creating our ECS cluster for the backend-flask
#### Option 1: Create our ECS cluster via the console 
- Choose clusters > Choose the ***cruddur*** cluster > Choose ***create*** > Choose Launch type ***FARGATE*** > Choose the platform version as ***LATEST*** > Choose the Deployment configuration ***Service*** >  Choose Family ***backend-flask*** > Revision ***2(LATEST)*** > Choose Service type ***Replica*** > Desired tasks ***1*** > Networking ***Default VPC*** > 

#### Option 2: Create our ECS cluster via the CLI 
- Create an ECS cluster named ***cruddur*** using the terminal, paste in and run:
```
aws ecs create-cluster \
  --cluster-name cruddur \
  --service-connect-defaults namespace=cruddur
```

#### Option 3: Create our ECS cluster from a script
- Create a new file in ```aws/json``` use the following [aws/json/service-backend-flask](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/aws/json/service-backend-flask.json)
```
{
    "cluster": "cruddur",
    "launchType": "FARGATE",
    "desiredCount": 1,
    "enableECSManagedTags": true,
    "enableExecuteCommand": true,
    "LoadBalancers": [
      {
          "targetGroupArn": "copy in the targetgrouparn for the backend",
          "containerName": "backend-flask",
          "containerPort": 4567
       }
     ],
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
- To ***get VPC ID***
```
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```
-  To fill in the ***subnet IDs*** above run the following in the CLI and copy the values(optionally you can get the values from the AWS EC2 the console)
```
export DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets  \
 --filters Name=vpc-id,Values=$DEFAULT_VPC_ID \
 --query 'Subnets[*].SubnetId' \
 --output json | jq -r 'join(",")')
echo $DEFAULT_SUBNET_IDS
```
- To ***get Security Group IDs*** run the following:
```
export CRUD_CLUSTER_SG=$(aws ec2 describe-security-groups \
--group-names cruddur-ecs-cluster-sg \
--query 'SecurityGroups[0].GroupId' \
--output text)
```
- In the terminal,paste and run:
```
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
```

***To test the application in a new tab, use the public IP address in a new tab from the Tasks section and add /healthcheck OR /activities/home at the end of the URL, it should return
```{"success": true}```***

#### Option 4: Create an ECS cluster with Service Connect from the CLI
- Create a new file in ```aws/json``` use the following [aws/json/service-backend-flask.json](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/aws/json/service-backend-flask.json)
```
{
  "cluster": "cruddur",
  "launchType": "FARGATE",
  "desiredCount": 1,
  "enableECSManagedTags": true,
  "enableExecuteCommand": true,
  "LoadBalancers": [
      {
          "targetGroupArn": "copy in the targetgrouparn for the backend loadbalancer",
          "containerName": "backend-flask",
          "containerPort": 4567
       }
  ],
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "assignPublicIp": "ENABLED",
      "securityGroups": [
        "sg-04ca5ebd69e0aec6f"
      ],
      "subnets": [
        "subnet-0462b87709683ccaa",
        "subnet-066a53dd88d557e05",
        "subnet-021a6adafb79249e3"
      ]
    }
  },
  "propagateTags": "SERVICE",
  "serviceName": "backend-flask",
  "taskDefinition": "backend-flask",
  "serviceConnectConfiguration": {
    "enabled": true,
    "namespace": "cruddur",
    "services": [
      {
        "portName": "backend-flask",
        "discoveryName": "backend-flask",
        "clientAliases": [{"port": 4567}]
      }
    ]
  }
}
```
- In the terminal,paste and run:
```
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
```
***To test the application in a new tab, use the public IP address in a new tab from the Tasks section and add /api/healthcheck OR /activities/home at the end of the URL, it should return
```{"success": true}```***

### Step 16: Access our container via SSH
#### Option 1: Create a Sessions Manager script that will allow us to SSH into our container
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

- If we create a Sessions Manager script, it will look something like:, the script below will allow us to use /bin/bash in the container terminal
- Create a new file ```connect-to-backend-service``` in [backend-react/bin/ecs/connect-to-backend-service](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ecs/connect-to-backend-flask)
- Change the permissions on the file in the terminal :
```
chmod u+x ./bin/ecs/connect-to-backend-service
```

- Execute the command in the terminal to connect to the container:
```
./bin/ecs/connect-to-backend-service <task ARN ID> backend-flask
```
- To list tasks:
```
aws ecs list-tasks --cluster cruddur
```

# FOR THE FRONTEND
# Create an Elastic Container Repository (ECR) 
### Step 1: create a new Production Dockerfile  for the frontend
- Create a new file using node, ```Dockerfile.prod``` in [frontend-react-js/Dockerfile.prod](). Which will create static files when we build 
```
# Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM node:16.18 AS build

ARG REACT_APP_BACKEND_URL
ARG REACT_APP_AWS_PROJECT_REGION
ARG REACT_APP_AWS_COGNITO_REGION
ARG REACT_APP_AWS_USER_POOLS_ID
ARG REACT_APP_CLIENT_ID

ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL
ENV REACT_APP_AWS_PROJECT_REGION=$REACT_APP_AWS_PROJECT_REGION
ENV REACT_APP_AWS_COGNITO_REGION=$REACT_APP_AWS_COGNITO_REGION
ENV REACT_APP_AWS_USER_POOLS_ID=$REACT_APP_AWS_USER_POOLS_ID
ENV REACT_APP_CLIENT_ID=$REACT_APP_CLIENT_ID

COPY . ./frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
RUN npm run build

# New Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM nginx:1.23.3-alpine

# --from build is coming from the Base Image
COPY --from=build /frontend-react-js/build /usr/share/nginx/html
COPY --from=build /frontend-react-js/nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000
```
- In ***RecoverPage.js*** and ***ConfirmationPage.js*** change the line
```
setCognitoErrors
to
setErrors
```

#### Create an nginx file
- In ```frontend-react.js``` , create a file [frontend-react.js/nginx.conf](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/nginx.conf)
- In the frontend-react folder, run ```npm run build```.

### Step 2: Create an Elastic Container Repository(ECR) for the Frontend via the CLI
#### Create a Private Repository via the CLI
- To create a repository ```frontend-react-js``` in ECR:
```
aws ecr create-repository \
  --repository-name frontend-react-js \
  --image-tag-mutability MUTABLE
  ```
 
#### Set URL
- We will now set path for the address that will map to our ECR IP
```
export ECR_FRONTEND_REACT_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/frontend-react-js"
echo $ECR_FRONTEND_REACT_URL
```

#### Log in to ECR via CLI
 - Login to our ECR repo we created above for the React-image so that we can push images to the repository.
 
 ```
 aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
 ```

### Step 3: Create our frontend image
#### Build Frontend image locally 
- Switch to ```frontend-react``` and paste in the following code in the terminal:
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
- Get the values of ```REACT_APP_AWS_PROJECT_REGION``` from the Docker compose file
- Inspect the container using
``` docker inspect <container id>```

### Step 4: Push a React Image to the container we created above for the frontend
#### Tag image
```docker tag frontend-react-js:latest $ECR_FRONTEND_REACT_URL:latest```

#### Push image
```docker push $ECR_FRONTEND_REACT_URL:latest```

#### Test the front-end 
- Start the backend and the database images via the Docker icon then,
- Test the front-end by running the following command in the terminal:
```
docker run --rm -p 3000:3000 -it frontend-react-js 
```

# Prepare our Frontend Container to be deployed to Fargate
### Step 5: Create an ECS Task Definition file for Fargate
#### Create a Task definition file for the Front-end container
- To create a task for the container, we will:
- Create a Task definition json file in , [aws/task-definitions/frontend-react-js.json](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/aws/task-definitions/frontend-react-js.json)
***{Make sure to change the values in the file as per your account, check from Docker compose file, and the image we created in the ECR repo for the backend}***
- In the terminal, run 
```chmod u+x ./aws/task-definitions/frontend-react-js.json```
- In task-definition, make sure to add in the ```health-check``` code block below in the json file, at the container level:
```
        "healthCheck": {
          "command": [
            "CMD-SHELL",
            "curl -f http://localhost:3000 || exit 1 "
          ], 
          "interval": 30,
          "timeout": 5,
          "retries": 3
        },
```

#### Register Task definition for the Front-end container
```
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/frontend-react-js.json
``` 
- Check the Task definitions in ```AWS ECS > Task definitions``` to ensure its been created in the console ***(REVISIONS will always update when we change the file therefore always make sure to push changes that you make in the Task Definition file to ECS to use the newer file)***

### Step 6: Create our ECS cluster for the Frontend-flask
#### Edit the security group Inbound rules that will allow requests to the Frontend container from the Load Balancer
***{We will now edit the rules for the CRUD_SERVICE_SG we created above to only allow traffic from our Load balancer that we have created, from ports 3000}***
- In Security groups, choose the Security Group we created above in ***crud-srv-sg***. ***This is because we want all incoming traffic to our application to come through the Load balancer only.***
Choose ***Edit the inbound rules*** > Add a new inbound rule > Choose the new rule as the ***cruddur-alb-sg*** > Choose port range as ***3000*** > Name it as ***CruddurALBFrontend***
Add in a port range ```4567``` for the backend Load Balancer

#### Create a Target group for frontend to the Load Balancer
- In ***Listeners and routing*** > Choose ***create New listener*** > Choose Protocol as ***HTTP*** > Choose Listener on ***port 3000*** > Choose ***Default action as the frontend target group we will create below***
- In the EC2 console, choose ***Target groups*** > Where target type is ***IP addresses*** > Add Target group name ***cruddur-frontendreact-js-tg*** > Listen on Protocol HTTP ***port 3000*** > Leave IP address type, VPC, Protocol version as defaults values > Choose health check path as ***/api/health-check*** > Set threshold times as ***3s*** > Choose ***Create***

- On Listeners and routing choose to listen on HTTP port 3000

# Launch our ECS Fargate container via the CLI
#### Step 7: Create our ECS cluster with Service connect from the CLI
- Create a new file in ```aws/json``` use the following [aws/json/service-frontend-react-js.json](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/aws/json/service-frontend-react-js.json)

- Paste in the following into the terminal create the service:
```
aws ecs create-service --cli-input-json file://aws/json/service-frontend-react-js.json
```
- Login AWS ECS clusters to make sure that its been launched.

### Step 8: Access our container via SSH
#### Connect to the Frontend ECS cluster container
- Create a new file, ```frontend-react-js``` in ```backend-flask/bin/ecs```, [backend-flask/bin/ecs/connect-to-frontend-react-js](https://github.com/Msaghu/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ecs/connect-to-frontend-react-js).
- The script above will allow us to use ```/bin/bash``` in the container terminal
- In the terminal, run 
```
chmod u+x ./bin/ecs/connect-to-frontend-react-js
```
- Then to connect run 
```
./bin/ecs/connect-to-service <task-id/arn number of the service
```
- Test curl in the /bin/sh terminal. by running in the therminal:
```curl localhost:3000```

#### Run the Frontend image
- We will run the container before we can test it.
``` docker run --rm -p 3000:3000 -it frontend-react-js ```

# Create a custom domain with SSL and Route53
### Step 9: Create a Hosted zone in Route 53
- In the AWS console, go to Route 53 > Go to ***Hosted zones*** > Select ***Create a hosted zone*** > In ***Hosted zone configuration/Domain name*** add in ```cruddur.com``` > In ***Type*** choose Public hosted zone then choose ***Create hosted zone***
- Open the ```cruddur.com``` page to view the nameservers.
- If you had bought a domain from a vendor eg GoDaddy, open their name servers page and paste in the values of the nameservers given by AWS Route53  to your domain nameservers from Godaddy.

### Create a record
- In the AWS console, go to Route 53 > Go to the cruddur.com host zone and click ***Create record*** > In Quick create record, select ***A record*** > Choose ***alias*** and Route traffic to the Application Load Balancer we created earlier > Select region wehere we created the LB


### Step : Create an SSL certificate with AWS Certificate Manager
- In the AWS console, go to AWS Certificate Manager > Choose ***Request certificate*** > Choose ***Request a public certificate*** > Choose Next then in Request Public certificate page, Add in your ***Domain name*** (that you created in the step above) > In Validation method, choose ***DNS validation*** > In ***Key algorithm*** leave it as the default > Choose ***Request***.
- While the certificate in creating, we can click into it and choose ***Create DNS records in Amazon Route 53*** 

# Error Handling in Flask
### Step : add a new Dockerfile in the Backend 
- Create a new file ```Dockerfile.prod``` that will allow us to build a backend container with debviuugging turned off
- Edit the existing ```Dockerfile```
- Before creating a production container, we need to make sure to login to the ECR backend repository. Create a script [./bin/]() change permissions and login then run the command below: 
- Run the follopwing in thje terminal:
```
docker build -f Dockerfile.prod  -t backend-flask-prod .
```

### Step: Run Postgres locally
- Run the following in the terminla:
```
docker run -rm \
-p 4567:4567 \
-e AWS_ENDPOINT_URL="http://dynamodb-local:8000" \
-e CONNECTION_URL="postgresql://postgres:password@db:5432/cruddur" \
-e FRONTEND_URL="https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}" \
-e BACKEND_URL="https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}" \
-e OTEL_SERVICE_NAME='backend-flask' \
-e OTEL_EXPORTER_OTLP_ENDPOINT="https://api.honeycomb.io" \
-e OTEL_EXPORTER_OTLP_HEADERS="x-honeycomb-team=${HONEYCOMB_API_KEY}" \
-e AWS_XRAY_URL="*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*" \
-e AWS_XRAY_DAEMON_ADDRESS="xray-daemon:2000" \
-e AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}" \
-e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
-e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
-e ROLLBAR_ACCESS_TOKEN="${ROLLBAR_ACCESS_TOKEN}" \
-e AWS_COGNITO_USER_POOL_ID="${AWS_COGNITO_USER_POOL_ID}" \
-e AWS_COGNITO_USER_POOL_CLIENT_ID="maulolipohdkkfhjdnkdikjfmcfkkdf" \   
-t backend-flask-prod
```

## ECS Security best practises
### Business Use cases of of AWS ECS
1. Deploying an application to a container using AWS ECS.

### Security challenges with AWS Fargate
1. Infrastructure is AWS managed thus no visilibility of infrastructure.
2. Ephemeral resources make it hard to do triage/forensics for detected threats.
3. No file/network monitoring.
4. Cannot run traditional security agents.
5. User can run unverified container images.
6. Containers can run as root and with elevated priviledges(when working with Linux systems, this can be very dangerous as root priviledges give users unlimited access to your entire system thus they can delete important running systems).

### Amazon ECS - Security Best practises
1. 

## Additional homework challenges
1. Create a hosted zone with the AWS CLI
2. Make a bash script that automatically gives the VPC ID and SuBNET IDS.
3. Create a Load Balancer using the CLI
4. Create a a CloudFront domain name via the CLI
5. Create a private reposirory for React


## Aditional links 
1. [Security in AWS ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html)
2. [AWS ECS documentation](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/application.html)
3. [Free AWS bootcamp Week 6-7](https://www.youtube.com/watch?v=HHmpZ5hqh1I&list=PLBfufR7vyJJ7k25byhRXJldB5AiwgNnWv&index=56)
