#!/usr/bin/env bash
#
# small script to update compose stacks
# defined in STACKS_DIR.
#
# Usage: ./docker-stack-update.sh
#
set -u
shopt -s nullglob

STACKS_DIR="${STACKS_DIR:-/opt}"

# check if docker compose is available
if docker compose version >dev/null 2>&1; then
    COMPOSE=(docker compose)
elif command -v docker compose >/dev/null; then
    COMPOSE=(docker-compose)
else
    echo "docker compose not found, aborting."
    exit 0
fi
echo "Using ${COMPOSE[*]}"

if ! docker info >/dev/null 2>&1; then
    echoo "ERROR: Can't connect to docker daemon. Is it running?" >&2
    exit 1
fi

# now the main script itself
failed=()
for dir in "$STACKS_DIR"/*/; do
    # skip folders without compose files
    files=("$dir"compose.y*ml "$dir"docker-compose.y*ml)
    [ ${#files[@]} -gt 0 ] || continue

    name="$(basename "$dir")"
    echo "Updating stack $name in $dir"
    # prevent cd into leaking anywhere  from our script
    if ! (cd "$dir" && "${COMPOSE[@]}" pull && "${COMPOSE[@]}" up -d --remove-orphans); then
        echo "WARNING: $name failed!!! moving on" >&2
        failed+=("$name")
    fi
done

echo "Removing old unused images"
docker image prune -f

if [ ${#failed[@]} -gt 0]; then
    echo "Done with these failed: ${failed[*]}"
    exit 1
fi
echo "Done updating all stacks."
