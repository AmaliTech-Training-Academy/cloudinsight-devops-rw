# Multi-platform Next.js Dockerfile optimized for AWS Graviton and other ARM instances
# Dependency installation stage - optimized for caching
FROM --platform=$BUILDPLATFORM node:22-alpine3.21 AS deps

# Build arguments for cross-platform support
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Install native dependencies for Alpine
RUN apk add --no-cache libc6-compat

WORKDIR /app

# Enable corepack and set pnpm version
RUN corepack enable pnpm && corepack prepare pnpm@latest --activate

# Copy dependency files first for better layer caching
COPY package.json pnpm-lock.yaml* ./

# Install dependencies with proper lockfile handling
RUN if [ -f pnpm-lock.yaml ]; then \
    echo "Installing with frozen lockfile..." && \
    pnpm install --frozen-lockfile --prefer-offline; \
    else \
    echo "No lockfile found, installing..." && \
    pnpm install --prefer-offline; \
    fi

# Source code builder stage
FROM --platform=$BUILDPLATFORM node:22-alpine3.21 AS builder

WORKDIR /app

# Enable pnpm
RUN corepack enable pnpm && corepack prepare pnpm@latest --activate

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Build-time public environment variables (can be overridden via --build-arg)
ARG NEXT_PUBLIC_API_BASE_URL="http://backend:8000/api/v1"
ARG NEXT_PUBLIC_NODE_ENV="production"
ARG NEXT_PUBLIC_ENABLE_MSW="false"

# Expose them as ENV so Next.js build inlines them
ENV NEXT_PUBLIC_API_BASE_URL=${NEXT_PUBLIC_API_BASE_URL}
ENV NEXT_PUBLIC_NODE_ENV=${NEXT_PUBLIC_NODE_ENV}
ENV NEXT_PUBLIC_ENABLE_MSW=${NEXT_PUBLIC_ENABLE_MSW}

# Copy source code (use .dockerignore to exclude unnecessary files)
COPY . .

# Build configuration
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Build the application
RUN echo "Building Next.js application..." && \
    pnpm run build && \
    echo "Build completed successfully"

# Production runtime stage
FROM node:22-alpine3.21 AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Re-declare build-time args so they can optionally be surfaced at runtime for server code
ARG NEXT_PUBLIC_API_BASE_URL
ARG NEXT_PUBLIC_NODE_ENV
ARG NEXT_PUBLIC_ENABLE_MSW
# (Optional) expose them again – mainly for any server code paths that still read process.env at runtime.
ENV NEXT_PUBLIC_API_BASE_URL=${NEXT_PUBLIC_API_BASE_URL}
ENV NEXT_PUBLIC_NODE_ENV=${NEXT_PUBLIC_NODE_ENV}
ENV NEXT_PUBLIC_ENABLE_MSW=${NEXT_PUBLIC_ENABLE_MSW}

# Runtime-only secret (DO NOT bake into build). Provide with `docker run -e AUTH_SECRET=...`.
# You may optionally set a default (not recommended for real deployments).

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Create directories with proper permissions
RUN mkdir -p ./public ./.next && \
    chown nextjs:nodejs ./.next

# Copy public assets if they exist
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# Copy Next.js build output (standalone mode for minimal image size)
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Set runtime environment
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"


# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node --version || exit 1

# Start the application
CMD ["node", "server.js"]
