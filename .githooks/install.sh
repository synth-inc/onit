#!/bin/bash
#
#  install.sh
#  Onit
#
#  Created by Kévin Naudin on 2026-01-23.
#
#  Run this script once to configure git hooks for this repository.
#  Usage: ./.githooks/install.sh
#

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "Setting up git hooks..."

# Configure git to use the shared hooks directory
git config core.hooksPath .githooks

echo ""
echo "✓ Git hooks installed successfully!"
echo ""
echo "What this does:"
echo "  • post-checkout: Updates submodules + cleans SPM cache"
echo "  • post-merge: Updates submodules after pull + cleans SPM cache"
