#!/bin/bash

# Define variables
REPOSITORY_NAME="donut-rds-app"
REGION="us-east-2"
LOG_FILE="./terraform_execution.log"
LOG_FILE_PATH="./terraform/terraform_execution.log"

# Clear the log file
> "$LOG_FILE_PATH"

# Function to delete all images in the repository
cleanup_ecr_repository() {
  echo "Fetching images from ECR repository: $REPOSITORY_NAME" | tee -a "$LOG_FILE"

  # List all image IDs in the repository
  IMAGE_IDS=$(aws ecr list-images --repository-name "$REPOSITORY_NAME" --region "$REGION" --query 'imageIds[*]' --output json)

  # Check if there are images to delete
  if [[ "$IMAGE_IDS" == "[]" ]]; then
    echo "No images found in the repository." | tee -a "$LOG_FILE"
    return 0
  fi

  # Write image IDs to a temporary file
  echo "$IMAGE_IDS" > image_ids.json

  echo "Deleting images from repository..." | tee -a "$LOG_FILE"
  # Delete images (including tagged ones)
  DELETE_OUTPUT=$(aws ecr batch-delete-image --repository-name "$REPOSITORY_NAME" --region "$REGION" --image-ids file://image_ids.json 2>&1)

  if echo "$DELETE_OUTPUT" | grep -q "failures"; then
    echo "Error: Failed to delete some images. Checking for remaining images..." | tee -a "$LOG_FILE"
    echo "$DELETE_OUTPUT" | grep "failure" | tee -a "$LOG_FILE"
  fi

  # Ensure that all images, even tagged ones, are removed
  aws ecr list-images --repository-name "$REPOSITORY_NAME" --region "$REGION" --query 'imageIds[*]' --output json > remaining_images.json

  # If there are still images remaining, try deleting them
  if [[ -s remaining_images.json ]]; then
    echo "Attempting to delete remaining images..." | tee -a "$LOG_FILE"
    aws ecr batch-delete-image --repository-name "$REPOSITORY_NAME" --region "$REGION" --image-ids file://remaining_images.json > /dev/null
  fi

  # Clean up temporary files
  rm -f image_ids.json remaining_images.json

  # Check if deletion was successful
  remaining_images_count=$(aws ecr list-images --repository-name "$REPOSITORY_NAME" --region "$REGION" --query 'imageIds | length(@)' --output text)
  if [ "$remaining_images_count" -eq 0 ]; then
    echo "All images successfully deleted from the repository." | tee -a "$LOG_FILE"
  else
    echo "Error: Some images could not be deleted." | tee -a "$LOG_FILE"
    return 1
  fi
}

# Step 0: Go into the Terraform directory
cd ./terraform || { echo "Error: Terraform directory not found." | tee -a "$LOG_FILE"; exit 1; }

# Check for command-line arguments
if [[ "$1" == "-c" ]]; then
  # If the user specified -c, run cleanup only
  echo "Running cleanup only..." | tee -a "$LOG_FILE"
  cleanup_ecr_repository
  cd ..
elif [[ "$1" == "" ]]; then
  # If no arguments, run terraform destroy
  echo "Running terraform destroy..." | tee -a "$LOG_FILE"

  # Run terraform destroy
  terraform destroy -auto-approve -no-color >> "$LOG_FILE" 2>&1

  cd ..
  echo "Destroy complete!" | tee -a "$LOG_FILE"
else
  # Invalid argument
  echo "Invalid option. Use '-c' for cleanup only or no argument for destroying all resources." | tee -a "$LOG_FILE"
  cd ..
  exit 1
fi
