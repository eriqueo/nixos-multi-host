#!/usr/bin/env bash
# Wrapper for AI documentation generator to ensure proper Python environment

export PYTHONPATH="/run/current-system/sw/lib/python3.13/site-packages:$PYTHONPATH"
/run/current-system/sw/bin/python3 /etc/nixos/scripts/ai-narrative-docs.py "$@"
