# React Micro Frontend Demo

A production-ready React micro frontend setup using Vite and `@originjs/vite-plugin-federation` with dynamic module loading and Cloud Run deployments.

## 🏗️ Architecture

This project demonstrates a true micro frontend architecture where each application is:
- **Independently deployable** to Google Cloud Run
- **Separately scalable** with its own container
- **Dynamically loadable** via URL configuration in the host app
- **Framework agnostic** - each MFE can use different React versions or libraries

## 📁 Project Structure

```
/
├── README.md                 # Comprehensive documentation
├── running_notes.md          # Local development notes
├── package.json              # Root dependencies and scripts
├── tsconfig.json             # Shared TypeScript config
├── deploy/                   # 🆕 All deployment files
│   ├── Dockerfile.host       # Host container
│   ├── Dockerfile.mfe1       # MFE1 container  
│   ├── Dockerfile.mfe2       # MFE2 container
│   ├── nginx.conf            # Nginx configuration
│   ├── deploy-host.sh        # Deploy host to Cloud Run
│   ├── deploy-mfe1.sh        # Deploy MFE1 to Cloud Run
│   ├── deploy-mfe2.sh        # Deploy MFE2 to Cloud Run
│   └── deploy-all.sh         # Deploy all services
├── host/                     # Host application (with dynamic MFE loading)
│   ├── vite.config.ts        # Federation configuration
│   ├── index.html
│   └── src/
│       ├── App.tsx           # Dynamic component loader with URL controls
│       └── components/
│           └── RemoteProductList.tsx
├── mfe1/                     # Product List micro frontend
│   ├── vite.config.ts        # Exposes ProductList component
│   ├── index.html
│   └── src/
│       ├── components/
│       │   └── ProductList.tsx
│       └── main.tsx
└── mfe2/                     # User Profile micro frontend
    ├── vite.config.ts        # Exposes UserProfile component
    ├── index.html
    └── src/
        ├── components/
        │   └── UserProfile.tsx
        └── main.tsx
```

## ✨ Features

### Host Application
- **Dynamic MFE Loading**: Load micro frontends from any URL at runtime
- **URL Configuration**: Input fields to specify remote entry URLs and module names
- **Fallback Handling**: Graceful error handling with detailed error messages
- **Local Development**: Defaults to localhost URLs for development
- **Module Federation**: Uses Vite's federation plugin for seamless integration

### Micro Frontends
- **Independent Deployment**: Each MFE deploys as a separate Cloud Run service
- **CORS Enabled**: Proper headers for cross-origin loading
- **Module Federation**: Exposes components via Vite module federation
- **Standalone Capable**: Each MFE can run independently for development and testing

## 🚀 Quick Start

### Prerequisites
```bash
npm install
```

### Recommended Development Workflow
Based on your running notes, here's the working approach:

```bash
# Step 1: Build the MFEs first
npm run build:mfes

# Step 2: Start MFEs in preview mode  
npm run preview:mfes

# Step 3: In another terminal, start the host
npm run dev:host
```

### One-Command Development
```bash
# This runs the complete workflow automatically
npm run dev
```

### Quick Start (if MFEs already built)
```bash
# If you've already built the MFEs and just want to restart
npm run dev:quick
```

### Why This Workflow?
- **MFEs need to to be built first**: Module federation requires the remote entry files to be generated
- **Preview mode works better**: `vite preview` serves the built federation files correctly
- **Host in dev mode**: The host can run in development mode for hot reloading of host-specific changes

### Individual Development
```bash
# Build individual MFEs
npm run build:mfe1
npm run build:mfe2

# Preview individual MFEs
npm run preview:mfe1  # http://localhost:3001
npm run preview:mfe2  # http://localhost:3002

# Develop host with hot reload
npm run dev:host      # http://localhost:3000
```

## 🔧 Technical Implementation

### Federation Configuration

The implementation uses Vite's federation plugin with direct federation method imports:

