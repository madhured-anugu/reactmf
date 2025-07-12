import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import federation from '@originjs/vite-plugin-federation'

export default defineConfig({
  plugins: [
    react(),
    federation({
      name: 'mfe1',
      filename: 'remoteEntry.js',
      exposes: {
        './ProductList': './src/components/ProductList.tsx',
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
    port: 3001,
    cors: true,
    origin: 'http://localhost:3001'
  },
  preview: {
    port: 3001,
    cors: true
  }
})
