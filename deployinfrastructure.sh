#!/bin/bash

# Define variables
TERRAFORM_DIR="./terraform"
TARGETS=("module.main" "module.networking" "module.rds" "module.ecr" "module.fargate")
LOG_FILE="./terraform_execution.log"
LOG_FILE_PATH="./terraform/terraform_execution.log"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
EXECUTE_SQL=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -sql)
      echo "SQL flag detected. SQL script will be executed." | tee -a "$LOG_FILE"
      EXECUTE_SQL=true
      shift # Remove flag from arguments
      ;;
    *)
      echo "Unknown option: $1" | tee -a "$LOG_FILE"
      exit 1
      ;;
  esac
done

# Go into the Terraform directory
cd "$TERRAFORM_DIR" || { echo "Error: Terraform directory not found." | tee -a "$LOG_FILE"; exit 1; }

# Clear the log file
> "$LOG_FILE"

# Helper function to apply Terraform modules
apply_module() {
  local module=$1
  echo "Applying ${module}..." | tee -a "$LOG_FILE"
  terraform apply -target="$module" -auto-approve -no-color >> "$LOG_FILE" 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: Failed to apply ${module}. Check the log file for details." | tee -a "$LOG_FILE"
    exit 1
  fi
}

# Apply modules step by step
apply_module "${TARGETS[0]}"
apply_module "${TARGETS[1]}"
apply_module "${TARGETS[2]}"

# Output RDS endpoint
echo "Fetching RDS endpoint..." | tee -a "$LOG_FILE"
terraform refresh >> "$LOG_FILE" 2>&1
RDS_ENDPOINT=$(terraform state show module.rds.aws_db_instance.donutdb | grep "endpoint" | awk '{print $3}' | tr -d '"' | tr -d '[]' | cut -d':' -f1)

if [ -z "$RDS_ENDPOINT" ]; then
  echo "Error: RDS endpoint not found. Check Terraform outputs." | tee -a "$LOG_FILE"
  exit 1
fi

echo "RDS endpoint: $RDS_ENDPOINT" | tee -a "$LOG_FILE"

# Apply ECR module
apply_module "${TARGETS[3]}"

# Fetch ECR Repository URL
echo "Checking if ECR repository exists in state..." | tee -a "$LOG_FILE"
terraform show | grep "aws_ecr_repository.app_repository" >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
  echo "ECR repository not found in state. Applying ECR repository..." | tee -a "$LOG_FILE"
  terraform apply -target=aws_ecr_repository.app_repository -auto-approve -no-color >> "$LOG_FILE" 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create ECR repository. Check the log file for details." | tee -a "$LOG_FILE"
    exit 1
  fi
fi

echo "Fetching ECR repository URL..." | tee -a "$LOG_FILE"
terraform refresh >> "$LOG_FILE" 2>&1
ECR_URL=$(terraform state show module.ecr.aws_ecr_repository.app_repository | grep "repository_url" | awk '{print $3}' | tr -d '"')
if [ -z "$ECR_URL" ]; then
  echo "Error: ECR repository URL not found. Check Terraform outputs." | tee -a "$LOG_FILE"
  exit 1
fi

# Authenticate Docker with ECR
echo "Authenticating Docker with ECR..." | tee -a "$LOG_FILE"
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin "$ECR_URL" >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Docker authentication with ECR failed. Check the log file for details." | tee -a "$LOG_FILE"
  exit 1
fi

# Build, Tag, and Push Docker Image
echo "Building Docker image..." | tee -a "$LOG_FILE"
cd ..
CURRENT_PLATFORM=$(uname -m)

