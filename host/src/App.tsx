import React, { Suspense, useState, useEffect } from 'react'
import './App.css'

// Import federation methods directly (better approach)
import {
  __federation_method_getRemote,
  __federation_method_setRemote,
  // @ts-ignore
} from "__federation__";

interface MFEConfig {
  name: string
  url: string
  module: string
  displayName: string
}

const DEFAULT_MFES: MFEConfig[] = [
  {
    name: 'mfe1',
    url: 'http://localhost:3001/assets/remoteEntry.js',
    module: './ProductList',
    displayName: 'Product List (Local)'
  },
  {
    name: 'mfe2',
    url: 'http://localhost:3002/assets/remoteEntry.js',
    module: './UserProfile',
    displayName: 'User Profile (Local)'
  }
]

// Simplified dynamic component creation using federation methods
const createDynamicComponent = (remoteUrl: string, scope: string, module: string) => {
  console.log(`Creating dynamic component for ${module} from ${remoteUrl}`);
  
  return React.lazy(async () => {
    try {
      console.log(`React.lazy is executing for ${module} from ${remoteUrl}`);
      
      // Set up the remote using federation methods
      __federation_method_setRemote(scope, {
        url: () => Promise.resolve(remoteUrl),
        format: 'esm',
        from: 'vite'
      });
      
      // Get the remote module directly - federation methods return the correct format
      const result = await __federation_method_getRemote(scope, module);
      console.log(`Successfully loaded component ${module}`, result);
      
      // Return the result directly - federation methods handle the module structure
      return result;
    } catch (error) {
      console.error(`Failed to load remote component from ${remoteUrl}:`, error);
      // Return fallback component
      return {
        default: () => (
          <div className="error-fallback">
            <h3>⚠️ Failed to load remote component</h3>
            <p>URL: {remoteUrl}</p>
            <p>Module: {module}</p>
            <p>Error: {(error as Error).message}</p>
          </div>
        )
      };
    }
  });
};

