import React from 'react';
import ReactDOM from 'react-dom';
import singleSpaReact from 'single-spa-react';
import ProductList from './ProductList.js';

const lifecycles = singleSpaReact({
  React,
  ReactDOM,
  rootComponent: ProductList,
  errorBoundary(err, info, props) {
    console.error('Product List MFE Error:', err, info);
    return (
      <div style={{ padding: '20px', color: '#e74c3c', textAlign: 'center' }}>
        <h3>❌ Product List Error</h3>
        <p>Failed to load the product list micro-frontend.</p>
        <details>
          <summary>Error details</summary>
          <pre>{err.toString()}</pre>
        </details>
      </div>
    );
  },
});

export const { bootstrap, mount, unmount } = lifecycles;
