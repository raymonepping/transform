#!/bin/bash
set -e

# Ensure /run/sshd exists (required after docker-slim!)
mkdir -p /run/sshd

# Exec the CMD as passed by Docker
exec "$@"