function App() {
  const [customUrls, setCustomUrls] = useState({
    mfe1: '',
    mfe2: ''
  })
  
  const [customModules, setCustomModules] = useState({
    mfe1: '',
    mfe2: ''
  })
  
  const [loadedComponents, setLoadedComponents] = useState<{[key: string]: React.ComponentType}>({})

  const handleUrlChange = (mfeKey: 'mfe1' | 'mfe2', url: string) => {
    setCustomUrls(prev => ({ ...prev, [mfeKey]: url }))
  }

  const handleModuleChange = (mfeKey: 'mfe1' | 'mfe2', module: string) => {
    setCustomModules(prev => ({ ...prev, [mfeKey]: module }))
  }

  const loadMFE = async (mfeKey: 'mfe1' | 'mfe2') => {
    const url = customUrls[mfeKey].trim()
    if (!url) return
    
    try {
      const defaultModule = mfeKey === 'mfe1' ? './ProductList' : './UserProfile'
      const module = customModules[mfeKey].trim() || defaultModule
      const Component = createDynamicComponent(url, mfeKey, module)
      setLoadedComponents(prev => ({ ...prev, [mfeKey]: Component }))
    } catch (error) {
      console.error(`Failed to load ${mfeKey}:`, error)
    }
  }

  const resetToDefault = (mfeKey: 'mfe1' | 'mfe2') => {
    const defaultConfig = DEFAULT_MFES.find(mfe => mfe.name === mfeKey)
    if (defaultConfig) {
      setCustomUrls(prev => ({ ...prev, [mfeKey]: defaultConfig.url }))
      setCustomModules(prev => ({ ...prev, [mfeKey]: '' }))
      
      try {
        const Component = createDynamicComponent(defaultConfig.url, defaultConfig.name, defaultConfig.module)
        setLoadedComponents(prev => ({ ...prev, [mfeKey]: Component }))
      } catch (error) {
        console.error(`Failed to load default ${mfeKey}:`, error)
      }
    }
  }

  const extractBaseUrl = (remoteEntryUrl: string): string => {
    try {
      const url = new URL(remoteEntryUrl)
      return `${url.protocol}//${url.host}`
    } catch (error) {
      console.error('Invalid URL:', remoteEntryUrl)
      return ''
    }
  }

  const openMFEApp = (mfeKey: 'mfe1' | 'mfe2') => {
    const customUrl = customUrls[mfeKey].trim()
    const defaultConfig = DEFAULT_MFES.find(mfe => mfe.name === mfeKey)
    const url = customUrl || (defaultConfig ? defaultConfig.url : '')
    
    if (!url) return

    const baseUrl = extractBaseUrl(url)
    if (baseUrl) {
      window.open(baseUrl, '_blank')
    }
  }

  // Load default components on mount
  useEffect(() => {
    console.log('Loading default MFEs...');
    DEFAULT_MFES.forEach(config => {
      console.log(`Creating component for ${config.name}: ${config.url} -> ${config.module}`);
      try {
        const Component = createDynamicComponent(config.url, config.name, config.module)
        setLoadedComponents(prev => ({ ...prev, [config.name]: Component }))
        console.log(`Added ${config.name} to loaded components`);
      } catch (error) {
        console.error(`Failed to load default ${config.name}:`, error)
      }
    })
    
    // Initialize custom modules with empty values
    setCustomModules({
      mfe1: '',
      mfe2: ''
    })
  }, [])

  const MFE1Component = loadedComponents.mfe1 || (() => <div className="loading">Loading MFE1...</div>)
  const MFE2Component = loadedComponents.mfe2 || (() => <div className="loading">Loading MFE2...</div>)

  return (
    <div className="App">
      <header className="App-header">
        <h1>🏠 Host Application</h1>
        <p>Micro Frontend Demo with Dynamic Loading</p>
      </header>

      <div className="mfe-controls">
        <div className="control-section">
          <h3>🔧 MFE Configuration</h3>
          <div className="url-controls">
            <div className="url-input-group">
              <label>📦 MFE1 (Product List) URL:</label>
              <input
                type="text"
                value={customUrls.mfe1}
                onChange={(e) => handleUrlChange('mfe1', e.target.value)}
                placeholder="https://your-mfe1-url.com/assets/remoteEntry.js"
                className="url-input"
              />
              <label>Module Name:</label>
              <input
                type="text"
                value={customModules.mfe1}
                onChange={(e) => handleModuleChange('mfe1', e.target.value)}
                placeholder="./ProductList (default)"
                className="url-input"
              />
              <div className="button-group">
                <button onClick={() => loadMFE('mfe1')} className="load-btn">
                  Load MFE1
                </button>
                <button onClick={() => resetToDefault('mfe1')} className="reset-btn">
                  Reset to Local
                </button>
                {(customUrls.mfe1 || DEFAULT_MFES[0].url) && (
                  <button onClick={() => openMFEApp('mfe1')} className="open-btn">
                    🔗 Open App
                  </button>
                )}
              </div>
            </div>

            <div className="url-input-group">
              <label>👤 MFE2 (User Profile) URL:</label>
              <input
                type="text"
                value={customUrls.mfe2}
                onChange={(e) => handleUrlChange('mfe2', e.target.value)}
                placeholder="https://your-mfe2-url.com/assets/remoteEntry.js"
                className="url-input"
              />
              <label>Module Name:</label>
              <input
                type="text"
                value={customModules.mfe2}
                onChange={(e) => handleModuleChange('mfe2', e.target.value)}
                placeholder="./UserProfile (default)"
                className="url-input"
              />
              <div className="button-group">
                <button onClick={() => loadMFE('mfe2')} className="load-btn">
                  Load MFE2
                </button>
                <button onClick={() => resetToDefault('mfe2')} className="reset-btn">
                  Reset to Local
                </button>
                {(customUrls.mfe2 || DEFAULT_MFES[1].url) && (
                  <button onClick={() => openMFEApp('mfe2')} className="open-btn">
                    🔗 Open App
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <main className="App-main">
        <div className="mfe-container">
          <div className="mfe-section">
            <h2>📦 Products (MFE1)</h2>
            <div className="current-url">
              <div>URL: {customUrls.mfe1 || DEFAULT_MFES[0].url}</div>
              <div>Module: {customModules.mfe1 || './ProductList'}</div>
            </div>
            <Suspense fallback={<div className="loading">Loading Products...</div>}>
              <MFE1Component />
            </Suspense>
          </div>
          
          <div className="mfe-section">
            <h2>👤 User Profile (MFE2)</h2>
            <div className="current-url">
              <div>URL: {customUrls.mfe2 || DEFAULT_MFES[1].url}</div>
              <div>Module: {customModules.mfe2 || './UserProfile'}</div>
            </div>
            <Suspense fallback={<div className="loading">Loading Profile...</div>}>
              <MFE2Component />
            </Suspense>
          </div>
        </div>
      </main>
    </div>
  )
}

export default App
