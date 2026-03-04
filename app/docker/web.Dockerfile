# Multi-stage build: Build React/Vite app and serve with Nginx

FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Build the application
RUN npm run build

FROM nginx:alpine

# Copy nginx configuration
COPY ../composition/docker/nginx.conf /etc/nginx/nginx.conf

# Copy built artifacts from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
