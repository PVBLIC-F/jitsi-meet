# Multi-stage Dockerfile for Jitsi Meet
# Stage 1: Build stage
FROM node:22-alpine AS builder

# Install build dependencies
RUN apk add --no-cache make python3 g++

# Set working directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Remove package-lock.json if it contains workspace references and install dependencies
RUN npm cache clean --force && \
    rm -f package-lock.json && \
    npm install --legacy-peer-deps

# Copy source code
COPY . .

# Build the application
RUN make compile && make deploy

# Stage 2: Production stage
FROM nginx:alpine

# Install necessary packages for processing includes
RUN apk add --no-cache \
    bash \
    sed \
    envsubst

# Copy built assets from builder stage
COPY --from=builder /usr/src/app/libs /usr/share/nginx/html/libs
COPY --from=builder /usr/src/app/css /usr/share/nginx/html/css
COPY --from=builder /usr/src/app/images /usr/share/nginx/html/images
COPY --from=builder /usr/src/app/sounds /usr/share/nginx/html/sounds
COPY --from=builder /usr/src/app/fonts /usr/share/nginx/html/fonts
COPY --from=builder /usr/src/app/static /usr/share/nginx/html/static
COPY --from=builder /usr/src/app/lang /usr/share/nginx/html/lang

# Copy HTML and JS files
COPY --from=builder /usr/src/app/*.html /usr/share/nginx/html/
COPY --from=builder /usr/src/app/*.js /usr/share/nginx/html/
COPY --from=builder /usr/src/app/manifest.json /usr/share/nginx/html/

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Copy and make executable the startup script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose port
EXPOSE 80

# Use custom entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"] 