import React, { useState, useEffect } from 'react'
import './UserProfile.css'

interface User {
  id: number
  name: string
  email: string
  avatar: string
  bio: string
  location: string
  joinDate: string
  preferences: {
    theme: 'light' | 'dark'
    notifications: boolean
    newsletter: boolean
  }
  stats: {
    orders: number
    wishlist: number
    reviews: number
  }
}

const mockUser: User = {
  id: 1,
  name: 'John Doe',
  email: 'john.doe@example.com',
  avatar: '👤',
  bio: 'Software engineer passionate about micro frontends and modern web development.',
  location: 'San Francisco, CA',
  joinDate: '2023-01-15',
  preferences: {
    theme: 'light',
    notifications: true,
    newsletter: false
  },
  stats: {
    orders: 12,
    wishlist: 5,
    reviews: 8
  }
}

const UserProfile: React.FC = () => {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [isEditing, setIsEditing] = useState(false)
  const [editedUser, setEditedUser] = useState<User | null>(null)

  useEffect(() => {
    // Simulate API call
    setTimeout(() => {
      setUser(mockUser)
      setEditedUser(mockUser)
      setLoading(false)
    }, 800)
  }, [])

  const handleEdit = () => {
    setIsEditing(true)
  }

  const handleSave = () => {
    if (editedUser) {
      setUser(editedUser)
      setIsEditing(false)
    }
  }

  const handleCancel = () => {
    setEditedUser(user)
    setIsEditing(false)
  }

  const handleInputChange = (field: string, value: any) => {
    if (editedUser) {
      if (field.includes('.')) {
        const [parent, child] = field.split('.')
        setEditedUser({
          ...editedUser,
          [parent]: {
            ...(editedUser as any)[parent],
            [child]: value
          }
        })
      } else {
        setEditedUser({
          ...editedUser,
          [field]: value
        })
      }
    }
  }

  if (loading) {
    return (
      <div className="user-profile-container">
        <div className="loading-spinner">Loading profile...</div>
      </div>
    )
  }

  if (!user) {
    return (
      <div className="user-profile-container">
        <div className="error-message">Failed to load user profile</div>
      </div>
    )
  }

  const currentUser = isEditing ? editedUser! : user

  return (
    <div className="user-profile-container">
      <div className="profile-header">
        <div className="avatar-section">
          <div className="avatar">{currentUser.avatar}</div>
          <div className="user-info">
            {isEditing ? (
              <input
                type="text"
                value={currentUser.name}
                onChange={(e) => handleInputChange('name', e.target.value)}
                className="edit-input"
              />
            ) : (
              <h2>{currentUser.name}</h2>
            )}
            <p className="email">{currentUser.email}</p>
            <p className="location">📍 {currentUser.location}</p>
            <p className="join-date">Member since {new Date(currentUser.joinDate).toLocaleDateString()}</p>
          </div>
        </div>
        
        <div className="action-buttons">
          {!isEditing ? (
            <button onClick={handleEdit} className="edit-btn">
              ✏️ Edit Profile
            </button>
          ) : (
            <div className="edit-actions">
              <button onClick={handleSave} className="save-btn">
                ✅ Save
              </button>
              <button onClick={handleCancel} className="cancel-btn">
                ❌ Cancel
              </button>
            </div>
          )}
        </div>
      </div>

      <div className="profile-content">
        <div className="bio-section">
          <h3>About</h3>
          {isEditing ? (
            <textarea
              value={currentUser.bio}
              onChange={(e) => handleInputChange('bio', e.target.value)}
              className="edit-textarea"
              rows={3}
            />
          ) : (
            <p>{currentUser.bio}</p>
          )}
        </div>

        <div className="stats-section">
          <h3>Activity</h3>
          <div className="stats-grid">
            <div className="stat-card">
              <div className="stat-number">{currentUser.stats.orders}</div>
              <div className="stat-label">Orders</div>
            </div>
            <div className="stat-card">
              <div className="stat-number">{currentUser.stats.wishlist}</div>
              <div className="stat-label">Wishlist</div>
            </div>
            <div className="stat-card">
              <div className="stat-number">{currentUser.stats.reviews}</div>
              <div className="stat-label">Reviews</div>
            </div>
          </div>
        </div>

        <div className="preferences-section">
          <h3>Preferences</h3>
          <div className="preferences-list">
            <div className="preference-item">
              <span>🎨 Theme:</span>
              {isEditing ? (
                <select
                  value={currentUser.preferences.theme}
                  onChange={(e) => handleInputChange('preferences.theme', e.target.value)}
                  className="edit-select"
                >
                  <option value="light">Light</option>
                  <option value="dark">Dark</option>
                </select>
              ) : (
                <span className="preference-value">{currentUser.preferences.theme}</span>
              )}
            </div>
            <div className="preference-item">
              <span>🔔 Notifications:</span>
              {isEditing ? (
                <input
                  type="checkbox"
                  checked={currentUser.preferences.notifications}
                  onChange={(e) => handleInputChange('preferences.notifications', e.target.checked)}
                  className="edit-checkbox"
                />
              ) : (
                <span className="preference-value">
                  {currentUser.preferences.notifications ? 'Enabled' : 'Disabled'}
                </span>
              )}
            </div>
            <div className="preference-item">
              <span>📧 Newsletter:</span>
              {isEditing ? (
                <input
                  type="checkbox"
                  checked={currentUser.preferences.newsletter}
                  onChange={(e) => handleInputChange('preferences.newsletter', e.target.checked)}
                  className="edit-checkbox"
                />
              ) : (
                <span className="preference-value">
                  {currentUser.preferences.newsletter ? 'Subscribed' : 'Unsubscribed'}
                </span>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default UserProfile
