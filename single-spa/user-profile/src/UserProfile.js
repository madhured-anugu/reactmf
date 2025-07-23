import React, { useState, useEffect } from 'react';
import './UserProfile.css';

const UserProfile = () => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('profile');

  useEffect(() => {
    // Simulate API call
    setTimeout(() => {
      setUser({
        id: 1,
        name: 'John Doe',
        email: 'john.doe@example.com',
        avatar: '👤',
        role: 'Premium Member',
        joinDate: 'January 2023',
        stats: {
          orders: 24,
          wishlist: 8,
          reviews: 12
        },
        preferences: {
          notifications: true,
          newsletter: true,
          darkMode: false
        },
        recentActivity: [
          { id: 1, action: 'Purchased MacBook Pro M3', date: '2 days ago' },
          { id: 2, action: 'Added iPhone 15 to wishlist', date: '1 week ago' },
          { id: 3, action: 'Left review for AirPods Pro', date: '2 weeks ago' }
        ]
      });
      setLoading(false);
    }, 800);
  }, []);

  const handlePreferenceChange = (key) => {
    setUser(prev => ({
      ...prev,
      preferences: {
        ...prev.preferences,
        [key]: !prev.preferences[key]
      }
    }));
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Loading profile...</p>
      </div>
    );
  }

  return (
    <div className="user-profile">
      <div className="profile-header">
        <div className="avatar">{user.avatar}</div>
        <div className="user-info">
          <h2>{user.name}</h2>
          <p className="email">{user.email}</p>
          <span className="role">{user.role}</span>
          <p className="join-date">Member since {user.joinDate}</p>
        </div>
      </div>

      <div className="profile-tabs">
        <button 
          className={`tab ${activeTab === 'profile' ? 'active' : ''}`}
          onClick={() => setActiveTab('profile')}
        >
          📊 Stats
        </button>
        <button 
          className={`tab ${activeTab === 'preferences' ? 'active' : ''}`}
          onClick={() => setActiveTab('preferences')}
        >
          ⚙️ Settings
        </button>
        <button 
          className={`tab ${activeTab === 'activity' ? 'active' : ''}`}
          onClick={() => setActiveTab('activity')}
        >
          📝 Activity
        </button>
      </div>

      <div className="tab-content">
        {activeTab === 'profile' && (
          <div className="stats-grid">
            <div className="stat-card">
              <div className="stat-icon">🛍️</div>
              <div className="stat-number">{user.stats.orders}</div>
              <div className="stat-label">Orders</div>
            </div>
            <div className="stat-card">
              <div className="stat-icon">❤️</div>
              <div className="stat-number">{user.stats.wishlist}</div>
              <div className="stat-label">Wishlist Items</div>
            </div>
            <div className="stat-card">
              <div className="stat-icon">⭐</div>
              <div className="stat-number">{user.stats.reviews}</div>
              <div className="stat-label">Reviews</div>
            </div>
          </div>
        )}

        {activeTab === 'preferences' && (
          <div className="preferences">
            <div className="preference-item">
              <div className="preference-info">
                <h4>🔔 Push Notifications</h4>
                <p>Receive notifications about orders and promotions</p>
              </div>
              <label className="switch">
                <input 
                  type="checkbox" 
                  checked={user.preferences.notifications}
                  onChange={() => handlePreferenceChange('notifications')}
                />
                <span className="slider"></span>
              </label>
            </div>
            <div className="preference-item">
              <div className="preference-info">
                <h4>📧 Newsletter</h4>
                <p>Subscribe to our weekly newsletter</p>
              </div>
              <label className="switch">
                <input 
                  type="checkbox" 
                  checked={user.preferences.newsletter}
                  onChange={() => handlePreferenceChange('newsletter')}
                />
                <span className="slider"></span>
              </label>
            </div>
            <div className="preference-item">
              <div className="preference-info">
                <h4>🌙 Dark Mode</h4>
                <p>Switch to dark theme</p>
              </div>
              <label className="switch">
                <input 
                  type="checkbox" 
                  checked={user.preferences.darkMode}
                  onChange={() => handlePreferenceChange('darkMode')}
                />
                <span className="slider"></span>
              </label>
            </div>
          </div>
        )}

        {activeTab === 'activity' && (
          <div className="activity-list">
            {user.recentActivity.map(activity => (
              <div key={activity.id} className="activity-item">
                <div className="activity-content">
                  <p>{activity.action}</p>
                  <span className="activity-date">{activity.date}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="mfe-info">
        <small>🏗️ Loaded via Single-SPA (Port 8081)</small>
      </div>
    </div>
  );
};

export default UserProfile;
