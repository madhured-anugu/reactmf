import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import federation from '@originjs/vite-plugin-federation'

export default defineConfig({
  plugins: [
    react(),
    federation({
      name: 'mfe2',
      filename: 'remoteEntry.js',
      exposes: {
        './UserProfile': './src/components/UserProfile.tsx',
        './main': './src/federation-entry.tsx'
      },
      shared: {
        react: {
          requiredVersion: '^18.0.0'
        },
        'react-dom': {
          requiredVersion: '^18.0.0'
        }
      }
    })
  ],
  build: {
    target: 'esnext',
    modulePreload: false,
    minify: false,
    cssCodeSplit: false,
    rollupOptions: {
      external: ['react', 'react-dom']
    }
  },
  server: {
    port: 3002,
    cors: true,
    origin: 'http://localhost:3002'
  },
  preview: {
    port: 3002,
    cors: true
  }
})
