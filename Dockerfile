# ---- Base ----
# Base image with Node.js and Alpine for a small footprint
FROM node:20-alpine AS base

# ---- Dependencies ----
# Install dependencies in a separate layer to leverage Docker's caching.
FROM base AS deps
WORKDIR /app

# Copy package.json and lock file
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm install

# ---- Builder ----
# Build the Next.js application
FROM base AS builder
WORKDIR /app

# Copy dependencies from the 'deps' stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build the Next.js app.
# You need to enable the 'standalone' output mode in your next.config.js
# module.exports = { output: 'standalone' }
RUN npm run build

# ---- Runner ----
# Final, minimal image to run the application
FROM base AS runner
WORKDIR /app

# Create a non-root user for security
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

ENV NODE_ENV=production

# Copy the standalone output from the builder stage
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./

# Copy public and static assets
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000
ENV PORT 3000

CMD ["node", "server.js"]