```typescript
// Direct import from federation runtime
import {
  __federation_method_getRemote,
  __federation_method_setRemote,
} from "__federation__";

// Dynamic component loading
const createDynamicComponent = (remoteUrl: string, scope: string, module: string) => {
  return React.lazy(async () => {
    // Set up the remote
    __federation_method_setRemote(scope, {
      url: () => Promise.resolve(remoteUrl),
      format: 'esm',
      from: 'vite'
    });
    
    // Load the module
    const result = await __federation_method_getRemote(scope, module);
    return result;
  });
};
```

### Key Benefits of This Approach

1. **No Manual Shared Scope**: Federation methods handle React sharing automatically
2. **Cleaner Code**: Minimal boilerplate compared to manual federation setup
3. **Better Performance**: Direct federation methods are more efficient
4. **Fewer Errors**: Eliminates common React hook and context issues
5. **Industry Standard**: Follows Vite federation best practices

### Vite Configuration

**Host Application (`host/vite.config.ts`)**:
```typescript
federation({
  name: 'host',
  remotes: {
    dummy: 'dummy.js' // Prevents build errors for dynamic loading
  },
  shared: ['react', 'react-dom']
})
```

**MFE Configuration (`mfe1/vite.config.ts`)**:
```typescript
federation({
  name: 'mfe1',
  filename: 'remoteEntry.js',
  exposes: {
    './ProductList': './src/components/ProductList.tsx'
  },
  shared: ['react', 'react-dom']
})
```

## ☁️ Cloud Deployment

### Prerequisites
1. **Google Cloud SDK**: Install and authenticate
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Docker**: Ensure Docker is running

### Deployment Options

#### Deploy All Services
```bash
cd deploy
./deploy-all.sh all
```

#### Deploy Individual Services
```bash
cd deploy
./deploy-mfe1.sh     # Deploy Product List MFE
./deploy-mfe2.sh     # Deploy User Profile MFE  
./deploy-host.sh     # Deploy Host Application
```

#### Interactive Deployment
```bash
cd deploy
./deploy-all.sh
# Select which service to deploy from the menu
```

### After Deployment

Each deployment provides:
- **Service URL**: Main application URL
- **Remote Entry URL**: `https://service-url/assets/remoteEntry.js`

Use the Remote Entry URLs in your host application's configuration panel.

## 🎯 Dynamic MFE Loading

The host application includes a configuration panel where you can:

1. **Enter Remote Entry URLs**: Input URLs for MFE remote entries
2. **Specify Module Names**: Define which module to load (e.g., `./ProductList`)
3. **Load MFEs**: Click "Load" to dynamically load from the specified URLs
4. **Reset to Local**: Return to localhost URLs for development
5. **Open MFE Apps**: Direct links to standalone MFE applications
6. **Error Handling**: Detailed error messages with fallback components

### Example URLs
- **Local Development**: `http://localhost:3001/assets/remoteEntry.js`
- **Cloud Run**: `https://mfe1-products-abc123.run.app/assets/remoteEntry.js`

## 🧹 Image Cleanup

### Cleanup Old Docker Images

As you deploy new versions, old Docker images accumulate in Google Container Registry. Use these scripts to clean up old images:

#### Basic Cleanup Script
```bash
cd deploy
./cleanup-images.sh
```

This script:
- Keeps the 2 most recent images for each service (mfe1-products, mfe2-profile, host-app)
- Shows what will be deleted before proceeding
- Asks for confirmation before deletion

#### Advanced Cleanup Script
```bash
cd deploy
./cleanup-images-advanced.sh [OPTIONS]
```

**Options:**
- `-k, --keep N`: Number of images to keep (default: 2)
- `-s, --service NAME`: Clean specific service only
- `-p, --project ID`: Use specific project ID
- `-y, --yes`: Auto-confirm deletions
- `-d, --dry-run`: Show what would be deleted without deleting
- `-h, --help`: Show help message

