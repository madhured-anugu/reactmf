import React, { useState, useEffect } from 'react'
import './ProductList.css'

interface Product {
  id: number
  name: string
  price: number
  description: string
  category: string
  inStock: boolean
}

const mockProducts: Product[] = [
  {
    id: 1,
    name: 'Wireless Headphones',
    price: 99.99,
    description: 'High-quality wireless headphones with noise cancellation',
    category: 'Electronics',
    inStock: true
  },
  {
    id: 2,
    name: 'Smart Watch',
    price: 199.99,
    description: 'Feature-rich smartwatch with health tracking',
    category: 'Electronics',
    inStock: true
  },
  {
    id: 3,
    name: 'Coffee Maker',
    price: 79.99,
    description: 'Programmable coffee maker with thermal carafe',
    category: 'Home & Kitchen',
    inStock: false
  },
  {
    id: 4,
    name: 'Yoga Mat',
    price: 29.99,
    description: 'Non-slip yoga mat for all types of exercise',
    category: 'Sports',
    inStock: true
  }
]

const ProductList: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedCategory, setSelectedCategory] = useState<string>('All')

  useEffect(() => {
    // Simulate API call
    setTimeout(() => {
      setProducts(mockProducts)
      setLoading(false)
    }, 1000)
  }, [])

  const categories = ['All', ...Array.from(new Set(products.map(p => p.category)))]
  
  const filteredProducts = selectedCategory === 'All' 
    ? products 
    : products.filter(p => p.category === selectedCategory)

  if (loading) {
    return (
      <div className="product-list-container">
        <div className="loading-spinner">Loading products...</div>
      </div>
    )
  }

  return (
    <div className="product-list-container">
      <div className="filter-section">
        <label htmlFor="category-filter">Filter by category:</label>
        <select 
          id="category-filter"
          value={selectedCategory}
          onChange={(e) => setSelectedCategory(e.target.value)}
        >
          {categories.map(category => (
            <option key={category} value={category}>
              {category}
            </option>
          ))}
        </select>
      </div>

      <div className="products-grid">
        {filteredProducts.map(product => (
          <div key={product.id} className="product-card">
            <div className="product-header">
              <h3>{product.name}</h3>
              <span className={`stock-status ${product.inStock ? 'in-stock' : 'out-of-stock'}`}>
                {product.inStock ? 'In Stock' : 'Out of Stock'}
              </span>
            </div>
            <p className="product-description">{product.description}</p>
            <div className="product-footer">
              <span className="product-category">{product.category}</span>
              <span className="product-price">${product.price.toFixed(2)}</span>
            </div>
            <button 
              className="add-to-cart-btn"
              disabled={!product.inStock}
            >
              {product.inStock ? 'Add to Cart' : 'Out of Stock'}
            </button>
          </div>
        ))}
      </div>
    </div>
  )
}

export default ProductList
