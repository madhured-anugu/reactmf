#!/bin/bash

# Manual image cleanup script
# Use this when you need to clean up specific images manually

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

# Load project configuration
if [ -f "../secrets.config" ]; then
    source ../secrets.config
    PROJECT_ID="${PROJECT_ID}"
else
    echo "Enter your GCP Project ID:"
    read -r PROJECT_ID
fi

echo "=========================================="
echo "  Manual GCP Image Cleanup"
echo "=========================================="
echo ""
print_status "Project ID: $PROJECT_ID"
echo ""

# Function to delete all untagged images for a service
delete_untagged_images() {
    local service_name=$1
    
    print_status "Finding untagged images for $service_name..."
    
    # Get untagged images (those without tags)
    local untagged_images
    untagged_images=$(gcloud container images list-tags "gcr.io/$PROJECT_ID/$service_name" \
        --format="value(digest)" \
        --filter="NOT tags:*" \
        --limit=1000 2>/dev/null)
    
    if [ -z "$untagged_images" ]; then
        print_status "No untagged images found for $service_name"
        return
    fi
    
    local count
    count=$(echo "$untagged_images" | wc -l | tr -d ' ')
    
    print_warning "Found $count untagged images for $service_name"
    echo "Untagged images:"
    echo "$untagged_images" | while read -r digest; do
        echo "  - gcr.io/$PROJECT_ID/$service_name@$digest"
    done
    
    echo ""
    echo "Delete all untagged images for $service_name? (y/N)"
    read -r CONFIRM
    
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "$untagged_images" | while read -r digest; do
            if [ -n "$digest" ]; then
                print_status "Deleting gcr.io/$PROJECT_ID/$service_name@$digest"
                if gcloud container images delete "gcr.io/$PROJECT_ID/$service_name@$digest" --quiet --force-delete-tags 2>/dev/null; then
                    print_success "Deleted $digest"
                else
                    print_error "Failed to delete $digest"
                fi
            fi
        done
    fi
}

# Function to delete all images except latest for a service
delete_all_except_latest() {
    local service_name=$1
    
    print_status "Finding images for $service_name (except latest)..."
    
    # Get all images except those tagged with 'latest'
    local images_to_delete
    images_to_delete=$(gcloud container images list-tags "gcr.io/$PROJECT_ID/$service_name" \
        --format="value(digest)" \
        --filter="NOT tags:latest" \
        --limit=1000 2>/dev/null)
    
    if [ -z "$images_to_delete" ]; then
        print_status "No images found for deletion (only latest exists)"
        return
    fi
    
    local count
    count=$(echo "$images_to_delete" | wc -l | tr -d ' ')
    
    print_warning "Found $count images for deletion (keeping latest)"
    echo "Images to delete:"
    echo "$images_to_delete" | while read -r digest; do
        echo "  - gcr.io/$PROJECT_ID/$service_name@$digest"
    done
    
    echo ""
    echo "Delete all images except latest for $service_name? (y/N)"
    read -r CONFIRM
    
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "$images_to_delete" | while read -r digest; do
            if [ -n "$digest" ]; then
                print_status "Deleting gcr.io/$PROJECT_ID/$service_name@$digest"
                if gcloud container images delete "gcr.io/$PROJECT_ID/$service_name@$digest" --quiet --force-delete-tags 2>/dev/null; then
                    print_success "Deleted $digest"
                else
                    print_error "Failed to delete $digest"
                fi
            fi
        done
    fi
}

# Function to force delete all images for a service
force_delete_all_images() {
    local service_name=$1
    
    print_warning "This will delete ALL images for $service_name"
    echo "Are you sure? This cannot be undone! (y/N)"
    read -r CONFIRM
    
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        print_status "Deleting all images for $service_name..."
        
        # Delete the entire image repository
        if gcloud container images delete "gcr.io/$PROJECT_ID/$service_name" --quiet --force-delete-tags 2>/dev/null; then
            print_success "All images deleted for $service_name"
        else
            print_error "Failed to delete all images for $service_name"
        fi
    fi
}

# Main menu
while true; do
    echo ""
    echo "Select an option:"
    echo "1) Delete untagged images for mfe1-products"
    echo "2) Delete untagged images for mfe2-profile"
    echo "3) Delete untagged images for host-app"
    echo "4) Delete all except latest for mfe1-products"
    echo "5) Delete all except latest for mfe2-profile"
    echo "6) Delete all except latest for host-app"
    echo "7) Force delete ALL images for mfe1-products"
    echo "8) Force delete ALL images for mfe2-profile"
    echo "9) Force delete ALL images for host-app"
    echo "10) Show current images"
    echo "11) Exit"
    echo ""
    echo "Enter your choice (1-11):"
    read -r CHOICE
    
    case $CHOICE in
        1)
            delete_untagged_images "mfe1-products"
            ;;
        2)
            delete_untagged_images "mfe2-profile"
            ;;
        3)
            delete_untagged_images "host-app"
            ;;
        4)
            delete_all_except_latest "mfe1-products"
            ;;
        5)
            delete_all_except_latest "mfe2-profile"
            ;;
        6)
            delete_all_except_latest "host-app"
            ;;
        7)
            force_delete_all_images "mfe1-products"
            ;;
        8)
            force_delete_all_images "mfe2-profile"
            ;;
        9)
            force_delete_all_images "host-app"
            ;;
        10)
            echo ""
            print_status "Current images:"
            for service in "mfe1-products" "mfe2-profile" "host-app"; do
                echo ""
                echo "Service: $service"
                echo "-------------------"
                gcloud container images list-tags "gcr.io/$PROJECT_ID/$service" \
                    --format="table(tags:label=TAG,digest:label=DIGEST,timestamp:label=CREATED)" \
                    --sort-by="~timestamp" \
                    --limit=10 2>/dev/null || echo "No images found"
            done
            ;;
        11)
            print_status "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please enter 1-11."
            ;;
    esac
done
