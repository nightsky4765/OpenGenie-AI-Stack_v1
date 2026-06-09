#!/bin/bash
set -eo pipefail
echo "Starting"
VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n 1)
echo "VRAM=$VRAM"
