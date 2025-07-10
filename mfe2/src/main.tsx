import React from 'react'
import ReactDOM from 'react-dom/client'
import UserProfile from './components/UserProfile'
import './index.css'

// This is for standalone development
ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <div style={{ padding: '2rem' }}>
      <h1>MFE2 - User Profile (Standalone)</h1>
      <UserProfile />
    </div>
  </React.StrictMode>,
)
