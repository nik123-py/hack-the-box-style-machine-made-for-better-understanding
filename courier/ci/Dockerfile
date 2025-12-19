# CI Runner Docker Container
# Minimal Ubuntu container for running CI builds
# User runs as 'runner' user (not root)

FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install minimal required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        curl \
        git \
        netcat-traditional \
        && \
    rm -rf /var/lib/apt/lists/*

# Create runner user (non-root)
RUN useradd -m -s /bin/bash runner

# Set working directory
WORKDIR /home/runner

# Switch to runner user
USER runner

# Default command
CMD ["/bin/bash"]