if [ "$CURRENT_PLATFORM" == "x86_64" ]; then
  docker build -t donut-app . >> "$LOG_FILE_PATH" 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: Docker build failed. Check the log file for details." | tee -a "$LOG_FILE_PATH"
    exit 1
  fi

  echo "Tagging Docker image..." | tee -a "$LOG_FILE_PATH"
  docker tag donut-app:latest "$ECR_URL:latest" >> "$LOG_FILE_PATH" 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: Docker image tagging failed. Check the log file for details." | tee -a "$LOG_FILE_PATH"
    exit 1
  fi

  # Push Docker Image to ECR
  echo "Pushing Docker image to ECR..." | tee -a "$LOG_FILE_PATH"
  docker push "$ECR_URL:latest" >> "$LOG_FILE_PATH" 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: Docker image push to ECR failed. Check the log file for details." | tee -a "$LOG_FILE_PATH"
    echo "Cleaning up..." | tee -a "$LOG_FILE_PATH"
    docker rmi -f donut-app:latest "$ACCOUNT_ID".dkr.ecr.us-east-2.amazonaws.com/donut-rds-app:latest >> "$LOG_FILE_PATH" 2>&1
    exit 1
  fi

  echo "Cleaning up..." | tee -a "$LOG_FILE_PATH"
  docker rmi -f donut-app:latest "$ECR_URL:latest" >> "$LOG_FILE_PATH" 2>&1

  echo "Docker image successfully pushed to ECR." | tee -a "$LOG_FILE_PATH"
else
  echo "Building and pushing Docker image for platform(s): linux/amd64..." | tee -a "$LOG_FILE_PATH"

  # Ensure buildx is created and used only once
  docker buildx create --use >> "$LOG_FILE_PATH" 2>&1 || echo "Buildx is already initialized." | tee -a "$LOG_FILE_PATH"

  # Build and tag Docker image
  docker buildx build --platform "linux/amd64" -t "$ECR_URL:latest" --push . >> "$LOG_FILE_PATH" 2>&1

  # Check if the build succeeded
  if [ $? -ne 0 ]; then
    echo "Error: Docker build/push failed. Check the log file for details." >> "$LOG_FILE_PATH"
    exit 1
  fi

  echo "Docker image successfully pushed to ECR. Remember to clean up your Docker containers and images." | tee -a "$LOG_FILE_PATH"
fi

# Populate RDS with initial data (conditional on -sql flag)
if [ "$EXECUTE_SQL" = true ]; then
  echo "Initializing RDS database with SQL file..." | tee -a "$LOG_FILE_PATH"
  mysql -h "$RDS_ENDPOINT" -u admin -p password < ../initialize_db.sql >> "$LOG_FILE_PATH" 2>&1
  if [ $? -ne 0 ]; then
      echo "Error: Failed to execute SQL script. Check the log file for details." | tee -a "$LOG_FILE_PATH"
      exit 1
  fi
  echo "Database initialization complete." | tee -a "$LOG_FILE_PATH"
else
  echo "Skipping SQL initialization." | tee -a "$LOG_FILE_PATH"
fi

# Apply Fargate Deployment
cd terraform
apply_module "${TARGETS[4]}"

# Output results
echo "Terraform apply completed. Outputting results..." | tee -a "$LOG_FILE"
terraform output -no-color >> "$LOG_FILE" 2>&1

# Output the URL of the Fargate app
echo "Fetching Load Balancer DNS URL..." | tee -a "$LOG_FILE"
LB_DNS_NAME=$(terraform state show module.fargate.aws_lb.donut_lb | grep "dns_name" | awk '{print $3}' | tr -d '"' 2>>"$LOG_FILE")
if [ -z "$LB_DNS_NAME" ]; then
  echo "Error: Load Balancer DNS name not found. Check Terraform outputs." | tee -a "$LOG_FILE"
fi

echo "Fargate app is accessible at: http://$LB_DNS_NAME" | tee -a "$LOG_FILE"
echo "Please wait a few minutes to allow the tasks to start and the DNS to propagate." | tee -a "$LOG_FILE"
echo "Infrastructure deployment complete!" | tee -a "$LOG_FILE"
echo "Check the log file for detailed execution logs." | tee -a "$LOG_FILE"
