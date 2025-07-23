import React, { useState, useEffect } from 'react';
import './ProductList.css';

const ProductList = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Simulate API call
    setTimeout(() => {
      setProducts([
        { 
          id: 1, 
          name: 'MacBook Pro M3', 
          price: 1999, 
          category: 'Electronics',
          image: '💻',
          description: 'Powerful laptop with M3 chip'
        },
        { 
          id: 2, 
          name: 'iPhone 15 Pro', 
          price: 999, 
          category: 'Electronics',
          image: '📱',
          description: 'Latest iPhone with advanced features'
        },
        { 
          id: 3, 
          name: 'AirPods Pro', 
          price: 249, 
          category: 'Accessories',
          image: '🎧',
          description: 'Wireless earbuds with noise cancellation'
        },
        { 
          id: 4, 
          name: 'iPad Air', 
          price: 599, 
          category: 'Electronics',
          image: '📱',
          description: 'Lightweight tablet for productivity'
        },
        { 
          id: 5, 
          name: 'Apple Watch Series 9', 
          price: 399, 
          category: 'Wearables',
          image: '⌚',
          description: 'Advanced smartwatch with health tracking'
        },
        { 
          id: 6, 
          name: 'Studio Display', 
          price: 1599, 
          category: 'Displays',
          image: '🖥️',
          description: '27-inch 5K Retina display'
        }
      ]);
      setLoading(false);
    }, 1000);
  }, []);

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Loading products...</p>
      </div>
    );
  }

  return (
    <div className="product-list">
      <div className="products-grid">
        {products.map(product => (
          <div key={product.id} className="product-card">
            <div className="product-image">{product.image}</div>
            <div className="product-info">
              <h3 className="product-name">{product.name}</h3>
              <p className="product-description">{product.description}</p>
              <div className="product-footer">
                <span className="product-category">{product.category}</span>
                <span className="product-price">${product.price}</span>
              </div>
              <button className="add-to-cart-btn">
                Add to Cart
              </button>
            </div>
          </div>
        ))}
      </div>
      <div className="mfe-info">
        <small>🏗️ Loaded via Single-SPA (Port 8080)</small>
      </div>
    </div>
  );
};

export default ProductList;
