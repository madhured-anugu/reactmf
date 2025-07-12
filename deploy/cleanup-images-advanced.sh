#!/bin/bash

# Advanced GCP Container Registry Cleanup Script
# Usage: ./cleanup-images-advanced.sh [OPTIONS]
# Options:
#   -k, --keep N          Number of images to keep (default: 2)
#   -s, --service NAME    Clean specific service only
#   -p, --project ID      Use specific project ID
#   -y, --yes             Auto-confirm deletions
#   -d, --dry-run         Show what would be deleted without actually deleting
#   -h, --help            Show this help message

set -e

# Default configuration
KEEP_IMAGES=2
SERVICES=("mfe1-products" "mfe2-profile" "host-app")
AUTO_CONFIRM=false
DRY_RUN=false
SPECIFIC_SERVICE=""
SPECIFIC_PROJECT=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to show help
show_help() {
    echo "GCP Container Registry Cleanup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -k, --keep N          Number of images to keep per service (default: 2)"
    echo "  -s, --service NAME    Clean specific service only (e.g., mfe1-products)"
    echo "  -p, --project ID      Use specific project ID"
    echo "  -y, --yes             Auto-confirm all deletions"
    echo "  -d, --dry-run         Show what would be deleted without actually deleting"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Interactive cleanup, keep 2 images per service"
    echo "  $0 -k 3                      # Keep 3 images per service"
    echo "  $0 -s mfe1-products          # Clean only mfe1-products service"
    echo "  $0 -k 1 -y                   # Keep 1 image per service, auto-confirm"
    echo "  $0 -d                        # Dry run - show what would be deleted"
    echo "  $0 -p my-project-id -s mfe1-products -k 1 -y  # Full example"
    echo ""
    echo "Services configured for cleanup:"
    for service in "${SERVICES[@]}"; do
        echo "  - $service"
    done
}

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

print_dry_run() {
    echo -e "${CYAN}[DRY RUN]${NC} $1"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -k|--keep)
                KEEP_IMAGES="$2"
                shift 2
                ;;
            -s|--service)
                SPECIFIC_SERVICE="$2"
                shift 2
                ;;
            -p|--project)
                SPECIFIC_PROJECT="$2"
                shift 2
                ;;
            -y|--yes)
                AUTO_CONFIRM=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Validate keep images number
    if ! [[ "$KEEP_IMAGES" =~ ^[0-9]+$ ]] || [ "$KEEP_IMAGES" -lt 1 ]; then
        print_error "Invalid number of images to keep: $KEEP_IMAGES"
        exit 1
    fi
    
    # Validate specific service if provided
    if [ -n "$SPECIFIC_SERVICE" ]; then
        local service_found=false
        for service in "${SERVICES[@]}"; do
            if [ "$service" = "$SPECIFIC_SERVICE" ]; then
                service_found=true
                break
            fi
        done
        
        if [ "$service_found" = false ]; then
            print_error "Unknown service: $SPECIFIC_SERVICE"
            echo "Available services: ${SERVICES[*]}"
            exit 1
        fi
    fi
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
}