**Examples:**
```bash
# Keep 3 images per service
./cleanup-images-advanced.sh -k 3

# Clean only MFE1 service
./cleanup-images-advanced.sh -s mfe1-products

# Dry run to see what would be deleted
./cleanup-images-advanced.sh -d

# Keep 1 image per service, auto-confirm
./cleanup-images-advanced.sh -k 1 -y

# Clean specific service with specific project
./cleanup-images-advanced.sh -p my-project-id -s mfe1-products -k 1 -y
```

### Cost Optimization

Regular cleanup helps:
- **Reduce storage costs** in Google Container Registry
- **Improve performance** by reducing registry size
- **Maintain clean environment** for better management

**Recommended Schedule:**
- Run cleanup after every few deployments
- Set up automated cleanup in CI/CD pipeline
- Keep 2-3 recent images for rollback capability

## 🛠️ Use Cases

### Development Team Workflow
1. **Team A** develops and deploys MFE1 (Product List)
2. **Team B** develops and deploys MFE2 (User Profile)  
3. **Team C** configures the host to load from Team A and B's deployments
4. Each team can independently update and redeploy their MFE

### A/B Testing
- Deploy different versions of an MFE to different URLs
- Switch between versions by changing the URL in the host app
- No need to redeploy the host application

### Environment Management
- **Development**: Load from localhost
- **Staging**: Load from staging Cloud Run services
- **Production**: Load from production Cloud Run services

### Feature Flags
- Dynamically enable/disable features by switching MFE URLs
- Gradual rollouts by directing traffic to different MFE versions

## 🔍 Troubleshooting

### Common Issues

1. **404 on remoteEntry.js**
   - Ensure MFE is built and deployed properly
   - Check the remote entry URL is accessible directly

2. **CORS Errors**
   - Verify nginx configuration in Dockerfiles
   - Check Cloud Run service allows cross-origin requests

3. **Module not found**
   - Verify exposed module names in vite.config.ts
   - Ensure module path matches exactly (case-sensitive)

4. **React Hook Errors**
   - Check React versions are compatible
   - Ensure shared scope is configured correctly

5. **Authentication Issues**
   - Run `gcloud auth login` before deployment
   - Verify project ID is set correctly

### Debug Tips

- **Network Tab**: Check for failed requests to remote entries
- **Console Logs**: Look for federation-specific error messages
- **Direct Testing**: Access remote entry URLs directly in browser
- **Independent Testing**: Test each MFE standalone before integration

### Development Scripts

```bash
# Check if all services are running
npm run check:services

# Build all MFEs
npm run build:mfes

# Preview all MFEs
npm run preview:mfes

# Clean build artifacts
npm run clean
```

## 📊 Performance Considerations

- **Lazy Loading**: Components are loaded only when needed
- **Shared Dependencies**: React/ReactDOM shared across all MFEs
- **Build Optimization**: Vite's fast build and HMR
- **Caching**: Proper cache headers for remote entries
- **Error Boundaries**: Graceful handling of MFE failures

## 🔐 Security

- **CORS Configuration**: Properly configured for cross-origin requests
- **Content Security Policy**: Consider CSP headers for production
- **Remote Entry Validation**: Verify remote entry URLs before loading
- **Error Handling**: Don't expose sensitive information in error messages

## 🚀 Next Steps

### Enhancements
- Add authentication integration
- Implement state management across MFEs
- Add monitoring and logging
- Create CI/CD pipelines
- Add automated testing

### Scaling
- Implement CDN for remote entries
- Add load balancing
- Monitor performance metrics
- Implement caching strategies

This setup provides a solid foundation for a production-ready micro frontend architecture with dynamic loading capabilities! 🎉

--Examples
gcp
https://mfe1-products-ewt6e5d5pa-uc.a.run.app
https://mfe2-profile-ewt6e5d5pa-uc.a.run.app

## 🚀 Enhanced MFE Architecture

### New Features

#### 1. **Default `./main` Module Exposure**
Both MFEs now expose their main entry point via `./main` module:
- **MFE1**: Exposes both `./ProductList` and `./main` 
- **MFE2**: Exposes both `./UserProfile` and `./main`
- **Host**: Uses `./main` as the default module for dynamic loading

