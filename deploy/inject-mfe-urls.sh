#!/bin/sh

# Script to inject MFE URLs into index.html before starting nginx
# This runs inside the Docker container at startup

set -e

echo "Starting MFE URL injection process..."

# Configuration
PROJECT_ID="${PROJECT_ID:-}"
BUCKET_NAME="${PROJECT_ID}-mfe-config"
CONFIG_FILE="mfe-urls.json"
INDEX_FILE="/usr/share/nginx/html/index.html"
BACKUP_FILE="/usr/share/nginx/html/index.html.backup"

# Create backup of original index.html
if [ ! -f "$BACKUP_FILE" ]; then
    cp "$INDEX_FILE" "$BACKUP_FILE"
    echo "Created backup of index.html"
fi

# Function to get MFE URLs from environment or Cloud Storage
get_mfe_urls() {
    # If URLs are provided via environment variables, use them
    if [ -n "$MFE1_URL" ] && [ -n "$MFE2_URL" ]; then
        echo "Using MFE URLs from environment variables"
        cat > /tmp/mfe-urls.json << EOF
{
  "mfe1": "$MFE1_URL",
  "mfe2": "$MFE2_URL"
}
EOF
        return 0
    fi
    
    # Try to download from Cloud Storage
    if [ -n "$PROJECT_ID" ]; then
        echo "Attempting to download MFE configuration from Cloud Storage..."
        echo "PROJECT_ID: $PROJECT_ID"
        echo "Bucket: $BUCKET_NAME"
        echo "Config file: $CONFIG_FILE"
        
        # Try to download the config file
        DOWNLOAD_URL="https://storage.googleapis.com/$BUCKET_NAME/$CONFIG_FILE"
        echo "Download URL: $DOWNLOAD_URL"
        
        # Try curl first (more commonly available)
        if command -v curl > /dev/null 2>&1; then
            echo "Using curl to download..."
            if curl -s -o /tmp/full-config.json "$DOWNLOAD_URL"; then
                echo "Downloaded MFE configuration from Cloud Storage with curl"
                echo "Downloaded content:"
                cat /tmp/full-config.json
                
                # Extract just the mfeUrls part
                if command -v jq > /dev/null 2>&1; then
                    echo "Using jq to extract mfeUrls"
                    jq '.mfeUrls' /tmp/full-config.json > /tmp/mfe-urls.json 2>/dev/null || {
                        echo "Failed to parse JSON with jq, using fallback"
                        create_fallback_config
                    }
                else
                    echo "jq not available, extracting URLs manually"
                    # Manual extraction for environments without jq
                    # Extract the mfeUrls section
                    grep -A 10 '"mfeUrls"' /tmp/full-config.json | \
                    sed -n '/{/,/}/p' | \
                    sed '1d;$d' | \
                    sed 's/^[[:space:]]*//' | \
                    sed '1i{' | \
                    sed '$ a}' > /tmp/mfe-urls.json || create_fallback_config
                fi
                
                # Verify the file was created and is valid
                if [ -s /tmp/mfe-urls.json ]; then
                    echo "Successfully extracted MFE URLs:"
                    cat /tmp/mfe-urls.json
                    return 0
                else
                    echo "Failed to extract MFE URLs, file is empty"
                fi
            else
                echo "Failed to download from Cloud Storage with curl"
            fi
        elif command -v wget > /dev/null 2>&1; then
            echo "Using wget to download..."
            if wget -q -O /tmp/full-config.json "$DOWNLOAD_URL"; then
                echo "Downloaded MFE configuration from Cloud Storage with wget"
                echo "Downloaded content:"
                cat /tmp/full-config.json
                
                # Extract just the mfeUrls part
                if command -v jq > /dev/null 2>&1; then
                    echo "Using jq to extract mfeUrls"
                    jq '.mfeUrls' /tmp/full-config.json > /tmp/mfe-urls.json 2>/dev/null || {
                        echo "Failed to parse JSON with jq, using fallback"
                        create_fallback_config
                    }
                else
                    echo "jq not available, extracting URLs manually"
                    # Manual extraction for environments without jq
                    # Extract the mfeUrls section
                    grep -A 10 '"mfeUrls"' /tmp/full-config.json | \
                    sed -n '/{/,/}/p' | \
                    sed '1d;$d' | \
                    sed 's/^[[:space:]]*//' | \
                    sed '1i{' | \
                    sed '$ a}' > /tmp/mfe-urls.json || create_fallback_config
                fi
                
                # Verify the file was created and is valid
                if [ -s /tmp/mfe-urls.json ]; then
                    echo "Successfully extracted MFE URLs:"
                    cat /tmp/mfe-urls.json
                    return 0
                else
                    echo "Failed to extract MFE URLs, file is empty"
                fi
            else
                echo "Failed to download from Cloud Storage with wget"
            fi
        else
            echo "Neither curl nor wget available"
        fi
    else
        echo "PROJECT_ID not set, cannot download from Cloud Storage"
    fi
    
    # Fallback to localhost URLs
    echo "Using fallback localhost URLs"
    create_fallback_config
}

# Function to create fallback configuration
create_fallback_config() {
    cat > /tmp/mfe-urls.json << EOF
{
  "mfe1": "http://localhost:3001/assets/remoteEntry.js",
  "mfe2": "http://localhost:3002/assets/remoteEntry.js"
}
EOF
}

# Function to inject URLs into index.html
inject_urls_into_html() {
    echo "Injecting MFE URLs into index.html..."
    
    # Read the MFE URLs
    if [ ! -f /tmp/mfe-urls.json ]; then
        echo "No MFE URLs file found, creating fallback"
        create_fallback_config
    fi
    
    # Read the URLs from the JSON file
    MFE_URLS_JSON=$(cat /tmp/mfe-urls.json)
    
    # Create the injection script
    INJECTION_SCRIPT="<script>window.mfeUrls = $MFE_URLS_JSON;</script>"
    
    # Use a more robust method to inject the script
    # First, copy the backup file
    cp "$BACKUP_FILE" "$INDEX_FILE"
    
    # Create a temporary file with the injection script
    echo "$INJECTION_SCRIPT" > /tmp/injection.txt
    
    # Use awk to inject the script before </head>
    awk '
        /<\/head>/ {
            # Read and print the injection script
            while ((getline line < "/tmp/injection.txt") > 0) {
                print "  " line
            }
            close("/tmp/injection.txt")
        }
        { print }
    ' "$BACKUP_FILE" > "$INDEX_FILE"
    
    echo "Successfully injected MFE URLs into index.html"
    echo "Injected: $INJECTION_SCRIPT"
}

# Function to show final configuration
show_final_config() {
    echo "=========================================="
    echo "Final Host Configuration:"
    echo "PROJECT_ID: ${PROJECT_ID:-'Not set'}"
    echo "MFE URLs:"
    if [ -f /tmp/mfe-urls.json ]; then
        cat /tmp/mfe-urls.json
    else
        echo "No MFE URLs available"
    fi
    echo "=========================================="
}

# Main execution
main() {
    echo "=========================================="
    echo "Host Container Startup"
    echo "=========================================="
    
    # Get MFE URLs
    get_mfe_urls
    
    # Inject URLs into HTML
    inject_urls_into_html
    
    # Show final configuration
    show_final_config
    
    # Clean up temp files
    rm -f /tmp/mfe-urls.json /tmp/full-config.json
    
    echo "Starting nginx..."
    exec nginx -g "daemon off;"
}

# Run main function
main "$@"
