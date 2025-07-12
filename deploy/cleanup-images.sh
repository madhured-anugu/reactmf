#!/bin/bash

# Cleanup old Docker images from Google Container Registry
# Keeps only the last 2 images for each service

set -e

# Configuration
KEEP_IMAGES=2
SERVICES=("mfe1-products" "mfe2-profile" "host-app")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to get available GCP projects
get_gcp_projects() {
    gcloud projects list --format="value(projectId)" 2>/dev/null
}

# Function to select project interactively
select_project() {
    echo "Verifying GCP account authentication..."
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null 2>&1; then
        print_error "You are not authenticated with gcloud. Please run 'gcloud auth login' first."
        exit 1
    fi
    
    print_success "GCP authentication verified"
    echo ""
    
    echo "Fetching available GCP projects..."
    PROJECTS=$(get_gcp_projects)
    
    if [ -z "$PROJECTS" ]; then
        print_error "No GCP projects found or unable to access projects."
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
        print_error "Invalid selection. Please enter a number between 1 and $((INDEX-1))."
        exit 1
    fi
    
    PROJECT_ID="${PROJECT_ARRAY[$((SELECTION-1))]}"
    echo "Selected project: $PROJECT_ID"
    
    echo "PROJECT_ID=$PROJECT_ID" > ../secrets.config
    print_success "Project ID saved to secrets.config"
}

# Function to cleanup images for a specific service
cleanup_service_images() {
    local service_name=$1
    local project_id=$2
    
    print_status "Cleaning up images for service: $service_name"
    
    # Get list of all images for this service, sorted by creation time (newest first)
    # Include both tagged and untagged images
    local images_with_info
    images_with_info=$(gcloud container images list-tags "gcr.io/$project_id/$service_name" \
        --format="csv(digest,tags,timestamp)" \
        --sort-by="~timestamp" \
        --limit=1000 2>/dev/null)
    
    if [ -z "$images_with_info" ]; then
        print_warning "No images found for service: $service_name"
        return
    fi
    
    # Skip header line and process images
    local images_data
    images_data=$(echo "$images_with_info" | tail -n +2)
    
    # Count total images
    local total_images
    total_images=$(echo "$images_data" | wc -l | tr -d ' ')
    
    print_status "Found $total_images images for $service_name"
    
    if [ "$total_images" -le "$KEEP_IMAGES" ]; then
        print_success "Only $total_images images found for $service_name. Nothing to cleanup."
        return
    fi
    
    # Get images to delete (skip first KEEP_IMAGES)
    local images_to_delete
    images_to_delete=$(echo "$images_data" | tail -n +$((KEEP_IMAGES + 1)))
    
    if [ -z "$images_to_delete" ]; then
        print_success "No old images to delete for $service_name"
        return
    fi
    
    local delete_count
    delete_count=$(echo "$images_to_delete" | wc -l | tr -d ' ')
    
    print_warning "Will delete $delete_count old images for $service_name (keeping newest $KEEP_IMAGES)"
    
    # Show what will be deleted
    echo "Images to be deleted:"
    echo "$images_to_delete" | while IFS=',' read -r digest tags timestamp; do
        if [ -n "$tags" ] && [ "$tags" != '""' ]; then
            echo "  - gcr.io/$project_id/$service_name@$digest (tags: $tags)"
        else
            echo "  - gcr.io/$project_id/$service_name@$digest (untagged)"
        fi
    done
    
    echo ""
    echo "Do you want to proceed with deletion? (y/N)"
    read -r CONFIRM
    
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        print_warning "Skipping deletion for $service_name"
        return
    fi
    
    # Delete images
    local deleted_count=0
    local failed_count=0
    
    echo "$images_to_delete" | while IFS=',' read -r digest tags timestamp; do
        if [ -n "$digest" ]; then
            local image_ref="gcr.io/$project_id/$service_name@$digest"
            
            # If the image has tags, try to delete by tag first
            if [ -n "$tags" ] && [ "$tags" != '""' ]; then
                # Remove quotes from tags
                local clean_tags=$(echo "$tags" | sed 's/"//g')
                
                # Split tags by semicolon and delete each
                IFS=';' read -ra TAG_ARRAY <<< "$clean_tags"
                for tag in "${TAG_ARRAY[@]}"; do
                    if [ -n "$tag" ]; then
                        print_status "Deleting tagged image: gcr.io/$project_id/$service_name:$tag"
                        if gcloud container images delete "gcr.io/$project_id/$service_name:$tag" --quiet --force-delete-tags 2>/dev/null; then
                            print_success "Deleted tagged image: $tag"
                        else
                            print_warning "Failed to delete tagged image: $tag, trying by digest"
                        fi
                    fi
                done
            fi
            
            # Also try to delete by digest
            print_status "Deleting image by digest: $image_ref"
            if gcloud container images delete "$image_ref" --quiet --force-delete-tags 2>/dev/null; then
                ((deleted_count++))
                print_success "Deleted image $digest"
            else
                ((failed_count++))
                print_error "Failed to delete image $digest"
            fi
        fi
    done
    
    print_success "Cleanup completed for $service_name"
    if [ $failed_count -gt 0 ]; then
        print_warning "Failed to delete $failed_count images for $service_name"
        print_status "Some images might be referenced by running services or have dependencies."
    fi
}

