# Week 6 — Deploying Containers

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


 
