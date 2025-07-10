#!/bin/sh

# Start nginx in the background
nginx -g "daemon off;" &

# Keep the container running
wait
