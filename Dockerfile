# Multi-stage build for React Micro Frontend
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build all micro frontends and host
RUN npm run build

# Production stage with nginx
FROM nginx:alpine

# Install Node.js in nginx container for serving built apps
RUN apk add --no-cache nodejs npm

# Remove default nginx config
RUN rm -rf /etc/nginx/conf.d/*

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built applications from builder stage
COPY --from=builder /app/host/dist /usr/share/nginx/html/host
COPY --from=builder /app/mfe1/dist /usr/share/nginx/html/mfe1
COPY --from=builder /app/mfe2/dist /usr/share/nginx/html/mfe2

# Create a startup script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose port 8080 (required by Cloud Run)
EXPOSE 8080

# Use custom entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
