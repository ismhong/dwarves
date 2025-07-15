#!/bin/bash

set -e

# Set environment variables for Docker BuildKit as requested
export BUILDKIT_PROGRESS=plain
export DOCKER_BUILDKIT=0

# Create a clean output directory
echo "Cleaning up previous builds..."
rm -rf output
mkdir -p output

# Platforms to build for
PLATFORMS="linux/amd64 linux/arm64 linux/arm/v7"

# Loop through each platform and build sequentially
for platform in $PLATFORMS
do
    echo "Building for platform: $platform"

    # Sanitize the platform string for tagging the image
    arch=$(echo $platform | sed 's/linux\///' | sed 's/\///g')

    # Temporary directory for this platform's build output
    build_tmp="build_output_$(echo "$arch" | tr '/' '_')"
    rm -rf "$build_tmp"

    # Build and export the result to the temporary local directory
    docker buildx build --platform "$platform" -t "pahole-multiarch:$arch" --output="type=local,dest=$build_tmp" .

    echo "--- Listing contents of temporary directory $build_tmp ---"
    ls -lR "$build_tmp"

    echo "Copying executables for $platform to the main 'output' folder..."

    # Copy all generated executables directly to the output folder
    cp "$build_tmp"/executables/* output/

    echo "Copied files for $arch."

    # Clean up the temporary directory for this platform
    rm -rf "$build_tmp"
done

echo "Build complete. All executables are in the 'output' directory:"
ls -l output
