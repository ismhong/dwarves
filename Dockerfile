# syntax=docker/dockerfile:1

# --- Build Stage ---
FROM alpine:3.22 AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM"

# Install build dependencies
RUN apk add --no-cache \
    alpine-sdk \
    cmake \
    elfutils-dev \
    libdwarf-dev \
    zlib-dev \
    libbpf-dev \
    linux-headers \
    musl-obstack-dev \
    argp-standalone \
    samurai \
    zlib-static \
    bzip2-static \
    xz-static \
    zstd-static

# Copy source code
WORKDIR /src
COPY . .

# Build
RUN mkdir build && cd build && \
    cmake -DSTATIC_LINK=ON -GNinja .. && \
    ninja

# Strip and rename executables
RUN cd build && \
    arch=$(echo $TARGETPLATFORM | sed 's/linux\///' | sed 's/\///g') && \
    for exe in pahole codiff ctfdwdiff pfunct pglobal prefcnt syscse dtagnames pdwtags scncopy ctracer; do \
        if [ -f "$exe" ]; then \
            # Create debug version with arch suffix
            cp "$exe" "$exe.$arch.debug" && \
            # Create stripped version with arch suffix
            strip -s -o "$exe.$arch.strip" "$exe"; \
        fi; \
    done

# --- Final Stage ---
# This stage contains only the final executables
FROM scratch

WORKDIR /executables
# Copy only the renamed executables from the builder stage
COPY --from=builder /src/build/*.strip .
COPY --from=builder /src/build/*.debug .
