#!/bin/sh
# Certbot deploy hook. Runs only after a certificate has been renewed.
# Restarting OME disconnects current viewers; schedule renewals accordingly.
set -eu
exec /usr/bin/docker compose --project-directory /opt/ome -f /opt/ome/compose.yaml restart ome
