# ==================== BASE ====================
FROM node:20-alpine AS base

WORKDIR /app

# Install dependencies for node-gyp
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    libc6-compat

# ==================== DEPENDENCIES ====================
FROM base AS dependencies

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm ci --only=production && \
    cp -R node_modules /tmp/node_modules && \
    npm ci

# ==================== BUILD ====================
FROM base AS build

COPY --from=dependencies /app/node_modules ./node_modules
COPY . .

# Build application
RUN npm run build && \
    npm prune --production

# ==================== DEVELOPMENT ====================
FROM base AS development

ENV NODE_ENV=development

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .

EXPOSE 4000

CMD ["npm", "run", "start:dev"]

# ==================== PRODUCTION ====================
FROM base AS production

ENV NODE_ENV=production

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001

# Copy built application
COPY --from=build --chown=nestjs:nodejs /app/dist ./dist
COPY --from=build --chown=nestjs:nodejs /app/node_modules ./node_modules
COPY --chown=nestjs:nodejs package.json ./

USER nestjs

EXPOSE 4000

CMD ["node", "dist/main"]
