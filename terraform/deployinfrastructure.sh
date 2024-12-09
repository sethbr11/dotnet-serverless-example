#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define variables
TERRAFORM_DIR="./terraform"
TARGETS=("module.main" "module.networking" "module.rds" "module.fargate")

# Step 1: Apply Provider Resources
echo "Applying provider resources..."
terraform apply -target=${TARGETS[0]} -auto-approve

# Step 2: Apply Networking Resources
echo "Applying networking resources..."
terraform apply -target=${TARGETS[1]} -auto-approve

# Step 3: Apply RDS Database Resources
echo "Applying RDS database resources..."
terraform apply -target=${TARGETS[2]} -auto-approve

# Step 4: Apply Fargate Deployment
echo "Applying Fargate deployment..."
terraform apply -target=${TARGETS[3]} -auto-approve

# Step 5: Output results
echo "Terraform apply completed. Outputting results..."
terraform output

echo "Infrastructure deployment complete!"
