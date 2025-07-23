import React from 'react';
import ReactDOM from 'react-dom';
import singleSpaReact from 'single-spa-react';
import UserProfile from './UserProfile.js';

const lifecycles = singleSpaReact({
  React,
  ReactDOM,
  rootComponent: UserProfile,
  errorBoundary(err, info, props) {
    console.error('User Profile MFE Error:', err, info);
    return (
      <div style={{ padding: '20px', color: '#e74c3c', textAlign: 'center' }}>
        <h3>❌ User Profile Error</h3>
        <p>Failed to load the user profile micro-frontend.</p>
        <details>
          <summary>Error details</summary>
          <pre>{err.toString()}</pre>
        </details>
      </div>
    );
  },
});

export const { bootstrap, mount, unmount } = lifecycles;
