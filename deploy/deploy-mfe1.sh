#!/bin/bash

# Deploy MFE1 (Product List) to GCP Cloud Run

# Configuration
IMAGE_NAME="mfe1-products"
REGION="us-central1"
SERVICE_NAME="mfe1-products"

# Function to get available GCP projects
get_gcp_projects() {
    gcloud projects list --format="value(projectId)" 2>/dev/null
}

# Function to select project interactively
select_project() {
    echo "Verifying GCP account authentication..."
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null 2>&1; then
        echo "You are not authenticated with gcloud. Please run 'gcloud auth login' first."
        exit 1
    fi
    
    echo "✓ GCP authentication verified"
    echo ""
    
    echo "Fetching available GCP projects..."
    PROJECTS=$(get_gcp_projects)
    
    if [ -z "$PROJECTS" ]; then
        echo "ERROR: No GCP projects found or unable to access projects."
        exit 1
    fi
    
    echo "Available GCP projects:"
    echo "----------------------"
    
    PROJECT_ARRAY=()
    INDEX=1
    
    while IFS= read -r project; do
        echo "$INDEX) $project"
        PROJECT_ARRAY+=("$project")
        ((INDEX++))
    done <<< "$PROJECTS"
    
    echo ""
    echo "Please select a project by entering the number (1-$((INDEX-1))):"
    read -r SELECTION
    
    if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt $((INDEX-1)) ]; then
        echo "ERROR: Invalid selection. Please enter a number between 1 and $((INDEX-1))."
        exit 1
    fi
    
    PROJECT_ID="${PROJECT_ARRAY[$((SELECTION-1))]}"
    echo "Selected project: $PROJECT_ID"
    
    echo "PROJECT_ID=$PROJECT_ID" > ../secrets.config
    echo "✓ Project ID saved to secrets.config"
}

# Check for secrets.config file
if [ -f "../secrets.config" ]; then
    echo "Loading configuration from secrets.config..."
    source ../secrets.config
    
    if [ -z "$PROJECT_ID" ]; then
        echo "WARNING: PROJECT_ID not found in secrets.config"
        select_project
    else
        echo "Using PROJECT_ID from secrets.config: $PROJECT_ID"
        
        if ! gcloud projects describe "$PROJECT_ID" > /dev/null 2>&1; then
            echo "WARNING: Cannot access project '$PROJECT_ID' from secrets.config"
            select_project
        fi
    fi
else
    echo "secrets.config not found."
    select_project
fi

echo ""
echo "Deploying MFE1 (Product List) to Google Cloud Run..."
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Service Name: $SERVICE_NAME"
echo ""

# Set the current project
echo "Setting current GCP project..."
gcloud config set project "$PROJECT_ID"

# Build the Docker image
echo "Building Docker image for Cloud Run (linux/amd64 platform)..."
cd ..
docker build --platform linux/amd64 -f deploy/Dockerfile.mfe1 -t "gcr.io/$PROJECT_ID/$IMAGE_NAME" .
cd deploy

if [ $? -ne 0 ]; then
    echo "ERROR: Docker build failed."
    exit 1
fi

# Configure Docker to use gcloud credentials
echo "Configuring Docker to use gcloud credentials..."
gcloud auth configure-docker

# Push the image to Google Container Registry
echo "Pushing image to Google Container Registry..."
docker push "gcr.io/$PROJECT_ID/$IMAGE_NAME"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to push Docker image."
    exit 1
fi

# Deploy to Cloud Run
echo "Deploying to Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
  --image "gcr.io/$PROJECT_ID/$IMAGE_NAME" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080

if [ $? -ne 0 ]; then
    echo "ERROR: Deployment to Cloud Run failed."
    exit 1
fi

# Get the deployed service URL
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --platform managed --region "$REGION" --format 'value(status.url)')

echo ""
echo "🎉 MFE1 (Product List) deployment successful!"
echo "Your Product List MFE is now available at: $SERVICE_URL"
echo ""
echo "Remote Entry URL: ${SERVICE_URL}/assets/remoteEntry.js"
echo "Use this URL in your host application to load this micro frontend."
