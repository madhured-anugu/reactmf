#!/bin/bash

# Complete MFE deployment workflow script
# This script deploys MFEs first, then the host with automatic URL injection

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Function to show help
show_help() {
    echo "MFE Complete Deployment Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  mfes-only     Deploy only MFEs (MFE1 and MFE2)"
    echo "  host-only     Deploy only the host application"
    echo "  full          Deploy MFEs first, then host (default)"
    echo "  config-only   Update MFE configuration in Cloud Storage only"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0            # Full deployment (MFEs + Host)"
    echo "  $0 full       # Same as above"
    echo "  $0 mfes-only  # Deploy only MFEs"
    echo "  $0 host-only  # Deploy only host"
    echo "  $0 config-only # Update configuration only"
}

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if secrets.config exists
    if [ ! -f "../secrets.config" ]; then
        print_error "secrets.config not found. Please run a deployment script first to configure your project."
        exit 1
    fi
    
    # Load project configuration
    source ../secrets.config
    
    if [ -z "$PROJECT_ID" ]; then
        print_error "PROJECT_ID not found in secrets.config"
        exit 1
    fi
    
    print_success "Project ID: $PROJECT_ID"
    
    # Check if required scripts exist
    local required_scripts=("deploy-mfe1.sh" "deploy-mfe2.sh" "deploy-host.sh" "update-mfe-config.sh")
    
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$script" ]; then
            print_error "Required script not found: $script"
            exit 1
        fi
        
        if [ ! -x "$script" ]; then
            print_error "Script is not executable: $script"
            exit 1
        fi
    done
    
    print_success "All required scripts are available"
}

# Function to deploy MFEs
deploy_mfes() {
    print_step "Deploying MFEs..."
    
    echo ""
    print_status "=========================================="
    print_status "Deploying MFE1 (Product List)"
    print_status "=========================================="
    
    if ./deploy-mfe1.sh; then
        print_success "MFE1 deployment completed successfully"
    else
        print_error "MFE1 deployment failed"
        exit 1
    fi
    
    echo ""
    print_status "=========================================="
    print_status "Deploying MFE2 (User Profile)"
    print_status "=========================================="
    
    if ./deploy-mfe2.sh; then
        print_success "MFE2 deployment completed successfully"
    else
        print_error "MFE2 deployment failed"
        exit 1
    fi
    
    print_success "All MFEs deployed successfully!"
}

# Function to deploy host
deploy_host() {
    print_step "Deploying Host Application..."
    
    echo ""
    print_status "=========================================="
    print_status "Deploying Host Application"
    print_status "=========================================="
    
    if ./deploy-host.sh; then
        print_success "Host deployment completed successfully"
    else
        print_error "Host deployment failed"
        exit 1
    fi
}

# Function to update configuration only
update_config_only() {
    print_step "Updating MFE configuration..."
    
    if ./update-mfe-config.sh update; then
        print_success "MFE configuration updated successfully"
    else
        print_error "Failed to update MFE configuration"
        exit 1
    fi
}

# Function to show final status
show_final_status() {
    print_step "Deployment Summary"
    
    echo ""
    print_status "=========================================="
    print_status "Final Deployment Status"
    print_status "=========================================="
    
    # Load project configuration
    source ../secrets.config
    
    # Check service URLs
    local mfe1_url
    local mfe2_url
    local host_url
    
    mfe1_url=$(gcloud run services describe "mfe1-products" --platform managed --region "us-central1" --format 'value(status.url)' 2>/dev/null || echo "")
    mfe2_url=$(gcloud run services describe "mfe2-profile" --platform managed --region "us-central1" --format 'value(status.url)' 2>/dev/null || echo "")
    host_url=$(gcloud run services describe "host-app" --platform managed --region "us-central1" --format 'value(status.url)' 2>/dev/null || echo "")
    
    echo ""
    print_status "Deployed Services:"
    
    if [ -n "$mfe1_url" ]; then
        print_success "✓ MFE1 (Product List): $mfe1_url"
        print_status "  Remote Entry: $mfe1_url/assets/remoteEntry.js"
    else
        print_warning "✗ MFE1 (Product List): Not deployed"
    fi
    
    if [ -n "$mfe2_url" ]; then
        print_success "✓ MFE2 (User Profile): $mfe2_url"
        print_status "  Remote Entry: $mfe2_url/assets/remoteEntry.js"
    else
        print_warning "✗ MFE2 (User Profile): Not deployed"
    fi
    
    if [ -n "$host_url" ]; then
        print_success "✓ Host Application: $host_url"
        echo ""
        print_status "🎉 Your complete MFE application is ready!"
        print_status "Access your application at: $host_url"
        print_status "The host will automatically load MFE URLs from Cloud Storage."
    else
        print_warning "✗ Host Application: Not deployed"
    fi
    
    echo ""
    print_status "Configuration Storage:"
    local bucket_name="${PROJECT_ID}-mfe-config"
    print_status "Bucket: gs://$bucket_name"
    print_status "Config URL: https://storage.googleapis.com/$bucket_name/mfe-urls.json"
    
    echo ""
    print_status "=========================================="
}

# Main function
main() {
    local deploy_option="${1:-full}"
    
    case "$deploy_option" in
        "help"|"-h"|"--help")
            show_help
            exit 0
            ;;
        "full")
            echo "=========================================="
            echo "  Complete MFE Deployment"
            echo "  MFEs + Host + Configuration"
            echo "=========================================="
            echo ""
            
            check_prerequisites
            deploy_mfes
            deploy_host
            show_final_status
            ;;
        "mfes-only")
            echo "=========================================="
            echo "  MFE Deployment Only"
            echo "  MFE1 + MFE2 + Configuration Update"
            echo "=========================================="
            echo ""
            
            check_prerequisites
            deploy_mfes
            print_success "MFEs deployment completed!"
            ;;
        "host-only")
            echo "=========================================="
            echo "  Host Deployment Only"
            echo "=========================================="
            echo ""
            
            check_prerequisites
            deploy_host
            print_success "Host deployment completed!"
            ;;
        "config-only")
            echo "=========================================="
            echo "  Configuration Update Only"
            echo "=========================================="
            echo ""
            
            check_prerequisites
            update_config_only
            print_success "Configuration update completed!"
            ;;
        *)
            print_error "Unknown option: $deploy_option"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
