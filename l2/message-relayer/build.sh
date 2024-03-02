#!/bin/sh

# Install pnpm
npm install -g pnpm@8.10.4

# Set pnpm store dir to /tmp/pnpm-store
pnpm config set store-dir /tmp/pnpm-store

# Install dependencies
pnpm install

# Copy pnpm to /app/node_modules/.bin/pnpm
cp /usr/local/bin/pnpm /app/node_modules/.bin/pnpm
