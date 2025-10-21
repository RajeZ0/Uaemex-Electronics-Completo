# syntax=docker/dockerfile:1
ARG NODE_VERSION=20.17.0
FROM node:${NODE_VERSION}-alpine AS base

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
WORKDIR /app

RUN apk add --no-cache libc6-compat curl

FROM base AS deps
COPY package.json package-lock.json ./
RUN npm ci

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npx prisma generate
RUN npm run build

FROM base AS runner
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001
USER nextjs
WORKDIR /app
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
EXPOSE 8080
CMD ["npm", "start"]