#### 2. **Automatic Cloud URL Discovery**
The host application automatically discovers MFE URLs from Google Cloud Storage:
- URLs are stored in a JSON configuration file in Cloud Storage
- Host application reads these URLs at runtime via `window.mfeUrls`
- Fallback to localhost URLs for development

#### 3. **Automated Deployment Pipeline**
Complete deployment automation with configuration management:
- MFE deployments automatically update Cloud Storage configuration
- Host deployment reads configuration and injects URLs into `index.html`
- Zero-configuration dynamic MFE loading

### Cloud Storage Integration

#### Configuration Management
```bash
# Update MFE configuration in Cloud Storage
./deploy/update-mfe-config.sh update

# View current configuration
./deploy/update-mfe-config.sh show

# Create storage bucket only
./deploy/update-mfe-config.sh create-bucket
```

#### Automatic URL Injection
The host application automatically receives MFE URLs through:
1. **Cloud Storage**: Downloads configuration from `gs://PROJECT_ID-mfe-config/mfe-urls.json`
2. **Runtime Injection**: URLs are injected into `window.mfeUrls` during container startup
3. **Dynamic Loading**: Host uses these URLs to load MFEs with `./main` module

#### Configuration Structure
```json
{
  "lastUpdated": "2025-07-12T15:58:02Z",
  "projectId": "your-project-id",
  "services": {
    "mfe1": {
      "name": "mfe1-products",
      "url": "https://mfe1-products-xyz.run.app",
      "remoteEntry": "https://mfe1-products-xyz.run.app/assets/remoteEntry.js",
      "status": "deployed"
    },
    "mfe2": {
      "name": "mfe2-profile",
      "url": "https://mfe2-profile-xyz.run.app", 
      "remoteEntry": "https://mfe2-profile-xyz.run.app/assets/remoteEntry.js",
      "status": "deployed"
    }
  },
  "mfeUrls": {
    "mfe1": "https://mfe1-products-xyz.run.app/assets/remoteEntry.js",
    "mfe2": "https://mfe2-profile-xyz.run.app/assets/remoteEntry.js"
  }
}
```

### Enhanced Deployment Scripts

#### Complete Deployment Workflow
```bash
cd deploy

# Full deployment (recommended)
./deploy-complete.sh

# Deploy only MFEs
./deploy-complete.sh mfes-only

# Deploy only host
./deploy-complete.sh host-only

# Update configuration only
./deploy-complete.sh config-only
```

#### Individual Deployments
```bash
# Deploy individual services (with auto-config update)
./deploy-mfe1.sh     # Deploys MFE1 + updates config
./deploy-mfe2.sh     # Deploys MFE2 + updates config  
./deploy-host.sh     # Deploys host + reads config
```

### Development Experience

#### Local Development
```bash
# Standard development workflow
npm run dev                    # Builds MFEs, starts preview, then host

# Using ./main modules locally
# Both MFEs now expose ./main alongside their specific components
# Host automatically uses ./main as default module
```

#### Cloud Development
```bash
# Deploy MFEs to cloud, develop host locally
./deploy-complete.sh mfes-only
npm run dev:host               # Host reads cloud URLs automatically
```

### Architecture Benefits

#### Zero-Configuration Loading
- **Development**: Host loads from localhost automatically
- **Cloud**: Host reads MFE URLs from Cloud Storage automatically  
- **No manual URL configuration needed**

#### Simplified Module Structure
- **Consistent Interface**: All MFEs expose `./main` 
- **Backward Compatible**: Original component exports still available
- **Easier Integration**: Standard entry point for all MFEs

#### Automated Configuration Management
- **Real-time Updates**: MFE deployments automatically update configuration
- **Public Access**: Configuration is publicly readable from Cloud Storage
- **Fallback Support**: Graceful fallback to localhost URLs

#### Enhanced Security & Permissions
- **Automatic Permissions**: Scripts handle Cloud Storage permissions automatically
- **Public Configuration**: MFE URLs are safely exposed for public access
- **Error Handling**: Graceful handling of permission and network issues