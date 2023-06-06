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

## Prepare oyr Flask App to use the python image from ECR
Copy URI from ECR python

## Docker compose up
Run docker compose up for select services
``` 
 
