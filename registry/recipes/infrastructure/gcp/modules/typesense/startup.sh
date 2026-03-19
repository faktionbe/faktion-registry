#!/bin/bash
set -e

# Log startup script execution
exec > >(tee -a /var/log/typesense-startup.log) 2>&1
echo "=== Typesense startup script started at $(date) ==="

# Ensure SSH is installed and running (critical for IAP access)
echo "Ensuring SSH daemon is running..."
apt-get update -qq
apt-get install -y -qq openssh-server
systemctl enable ssh
systemctl start ssh
echo "SSH daemon is running"

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo "Docker installed successfully"
else
    echo "Docker already installed"
fi

# Format and mount the persistent data disk if not already mounted
DATA_DISK="/dev/disk/by-id/google-typesense-data"
MOUNT_POINT="/var/lib/typesense"

if ! mountpoint -q "$MOUNT_POINT"; then
    echo "Setting up persistent data disk..."
    
    # Create mount point
    mkdir -p "$MOUNT_POINT"
    
    # Check if disk needs formatting (no filesystem)
    if ! blkid "$DATA_DISK" &> /dev/null; then
        echo "Formatting data disk..."
        mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard "$DATA_DISK"
    fi
    
    # Mount the disk
    mount -o discard,defaults "$DATA_DISK" "$MOUNT_POINT"
    
    # Add to fstab for persistence across reboots
    if ! grep -q "$DATA_DISK" /etc/fstab; then
        echo "$DATA_DISK $MOUNT_POINT ext4 discard,defaults,nofail 0 2" >> /etc/fstab
    fi
    
    echo "Data disk mounted at $MOUNT_POINT"
else
    echo "Data disk already mounted at $MOUNT_POINT"
fi

# Ensure correct ownership for data directory
chown -R root:root "$MOUNT_POINT"

# Stop and remove existing Typesense container if running
if docker ps -a --format '{{.Names}}' | grep -q '^typesense$'; then
    echo "Stopping existing Typesense container..."
    docker stop typesense || true
    docker rm typesense || true
fi

# Pull the latest version of the specified Typesense image
echo "Pulling Typesense image version ${typesense_version}..."
docker pull "typesense/typesense:${typesense_version}"

# Run Typesense container
echo "Starting Typesense container..."
docker run -d \
    --name typesense \
    --restart always \
    -p 8108:8108 \
    -v "$MOUNT_POINT:/data" \
    "typesense/typesense:${typesense_version}" \
    --data-dir /data \
    --api-key="${typesense_api_key}" \
    --enable-cors

# Wait for Typesense to be healthy
echo "Waiting for Typesense to be healthy..."
for i in {1..30}; do
    if curl -sf http://localhost:8108/health > /dev/null 2>&1; then
        echo "Typesense is healthy!"
        break
    fi
    echo "Waiting for Typesense to start... (attempt $i/30)"
    sleep 2
done

# Final health check
if curl -sf http://localhost:8108/health > /dev/null 2>&1; then
    echo "=== Typesense startup completed successfully at $(date) ==="
else
    echo "WARNING: Typesense health check failed after 60 seconds"
    echo "Container logs:"
    docker logs typesense
fi

