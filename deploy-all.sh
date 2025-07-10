#!/bin/bash

# Master deployment script for all micro frontends

echo "🚀 Micro Frontend Deployment Suite"
echo "===================================="
echo ""
echo "This script will deploy all micro frontend applications to GCP Cloud Run."
echo "Each application will be deployed as a separate service:"
echo ""
echo "1. MFE1 (Product List) - Standalone micro frontend"
echo "2. MFE2 (User Profile) - Standalone micro frontend"  
echo "3. Host Application - Main application that loads remote MFEs"
echo ""

# Function to make scripts executable
make_executable() {
    chmod +x deploy-mfe1.sh
    chmod +x deploy-mfe2.sh
    chmod +x deploy-host.sh
    echo "✓ Made deployment scripts executable"
}

# Function to deploy all services
deploy_all() {
    echo "Starting deployment of all services..."
    echo ""
    
    echo "📦 Deploying MFE1 (Product List)..."
    echo "===================================="
    ./deploy-mfe1.sh
    if [ $? -ne 0 ]; then
        echo "❌ MFE1 deployment failed!"
        exit 1
    fi
    
    echo ""
    echo "👤 Deploying MFE2 (User Profile)..."
    echo "===================================="
    ./deploy-mfe2.sh
    if [ $? -ne 0 ]; then
        echo "❌ MFE2 deployment failed!"
        exit 1
    fi
    
    echo ""
    echo "🏠 Deploying Host Application..."
    echo "================================"
    ./deploy-host.sh
    if [ $? -ne 0 ]; then
        echo "❌ Host deployment failed!"
        exit 1
    fi
}

# Function to deploy individual service
deploy_individual() {
    echo "Select which service to deploy:"
    echo "1) MFE1 (Product List)"
    echo "2) MFE2 (User Profile)"
    echo "3) Host Application"
    echo "4) Deploy All"
    echo ""
    echo "Enter your choice (1-4):"
    read -r CHOICE
    
    case $CHOICE in
        1)
            echo "Deploying MFE1 (Product List)..."
            ./deploy-mfe1.sh
            ;;
        2)
            echo "Deploying MFE2 (User Profile)..."
            ./deploy-mfe2.sh
            ;;
        3)
            echo "Deploying Host Application..."
            ./deploy-host.sh
            ;;
        4)
            deploy_all
            ;;
        *)
            echo "Invalid choice. Please enter 1-4."
            exit 1
            ;;
    esac
}

# Check if running scripts exist
if [ ! -f "deploy-mfe1.sh" ] || [ ! -f "deploy-mfe2.sh" ] || [ ! -f "deploy-host.sh" ]; then
    echo "❌ One or more deployment scripts are missing!"
    echo "Please ensure all deployment scripts are in the current directory."
    exit 1
fi

# Make scripts executable
make_executable

# Check for command line argument
if [ "$1" = "all" ]; then
    deploy_all
else
    deploy_individual
fi

echo ""
echo "🎉 Deployment process completed!"
echo ""
echo "📋 Next Steps:"
echo "=============="
echo "1. Note down the URLs provided by each deployment"
echo "2. Use the Remote Entry URLs in your host application"
echo "3. Test the deployed applications"
echo ""
echo "💡 Tips:"
echo "- MFE Remote Entry URLs: https://your-service-url.com/assets/remoteEntry.js"
echo "- You can update the host application to load MFEs from these URLs"
echo "- Each service is independently scalable and deployable"
