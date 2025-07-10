import React from 'react'
import ReactDOM from 'react-dom/client'
import ProductList from './components/ProductList'
import './index.css'

// This is for standalone development
ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <div style={{ padding: '2rem' }}>
      <h1>MFE1 - Product List (Standalone)</h1>
      <ProductList />
    </div>
  </React.StrictMode>,
)