# Function to cleanup images for a specific service
cleanup_service_images() {
    local service_name=$1
    local project_id=$2
    
    print_status "Analyzing images for service: $service_name"
    
    # Get list of all images for this service, sorted by creation time (newest first)
    local images
    images=$(gcloud container images list-tags "gcr.io/$project_id/$service_name" \
        --format="value(digest)" \
        --sort-by="~timestamp" \
        --limit=1000 2>/dev/null)
    
    if [ -z "$images" ]; then
        print_warning "No images found for service: $service_name"
        return
    fi
    
    # Count total images
    local total_images
    total_images=$(echo "$images" | wc -l | tr -d ' ')
    
    print_status "Found $total_images images for $service_name"
    
    if [ "$total_images" -le "$KEEP_IMAGES" ]; then
        print_success "Only $total_images images found for $service_name. Nothing to cleanup."
        return
    fi
    
    # Skip the first KEEP_IMAGES (newest ones) and get the rest for deletion
    local images_to_delete
    images_to_delete=$(echo "$images" | tail -n +$((KEEP_IMAGES + 1)))
    
    if [ -z "$images_to_delete" ]; then
        print_success "No old images to delete for $service_name"
        return
    fi
    
    local delete_count
    delete_count=$(echo "$images_to_delete" | wc -l | tr -d ' ')
    
    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Would delete $delete_count old images for $service_name (keeping newest $KEEP_IMAGES)"
        echo "Images that would be deleted:"
        echo "$images_to_delete" | while read -r digest; do
            echo "  - gcr.io/$project_id/$service_name@$digest"
        done
        return
    fi
    
    print_warning "Will delete $delete_count old images for $service_name (keeping newest $KEEP_IMAGES)"
    
    # Show what will be deleted
    echo "Images to be deleted:"
    echo "$images_to_delete" | while read -r digest; do
        echo "  - gcr.io/$project_id/$service_name@$digest"
    done
    
    # Ask for confirmation if not auto-confirmed
    if [ "$AUTO_CONFIRM" = false ]; then
        echo ""
        echo "Do you want to proceed with deletion for $service_name? (y/N)"
        read -r CONFIRM
        
        if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
            print_warning "Skipping deletion for $service_name"
            return
        fi
    fi
    
    # Delete images
    local deleted_count=0
    local failed_count=0
    
    echo "$images_to_delete" | while read -r digest; do
        if [ -n "$digest" ]; then
            print_status "Deleting gcr.io/$project_id/$service_name@$digest"
            if gcloud container images delete "gcr.io/$project_id/$service_name@$digest" --quiet 2>/dev/null; then
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
    fi
}

# Function to show current images
show_current_images() {
    local project_id=$1
    local services_to_show=("${SERVICES[@]}")
    
    if [ -n "$SPECIFIC_SERVICE" ]; then
        services_to_show=("$SPECIFIC_SERVICE")
    fi
    
    print_status "Current images in project: $project_id"
    echo ""
    
    for service in "${services_to_show[@]}"; do
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
    
    # Determine project ID
    if [ -n "$SPECIFIC_PROJECT" ]; then
        PROJECT_ID="$SPECIFIC_PROJECT"
        print_status "Using project ID from command line: $PROJECT_ID"
    elif [ -f "../secrets.config" ]; then
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
    
    # Determine which services to clean
    local services_to_clean=("${SERVICES[@]}")
    if [ -n "$SPECIFIC_SERVICE" ]; then
        services_to_clean=("$SPECIFIC_SERVICE")
    fi
    
    echo ""
    print_status "Configuration:"
    print_status "  Project ID: $PROJECT_ID"
    print_status "  Services: ${services_to_clean[*]}"
    print_status "  Images to keep per service: $KEEP_IMAGES"
    print_status "  Auto-confirm: $AUTO_CONFIRM"
    print_status "  Dry run: $DRY_RUN"
    echo ""
    
    # Show current images
    show_current_images "$PROJECT_ID"
    
    # Ask if user wants to proceed with cleanup (unless auto-confirmed or dry run)
    if [ "$AUTO_CONFIRM" = false ] && [ "$DRY_RUN" = false ]; then
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
    fi
    
    # Cleanup images for each service
    echo ""
    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Starting dry run process..."
    else
        print_status "Starting cleanup process..."
    fi
    echo ""
    
    for service in "${services_to_clean[@]}"; do
        cleanup_service_images "$service" "$PROJECT_ID"
        echo ""
    done
    
    if [ "$DRY_RUN" = true ]; then
        print_success "Dry run completed!"
        echo ""
        print_status "To actually delete the images, run the script without the -d flag."
    else
        print_success "Cleanup process completed!"
        echo ""
        
        # Show final state
        print_status "Final state after cleanup:"
        show_current_images "$PROJECT_ID"
    fi
}

# Parse arguments and run main function
parse_args "$@"
main
