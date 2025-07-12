import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import federation from '@originjs/vite-plugin-federation'

export default defineConfig(() => {
  return {
    plugins: [
      react(),
      federation({
        name: 'host',
        remotes: {
          // Module federation is being handled dynamically. see App.tsx
          // Add dummy.js to prevent vite from throwing an error
          dummy: 'dummy.js'
        },
        shared: ['react', 'react-dom']
      })
    ],
    build: {
      target: 'esnext',
      modulePreload: false,
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
