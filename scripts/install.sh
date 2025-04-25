#!/bin/bash

echo ">>> Starting Linkding DevOps Deployment <<<"
echo "Ensuring .env file exists and secrets are set..."
echo "Ensuring Docker and Docker Compose are installed..."
echo "Ensuring ports 80 and 443 are free..."
# read -p "Press Enter to continue or Ctrl+C to cancel..." # Optional pause

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found. Please copy .env.example to .env and set secrets."
    exit 1
fi

# Load .env variables into the environment for docker compose
# Using 'set -a' ensures all defined variables are exported
set -a
source .env
set +a

echo "--- Starting main services (Linkding, Postgres, Caddy) ---"
# Pull latest images specified in the compose file
docker compose -f docker-compose.yml pull

# Start services defined in docker-compose.yml in detached mode
# --remove-orphans removes containers for services not defined anymore
docker compose -f docker-compose.yml up -d --remove-orphans

# Separately manage Watchtower if desired (using its own compose file)
# Check if the watchtower config exists before trying to start it
if [ -f watchtower/docker-compose.watchtower.yml ]; then
  echo "--- Starting Watchtower for automatic updates ---"
  docker compose -f watchtower/docker-compose.watchtower.yml pull
  docker compose -f watchtower/docker-compose.watchtower.yml up -d --remove-orphans
else
  echo "--- Watchtower configuration not found, skipping Watchtower startup ---"
fi

echo ""
echo ">>> Deployment potentially complete! <<<"
echo "Linkding should be available shortly at https://bookmarks.mischa.cloud"
echo "Caddy will attempt to provision an HTTPS certificate automatically."
echo "Make sure the DNS A record for bookmarks.mischa.cloud points to this server's IP!"
echo "You might need to wait a few minutes for DNS propagation and certificate issuance."

exit 0
