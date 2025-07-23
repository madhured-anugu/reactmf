#!/bin/bash

# Single-SPA Micro-Frontend Startup Script
# This script installs dependencies and starts all applications

echo "🚀 Starting Single-SPA Micro-Frontend Demo..."
echo "=================================================="

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if Node.js is installed
check_node() {
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js is not installed. Please install Node.js first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Node.js found: $(node --version)${NC}"
}

# Function to install dependencies
install_dependencies() {
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    
    echo -e "${BLUE}Installing root-config dependencies...${NC}"
    cd root-config && npm install
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to install root-config dependencies${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Installing product-list dependencies...${NC}"
    cd ../product-list && npm install  
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to install product-list dependencies${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Installing user-profile dependencies...${NC}"
    cd ../user-profile && npm install
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to install user-profile dependencies${NC}"
        exit 1
    fi
    
    cd ..
    echo -e "${GREEN}✅ All dependencies installed successfully!${NC}"
}

# Function to start applications
start_applications() {
    echo -e "${YELLOW}🌟 Starting all applications...${NC}"
    echo -e "${BLUE}This will open 3 terminal windows/tabs:${NC}"
    echo -e "  • Root Config (Port 9000)"
    echo -e "  • Product List MFE (Port 8080)" 
    echo -e "  • User Profile MFE (Port 8081)"
    echo ""
    
    # Check if we're on macOS, Linux, or Windows
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo -e "${BLUE}Opening Terminal tabs on macOS...${NC}"
        
        # Start root-config
        osascript -e "tell application \"Terminal\" to do script \"cd '$(pwd)/root-config' && echo '🎯 Starting Root Config (Port 9000)...' && npm start\""
        
        # Start product-list  
        osascript -e "tell application \"Terminal\" to do script \"cd '$(pwd)/product-list' && echo '🛍️ Starting Product List MFE (Port 8080)...' && npm start\""
        
        # Start user-profile
        osascript -e "tell application \"Terminal\" to do script \"cd '$(pwd)/user-profile' && echo '👤 Starting User Profile MFE (Port 8081)...' && npm start\""
        
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        echo -e "${BLUE}Opening terminal windows on Linux...${NC}"
        
        # Try gnome-terminal first, then xterm
        if command -v gnome-terminal &> /dev/null; then
            gnome-terminal --tab --title="Root Config" -- bash -c "cd '$(pwd)/root-config' && echo '🎯 Starting Root Config (Port 9000)...' && npm start; exec bash"
            gnome-terminal --tab --title="Product List" -- bash -c "cd '$(pwd)/product-list' && echo '🛍️ Starting Product List MFE (Port 8080)...' && npm start; exec bash"  
            gnome-terminal --tab --title="User Profile" -- bash -c "cd '$(pwd)/user-profile' && echo '👤 Starting User Profile MFE (Port 8081)...' && npm start; exec bash"
        elif command -v xterm &> /dev/null; then
            xterm -e "cd '$(pwd)/root-config' && echo '🎯 Starting Root Config (Port 9000)...' && npm start" &
            xterm -e "cd '$(pwd)/product-list' && echo '🛍️ Starting Product List MFE (Port 8080)...' && npm start" &
            xterm -e "cd '$(pwd)/user-profile' && echo '👤 Starting User Profile MFE (Port 8081)...' && npm start" &
        else
            echo -e "${RED}❌ No suitable terminal emulator found. Please install gnome-terminal or xterm.${NC}"
            echo -e "${YELLOW}Manual startup required:${NC}"
            echo -e "  Terminal 1: cd root-config && npm start"
            echo -e "  Terminal 2: cd product-list && npm start"
            echo -e "  Terminal 3: cd user-profile && npm start"
            exit 1
        fi
        
    else
        # Windows or others - provide manual instructions
        echo -e "${YELLOW}⚠️ Automatic terminal opening not supported on this platform.${NC}"
        echo -e "${BLUE}Please run these commands in separate terminals:${NC}"
        echo ""
        echo -e "${YELLOW}Terminal 1 (Root Config):${NC}"
        echo -e "  cd root-config && npm start"
        echo ""
        echo -e "${YELLOW}Terminal 2 (Product List MFE):${NC}" 
        echo -e "  cd product-list && npm start"
        echo ""
        echo -e "${YELLOW}Terminal 3 (User Profile MFE):${NC}"
        echo -e "  cd user-profile && npm start"
        echo ""
        return
    fi
    
    echo ""
    echo -e "${GREEN}✅ Applications are starting...${NC}"
}

# Function to show completion message
show_completion() {
    echo ""
    echo -e "${GREEN}🎉 Single-SPA Demo is starting up!${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo -e "${YELLOW}📱 Applications:${NC}"
    echo -e "  • Root Config:    ${BLUE}http://localhost:9000${NC}"
    echo -e "  • Product List:   ${BLUE}http://localhost:8080${NC}" 
    echo -e "  • User Profile:   ${BLUE}http://localhost:8081${NC}"
    echo ""
    echo -e "${YELLOW}⏱️ Please wait 30-60 seconds for all services to start...${NC}"
    echo -e "${GREEN}🌐 Then open: ${BLUE}http://localhost:9000${NC}"
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo -e "  • Press Ctrl+C in each terminal to stop services"
    echo -e "  • Check browser console for any errors"
    echo -e "  • Each MFE can also run independently"
    echo -e "${BLUE}================================================${NC}"
}

# Main execution
main() {
    check_node
    install_dependencies
    start_applications
    show_completion
}

# Run main function
main