# Function to show current images
show_current_images() {
    local project_id=$1
    
    print_status "Current images in project: $project_id"
    echo ""
    
    for service in "${SERVICES[@]}"; do
        echo "Service: $service"
        echo "----------------------------------------"
        
        # Get images with tags and timestamps
        local images_info
        images_info=$(gcloud container images list-tags "gcr.io/$project_id/$service" \
            --format="table(tags:label=TAG,digest:label=DIGEST,timestamp:label=CREATED)" \
            --sort-by="~timestamp" \
            --limit=10 2>/dev/null)
        
        if [ -z "$images_info" ]; then
            print_warning "No images found for $service"
        else
            echo "$images_info"
        fi
        echo ""
    done
}

# Main script
main() {
    echo "=========================================="
    echo "  GCP Container Registry Cleanup Script"
    echo "=========================================="
    echo ""
    
    # Check for secrets.config file
    if [ -f "../secrets.config" ]; then
        print_status "Loading configuration from secrets.config..."
        source ../secrets.config
        
        if [ -z "$PROJECT_ID" ]; then
            print_warning "PROJECT_ID not found in secrets.config"
            select_project
        else
            print_status "Using PROJECT_ID from secrets.config: $PROJECT_ID"
            
            if ! gcloud projects describe "$PROJECT_ID" > /dev/null 2>&1; then
                print_warning "Cannot access project '$PROJECT_ID' from secrets.config"
                select_project
            fi
        fi
    else
        print_warning "secrets.config not found."
        select_project
    fi
    
    # Set the current project
    print_status "Setting current GCP project..."
    gcloud config set project "$PROJECT_ID"
    
    echo ""
    print_status "Configuration:"
    print_status "  Project ID: $PROJECT_ID"
    print_status "  Services: ${SERVICES[*]}"
    print_status "  Images to keep per service: $KEEP_IMAGES"
    echo ""
    
    # Show current images
    show_current_images "$PROJECT_ID"
    
    # Ask if user wants to proceed with cleanup
    echo ""
    print_warning "This will delete old Docker images from Google Container Registry."
    print_warning "Only the newest $KEEP_IMAGES images will be kept for each service."
    echo ""
    echo "Do you want to proceed? (y/N)"
    read -r PROCEED
    
    if [[ ! "$PROCEED" =~ ^[Yy]$ ]]; then
        print_warning "Cleanup cancelled."
        exit 0
    fi
    
    # Cleanup images for each service
    echo ""
    print_status "Starting cleanup process..."
    echo ""
    
    for service in "${SERVICES[@]}"; do
        cleanup_service_images "$service" "$PROJECT_ID"
        echo ""
    done
    
    print_success "Cleanup process completed!"
    echo ""
    
    # Show final state
    print_status "Final state after cleanup:"
    show_current_images "$PROJECT_ID"
}

# Run main function
main "$@"
