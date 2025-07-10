import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import federation from '@originjs/vite-plugin-federation'

export default defineConfig(({ mode }) => {
  const isProduction = mode === 'production'
  const baseUrl = process.env.VITE_APP_URL || ''
  
  return {
    plugins: [
      react(),
      federation({
        name: 'host',
        remotes: {
          mfe1: isProduction 
            ? `${baseUrl}/mfe1/assets/remoteEntry.js`
            : 'http://localhost:3001/assets/remoteEntry.js',
          mfe2: isProduction
            ? `${baseUrl}/mfe2/assets/remoteEntry.js`
            : 'http://localhost:3002/assets/remoteEntry.js'
        },
        shared: ['react', 'react-dom']
      })
    ],
    build: {
      modulePreload: false,
      target: 'esnext',
      minify: false,
      cssCodeSplit: false
    },
    server: {
      port: 3000,
      cors: true
    },
    preview: {
      port: 3000,
      cors: true
    }
  }
})
