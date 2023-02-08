#!/usr/bin/env bash
set -e
. /app/.venv/bin/activate

exec duologsync /etc/duologsync/config.yaml>