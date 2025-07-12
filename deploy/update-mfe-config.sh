#!/bin/bash

# Script to create and update MFE URLs in Google Cloud Storage
# This will be called after successful MFE deployments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
BUCKET_NAME=""
CONFIG_FILE="mfe-urls.json"
TEMP_FILE="/tmp/mfe-urls.json"

# Load project configuration
if [ -f "../secrets.config" ]; then
    source ../secrets.config
    PROJECT_ID="${PROJECT_ID}"
else
    print_error "secrets.config not found. Please run a deployment script first."
    exit 1
fi

# Set bucket name based on project
BUCKET_NAME="${PROJECT_ID}-mfe-config"

print_status "Project ID: $PROJECT_ID"
print_status "Bucket Name: $BUCKET_NAME"

# Function to create bucket if it doesn't exist
create_bucket_if_needed() {
    print_status "Checking if bucket exists: $BUCKET_NAME"
    
    if gsutil ls -b "gs://$BUCKET_NAME" > /dev/null 2>&1; then
        print_success "Bucket already exists: $BUCKET_NAME"
    else
        print_status "Creating bucket: $BUCKET_NAME"
        
        # Create bucket with public access
        if gsutil mb -p "$PROJECT_ID" -b on "gs://$BUCKET_NAME"; then
            print_success "Created bucket: $BUCKET_NAME"
        else
            print_error "Failed to create bucket: $BUCKET_NAME"
            exit 1
        fi
    fi
    
    # Always try to set bucket to public access (ignore errors)
    print_status "Configuring bucket for public access..."
    
    # Get current user email
    local current_user
    current_user=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
    
    if [ -n "$current_user" ]; then
        print_status "Ensuring user has necessary permissions..."
        # Grant storage admin permissions to current user
        gsutil iam ch user:"$current_user":objectAdmin "gs://$BUCKET_NAME" 2>/dev/null || {
            print_warning "Could not set user permissions"
        }
    fi
    
    # Enable uniform bucket-level access
    gsutil uniformbucketlevelaccess set on "gs://$BUCKET_NAME" 2>/dev/null || {
        print_warning "Could not enable uniform bucket-level access"
    }
    
    # Make bucket publicly readable
    gsutil iam ch allUsers:objectViewer "gs://$BUCKET_NAME" 2>/dev/null || {
        print_warning "Could not set bucket-level permissions"
    }
    
    print_success "Bucket configuration completed"
}

# Function to get current service URL
get_service_url() {
    local service_name=$1
    local region="us-central1"
    
    local url
    url=$(gcloud run services describe "$service_name" \
        --platform managed \
        --region "$region" \
        --format 'value(status.url)' 2>/dev/null)
    
    if [ -n "$url" ]; then
        echo "$url"
    else
        echo ""
    fi
}

# Function to create or update the MFE URLs JSON
update_mfe_urls() {
    print_status "Getting current MFE service URLs..."
    
    # Get service URLs
    local mfe1_url
    local mfe2_url
    local host_url
    
    mfe1_url=$(get_service_url "mfe1-products")
    mfe2_url=$(get_service_url "mfe2-profile")
    host_url=$(get_service_url "host-app")
    
    print_status "MFE1 URL: ${mfe1_url:-'Not deployed'}"
    print_status "MFE2 URL: ${mfe2_url:-'Not deployed'}"
    print_status "Host URL: ${host_url:-'Not deployed'}"
    
    # Create JSON configuration
    cat > "$TEMP_FILE" << EOF
{
  "lastUpdated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "projectId": "$PROJECT_ID",
  "services": {
    "mfe1": {
      "name": "mfe1-products",
      "url": "${mfe1_url}",
      "remoteEntry": "${mfe1_url}/assets/remoteEntry.js",
      "status": "${mfe1_url:+deployed}"
    },
    "mfe2": {
      "name": "mfe2-profile", 
      "url": "${mfe2_url}",
      "remoteEntry": "${mfe2_url}/assets/remoteEntry.js",
      "status": "${mfe2_url:+deployed}"
    },
    "host": {
      "name": "host-app",
      "url": "${host_url}",
      "status": "${host_url:+deployed}"
    }
  },
  "mfeUrls": {
    "mfe1": "${mfe1_url}/assets/remoteEntry.js",
    "mfe2": "${mfe2_url}/assets/remoteEntry.js"
  }
}
EOF
    
    print_status "Created configuration file:"
    cat "$TEMP_FILE"
    
    # Upload to Google Cloud Storage
    print_status "Uploading configuration to Cloud Storage..."
    
    if gsutil cp "$TEMP_FILE" "gs://$BUCKET_NAME/$CONFIG_FILE"; then
        print_success "Uploaded configuration to gs://$BUCKET_NAME/$CONFIG_FILE"
        
        # Set content type and cache control (ignore errors)
        gsutil setmeta -h "Content-Type:application/json" \
                      -h "Cache-Control:no-cache, max-age=0" \
                      "gs://$BUCKET_NAME/$CONFIG_FILE" 2>/dev/null || {
            print_warning "Could not set metadata, but file was uploaded successfully"
        }
        
        print_success "Configuration is accessible at:"
        print_success "https://storage.googleapis.com/$BUCKET_NAME/$CONFIG_FILE"
        
        # Test accessibility
        print_status "Testing public accessibility..."
        sleep 2  # Wait a moment for the file to be available
        if curl -s -f "https://storage.googleapis.com/$BUCKET_NAME/$CONFIG_FILE" > /dev/null; then
            print_success "✓ File is publicly accessible"
        else
            print_warning "⚠️ File may not be publicly accessible yet"
            print_status "This is normal and may take a few moments to propagate"
        fi
    else
        print_error "Failed to upload configuration file"
        exit 1
    fi
    
    # Clean up temp file
    rm -f "$TEMP_FILE"
}

# Function to show current configuration
show_current_config() {
    print_status "Current MFE Configuration:"
    
    if gsutil ls "gs://$BUCKET_NAME/$CONFIG_FILE" > /dev/null 2>&1; then
        print_status "Downloading current configuration..."
        gsutil cp "gs://$BUCKET_NAME/$CONFIG_FILE" "$TEMP_FILE"
        
        echo "----------------------------------------"
        cat "$TEMP_FILE"
        echo "----------------------------------------"
        
        rm -f "$TEMP_FILE"
    else
        print_warning "No configuration file found in storage"
    fi
}

# Main function
main() {
    echo "=========================================="
    echo "  MFE URL Configuration Manager"
    echo "=========================================="
    echo ""
    
    # Set the current project
    gcloud config set project "$PROJECT_ID"
    
    case "${1:-update}" in
        "update")
            create_bucket_if_needed
            update_mfe_urls
            ;;
        "show")
            show_current_config
            ;;
        "create-bucket")
            create_bucket_if_needed
            ;;
        *)
            echo "Usage: $0 [update|show|create-bucket]"
            echo ""
            echo "Commands:"
            echo "  update        Update MFE URLs from current deployments (default)"
            echo "  show          Show current configuration from storage"
            echo "  create-bucket Create storage bucket only"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
