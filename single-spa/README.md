# Single-SPA Micro-Frontend Demo

This is a demonstration of micro-frontend architecture using Single-SPA framework. It includes a root config application and two micro-frontends: Product List and User Profile.

## Architecture Overview

```
┌─────────────────────────────────────────┐
│            Root Config                  │
│         (Port 9000)                     │
│    ┌─────────────────────────────────┐  │
│    │       Single-SPA Router         │  │
│    └─────────────────────────────────┘  │
└─────────────────────────────────────────┘
              │           │
              ▼           ▼
┌─────────────────┐  ┌──────────────────┐
│  Product List   │  │  User Profile    │
│   MFE (8080)    │  │   MFE (8081)     │
│                 │  │                  │
│ • Product Cards │  │ • User Stats     │
│ • Shopping Cart │  │ • Preferences    │
│ • Category      │  │ • Activity Log   │
└─────────────────┘  └──────────────────┘
```

## Features

### Root Config (Port 9000)
- **Single-SPA Router**: Orchestrates micro-frontends
- **Modern UI**: Beautiful gradient design with responsive layout
- **Error Boundaries**: Graceful error handling for each MFE
- **SystemJS**: Dynamic module loading
- **Development/Production**: Different configurations for local and production

### Product List MFE (Port 8080)
- **Product Grid**: Responsive card layout
- **Product Information**: Name, price, category, description
- **Interactive Cards**: Hover effects and animations
- **Add to Cart**: Button interactions
- **Loading States**: Spinner while loading data

### User Profile MFE (Port 8081)
- **User Dashboard**: Profile header with avatar and info
- **Tabbed Interface**: Stats, Settings, and Activity tabs
- **Statistics**: Orders, wishlist, and reviews count
- **Preferences**: Toggle switches for notifications and settings
- **Activity Log**: Recent user actions and timestamps

## Technology Stack

- **Framework**: Single-SPA
- **Frontend**: React 18 with Hooks
- **Build Tool**: Webpack 5
- **Module System**: SystemJS
- **CSS**: Custom responsive styles
- **Development**: Hot module replacement

## Quick Start

### Prerequisites
- Node.js (v16 or higher)
- npm or yarn

### Installation & Running

1. **Install all dependencies**:
   ```bash
   # From the single-spa directory
   cd root-config && npm install
   cd ../product-list && npm install  
   cd ../user-profile && npm install
   cd ..
   ```

2. **Start all applications** (run in separate terminals):
   ```bash
   # Terminal 1: Root Config
   cd root-config && npm start
   
   # Terminal 2: Product List MFE
   cd product-list && npm start
   
   # Terminal 3: User Profile MFE  
   cd user-profile && npm start
   ```

3. **Open your browser**:
   - Main Application: http://localhost:9000
   - Product List MFE: http://localhost:8080 (standalone)
   - User Profile MFE: http://localhost:8081 (standalone)

### Quick Start Script

For convenience, you can use the startup script:

```bash
chmod +x start-all.sh
./start-all.sh
```

## Project Structure

```
single-spa/
├── README.md
├── start-all.sh                 # Quick start script
├── root-config/                 # Main orchestrator app
│   ├── package.json
│   ├── webpack.config.js
│   ├── .babelrc
│   └── src/
│       ├── index.ejs           # HTML template with SystemJS
│       └── index.js            # Single-SPA configuration
├── product-list/               # Product MFE
│   ├── package.json
│   ├── webpack.config.js
│   ├── .babelrc
│   └── src/
│       ├── index.js           # Single-SPA React lifecycle
│       ├── ProductList.js     # React component
│       └── ProductList.css    # Styles
└── user-profile/              # User MFE
    ├── package.json
    ├── webpack.config.js
    ├── .babelrc
    └── src/
        ├── index.js          # Single-SPA React lifecycle
        ├── UserProfile.js    # React component
        └── UserProfile.css   # Styles
```

## Key Single-SPA Concepts

### 1. Root Config
The root config is responsible for:
- Registering micro-frontends
- Defining when each MFE should be active
- Managing the import map for module resolution

### 2. Micro-frontend Registration
```javascript
registerApplication({
  name: '@reactmf/product-list',
  app: () => System.import('@reactmf/product-list'),
  activeWhen: () => true,
  customProps: {
    domElement: document.getElementById('product-list-mfe'),
  }
});
```

### 3. Single-SPA React Integration
Each MFE uses `single-spa-react` to provide lifecycle methods:
```javascript
const lifecycles = singleSpaReact({
  React,
  ReactDOM,
  rootComponent: ProductList,
  errorBoundary: ErrorComponent,
});

export const { bootstrap, mount, unmount } = lifecycles;
```

### 4. SystemJS Import Maps
Module resolution is handled via import maps:
```javascript
{
  "imports": {
    "@reactmf/product-list": "//localhost:8080/reactmf-product-list.js",
    "@reactmf/user-profile": "//localhost:8081/reactmf-user-profile.js",
    "react": "https://cdn.jsdelivr.net/npm/react@18.2.0/umd/react.development.js"
  }
}
```

## Development Features

- **Hot Reload**: All applications support hot module replacement
- **Independent Development**: Each MFE can be developed and tested independently
- **Shared Dependencies**: React and React-DOM are shared across MFEs
- **CORS Enabled**: Proper CORS configuration for cross-origin requests
- **Error Boundaries**: Each MFE has error boundaries for isolation

## Production Build

To build for production:

```bash
# Build all applications
cd root-config && npm run build
cd ../product-list && npm run build  
cd ../user-profile && npm run build
```

## Comparison with Module Federation

| Feature | Single-SPA | Module Federation |
|---------|------------|-------------------|
| **Runtime** | SystemJS | Webpack Runtime |
| **Framework Agnostic** | ✅ Yes | ❌ Webpack only |
| **Shared Dependencies** | External CDN | Webpack sharing |
| **Bundle Size** | Smaller | Larger |
| **Setup Complexity** | Moderate | Simple |
| **Hot Reload** | Limited | Full support |

## Best Practices

1. **Keep MFEs Independent**: Minimal coupling between micro-frontends
2. **Shared State Management**: Use events or shared libraries for communication
3. **Error Isolation**: Implement proper error boundaries
4. **Performance**: Lazy load MFEs when needed
5. **Testing**: Test each MFE independently and integration testing for the shell

## Troubleshooting

### Common Issues:

1. **CORS Errors**: Ensure all dev servers have CORS enabled
2. **Module Not Found**: Check import map URLs and ensure services are running
3. **React Version Conflicts**: Ensure all MFEs use the same React version
4. **SystemJS Errors**: Check browser console for import map resolution issues

### Debug Mode:
Add this to your browser console to enable SystemJS debugging:
```javascript
System.trace = true;
```

## Next Steps

- Add routing with `single-spa-routing`
- Implement shared state management
- Add authentication/authorization
- Create CI/CD pipeline
- Add E2E testing with Cypress
- Implement lazy loading strategies
