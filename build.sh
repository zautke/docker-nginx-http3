#!/bin/bash

# Exit on error
set -e

# Create and use a new builder instance
docker buildx create --name nginx-builder --use || true

# Build and push the main image for each platform
echo "Building braisenly/nginx-http3 for arm64..."
docker buildx build \
  --platform linux/arm64 \
  --tag braisenly/nginx-http3:latest-arm64 \
  --push \
  -f Dockerfile .

echo "Building braisenly/nginx-http3 for amd64..."
docker buildx build \
  --platform linux/amd64 \
  --tag braisenly/nginx-http3:latest-amd64 \
  --push \
  -f Dockerfile .

# Create and push the multi-arch manifest
echo "Creating multi-arch manifest for braisenly/nginx-http3..."
docker manifest create braisenly/nginx-http3:latest \
  braisenly/nginx-http3:latest-arm64 \
  braisenly/nginx-http3:latest-amd64
docker manifest push braisenly/nginx-http3:latest

# Build and push the test image for each platform
echo "Building braisenly/nginx-h3 for arm64..."
docker buildx build \
  --platform linux/arm64 \
  --tag braisenly/nginx-h3:latest-arm64 \
  --tag braisenly/nginx-h3:test-arm64 \
  --push \
  -f test.Dockerfile .

echo "Building braisenly/nginx-h3 for amd64..."
docker buildx build \
  --platform linux/amd64 \
  --tag braisenly/nginx-h3:latest-amd64 \
  --tag braisenly/nginx-h3:test-amd64 \
  --push \
  -f test.Dockerfile .

# Create and push the multi-arch manifests
echo "Creating multi-arch manifests for braisenly/nginx-h3..."
docker manifest create braisenly/nginx-h3:latest \
  braisenly/nginx-h3:latest-arm64 \
  braisenly/nginx-h3:latest-amd64
docker manifest push braisenly/nginx-h3:latest

docker manifest create braisenly/nginx-h3:test \
  braisenly/nginx-h3:test-arm64 \
  braisenly/nginx-h3:test-amd64
docker manifest push braisenly/nginx-h3:test

echo "Build completed successfully!"
