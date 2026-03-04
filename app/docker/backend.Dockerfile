# Backend Dockerfile for Node.js application
# Assumes a standard Node.js backend with package.json in app/backend

FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

# Build if build script exists (suppress error if missing)
RUN npm run build 2>/dev/null || true


FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production

# Copy entire app from builder, then remove heavy node_modules and reinstall prod-only
COPY --from=builder /app /tmp/build

# Copy relevant source/build files to final location
# This handles different project layouts: TypeScript (dist/), JavaScript (src/), etc.
RUN cp -r /tmp/build/src . 2>/dev/null || true && \
    cp -r /tmp/build/dist . 2>/dev/null || true && \
    cp -r /tmp/build/build . 2>/dev/null || true && \
    cp -r /tmp/build/public . 2>/dev/null || true

EXPOSE 3000

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start application
CMD ["npm", "start"]
