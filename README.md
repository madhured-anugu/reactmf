# React Micro Frontend Demo

A proof-of-concept React micro frontend setup using Vite and `@originjs/vite-plugin-federation` with separate Cloud Run deployments.

## Architecture

This project demonstrates a true micro frontend architecture where each application is:
- **Independently deployable** to Google Cloud Run
- **Separately scalable** with its own container
- **Dynamically loadable** via URL configuration in the host app

## Structure

```
/
├── package.json              # Root dependencies and scripts
├── tsconfig.json             # Shared TypeScript config
├── Dockerfile.host           # Host application container
├── Dockerfile.mfe1           # MFE1 container
├── Dockerfile.mfe2           # MFE2 container
├── deploy-host.sh            # Deploy host to Cloud Run
├── deploy-mfe1.sh            # Deploy MFE1 to Cloud Run
├── deploy-mfe2.sh            # Deploy MFE2 to Cloud Run
├── deploy-all.sh             # Deploy all services
├── host/                     # Host application (with dynamic MFE loading)
│   ├── vite.config.ts
│   ├── index.html
│   └── src/
│       ├── App.tsx           # Dynamic component loader with URL controls
│       └── ...
├── mfe1/                     # Product List micro frontend
│   ├── vite.config.ts        # Exposes ProductList component
│   ├── index.html
│   └── src/
│       ├── components/
│       │   └── ProductList.tsx
│       └── ...
└── mfe2/                     # User Profile micro frontend
    ├── vite.config.ts        # Exposes UserProfile component
    ├── index.html
    └── src/
        ├── components/
        │   └── UserProfile.tsx
        └── ...
```

## Features

### Host Application
- **Dynamic MFE Loading**: Load micro frontends from any URL
- **URL Configuration**: Input fields to specify remote entry URLs
- **Fallback Handling**: Graceful error handling for failed loads
- **Local Development**: Defaults to localhost URLs for development

### Micro Frontends
- **Independent Deployment**: Each MFE deploys as a separate Cloud Run service
- **CORS Enabled**: Proper headers for cross-origin loading
- **Module Federation**: Exposes components via webpack module federation
- **Standalone Capable**: Each MFE can run independently for development

## Local Development

### Prerequisites
```bash
npm install
```

### Option 1: Development Mode
For active development with hot-reload:

```bash
# Terminal 1: Start MFE1
npm run dev:mfe1

# Terminal 2: Start MFE2  
npm run dev:mfe2

# Terminal 3: Start Host
npm run dev:host
```

### Option 2: Production-Like Mode
For testing module federation (recommended):

```bash
# Build MFEs first
npm run build:mfes

# Start MFEs in preview mode
npm run preview:mfes

# Start host in dev mode
npm run dev:host
```

### Option 3: Quick Start
```bash
npm run dev:quick  # If MFEs already built
```

## Cloud Deployment

### Prerequisites
1. **Google Cloud SDK**: Install and authenticate
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Docker**: Ensure Docker is running

### Deployment Options

#### Option 1: Deploy All Services
```bash
./deploy-all.sh all
```

#### Option 2: Deploy Individual Services
```bash
./deploy-all.sh
# Then select which service to deploy
```

#### Option 3: Deploy Specific Service
```bash
./deploy-mfe1.sh     # Deploy Product List MFE
./deploy-mfe2.sh     # Deploy User Profile MFE  
./deploy-host.sh     # Deploy Host Application
```

### After Deployment

Each deployment will provide:
- **Service URL**: Main application URL
- **Remote Entry URL**: `https://service-url/assets/remoteEntry.js`

Use the Remote Entry URLs in your host application's URL configuration fields.

## Dynamic MFE Loading

The host application includes a configuration panel where you can:

1. **Enter Remote Entry URLs**: Input URLs for MFE1 and MFE2
2. **Load MFEs**: Click "Load" to dynamically load from the specified URLs
3. **Reset to Local**: Return to localhost URLs for development
4. **Error Handling**: See detailed error messages if loading fails

### Example URLs
- **Local**: `http://localhost:3001/assets/remoteEntry.js`
- **Cloud Run**: `https://mfe1-products-abc123.run.app/assets/remoteEntry.js`

## Use Cases

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

## Technical Details

- **Vite**: Fast development server and build tool
- **Module Federation**: Runtime loading of remote components
- **Docker**: Containerized deployments with nginx
- **Google Cloud Run**: Serverless container platform
- **CORS**: Proper cross-origin resource sharing configuration

## Troubleshooting

### Common Issues

1. **404 on remoteEntry.js**: Ensure MFE is built and deployed properly
2. **CORS Errors**: Check nginx configuration in Dockerfiles
3. **Module not found**: Verify exposed module names in vite.config.ts
4. **Authentication**: Run `gcloud auth login` before deployment

### Debug Tips

- Check browser network tab for failed requests
- Use browser console for module federation errors
- Verify remote entry URLs are accessible directly
- Test MFEs individually before integration
