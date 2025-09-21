#!/usr/bin/env bash

################################################################################
# Flux Kustomization Dependencies Generator
################################################################################
#
# Description: Simple wrapper script to generate Flux Kustomization dependency
#              visualization as a markdown document.
#
# Author:      Generated for home-ops
# Version:     1.0.0
# Created:     2025-07-10
#
# Usage:       ./generate-dependencies.sh [output-file]
#
# Examples:    ./generate-dependencies.sh
#              ./generate-dependencies.sh custom-deps.md
#
################################################################################

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
OUTPUT_FILE="${1:-flux-kustomization-dependencies.md}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
log_success() { echo -e "${GREEN}✅ $*${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $*${NC}"; }
log_error() { echo -e "${RED}❌ $*${NC}" >&2; }

main() {
    log_info "Generating Flux Kustomization dependencies..."
    log_info "Output file: $OUTPUT_FILE"

    # Check if Python script exists
    if [[ ! -f "$SCRIPT_DIR/generate-flux-dependencies.py" ]]; then
        log_error "Python script 'generate-flux-dependencies.py' not found in $SCRIPT_DIR"
        exit 1
    fi

    # Check if kubernetes directory exists
    if [[ ! -d "$SCRIPT_DIR/kubernetes" ]]; then
        log_error "Kubernetes directory not found in $SCRIPT_DIR"
        exit 1
    fi

    # Run the Python script
    cd "$SCRIPT_DIR"
    if python3 generate-flux-dependencies.py; then
        # Check if output was generated
        if [[ -f "$OUTPUT_FILE" ]]; then
            log_success "Dependency visualization generated successfully!"
            log_info "File: $OUTPUT_FILE"

            # Show some stats
            local total_lines=$(wc -l < "$OUTPUT_FILE")
            local total_kustomizations=$(grep -c "^| \`.*\` | \`.*\` |" "$OUTPUT_FILE" || echo "0")

            log_info "Document contains $total_lines lines"
            log_info "Found $total_kustomizations Kustomizations"

        else
            log_error "Output file was not generated"
            exit 1
        fi
    else
        log_error "Failed to generate dependency visualization"
        exit 1
    fi
}

# Show usage if help is requested
case "${1:-}" in
    -h|--help)
        echo "Usage: $0 [output-file]"
        echo ""
        echo "Generate a markdown document visualizing Flux Kustomization dependencies"
        echo ""
        echo "Arguments:"
        echo "  output-file    Optional output filename (default: flux-kustomization-dependencies.md)"
        echo ""
        echo "Examples:"
        echo "  $0                           # Generate with default filename"
        echo "  $0 my-dependencies.md       # Generate with custom filename"
        echo ""
        exit 0
        ;;
esac

main "$@"
