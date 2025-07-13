#!/bin/bash

# CloudNative-PG S3 Folder Rename Script
# Renames S3 folders for CloudNative-PG backup restore operations
# Usage: ./s3-folder-rename.sh [OPTIONS] SOURCE_FOLDER TARGET_FOLDER

set -euo pipefail

# Default values
BUCKET="s3://cloudnative-pg"
ENDPOINT_URL="https://gateway.storjshare.io"
REMOVE_SOURCE=false
VERBOSE=false

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] SOURCE_FOLDER TARGET_FOLDER

Rename S3 folders for CloudNative-PG backup restore operations.

ARGUMENTS:
    SOURCE_FOLDER    Name of the source folder to rename (e.g., postgres-v17)
    TARGET_FOLDER    Name of the target folder (e.g., postgres-v17-backup)

OPTIONS:
    -b, --bucket BUCKET        S3 bucket name (default: $BUCKET)
    -e, --endpoint ENDPOINT    S3 endpoint URL (default: $ENDPOINT_URL)
    -r, --remove-source        Remove source folder after successful copy
    -v, --verbose              Enable verbose output
    -h, --help                 Show this help message

EXAMPLES:
    # Basic rename
    $0 postgres-v17 postgres-v17-backup

    # Rename with source removal
    $0 -r postgres-v17 postgres-v17-backup

    # Use different bucket
    $0 -b s3://my-bucket postgres-v17 postgres-v17-backup

    # Use different endpoint (for non-Storj S3)
    $0 -e https://s3.amazonaws.com postgres-v17 postgres-v17-backup
EOF
}

# Function to log messages
log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
    fi
}

# Function to check if folder exists
folder_exists() {
    local folder="$1"
    aws s3 ls "${BUCKET}/${folder}/" --endpoint-url "$ENDPOINT_URL" >/dev/null 2>&1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--bucket)
            BUCKET="$2"
            shift 2
            ;;
        -e|--endpoint)
            ENDPOINT_URL="$2"
            shift 2
            ;;
        -r|--remove-source)
            REMOVE_SOURCE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            usage
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Check if we have the required arguments
if [[ $# -ne 2 ]]; then
    echo "Error: SOURCE_FOLDER and TARGET_FOLDER are required" >&2
    usage
    exit 1
fi

SOURCE_FOLDER="$1"
TARGET_FOLDER="$2"

# Validate inputs
if [[ -z "$SOURCE_FOLDER" || -z "$TARGET_FOLDER" ]]; then
    echo "Error: SOURCE_FOLDER and TARGET_FOLDER cannot be empty" >&2
    exit 1
fi

if [[ "$SOURCE_FOLDER" == "$TARGET_FOLDER" ]]; then
    echo "Error: SOURCE_FOLDER and TARGET_FOLDER cannot be the same" >&2
    exit 1
fi

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed or not in PATH" >&2
    exit 1
fi

log "Starting S3 folder rename operation"
log "Source: ${BUCKET}/${SOURCE_FOLDER}/"
log "Target: ${BUCKET}/${TARGET_FOLDER}/"
log "Endpoint: $ENDPOINT_URL"
log "Remove source: $REMOVE_SOURCE"

# Check if source folder exists
if ! folder_exists "$SOURCE_FOLDER"; then
    echo "Error: Source folder '${SOURCE_FOLDER}' does not exist in bucket '$BUCKET'" >&2
    exit 1
fi

# Check if target folder already exists
if folder_exists "$TARGET_FOLDER"; then
    echo "Error: Target folder '${TARGET_FOLDER}' already exists in bucket '$BUCKET'" >&2
    echo "Please choose a different target folder name or remove the existing folder first." >&2
    exit 1
fi

# Perform the copy operation
echo "Copying ${BUCKET}/${SOURCE_FOLDER}/ to ${BUCKET}/${TARGET_FOLDER}/ ..."
log "Running: aws s3 cp ${BUCKET}/${SOURCE_FOLDER}/ ${BUCKET}/${TARGET_FOLDER}/ --recursive --endpoint-url $ENDPOINT_URL"

if aws s3 cp "${BUCKET}/${SOURCE_FOLDER}/" "${BUCKET}/${TARGET_FOLDER}/" \
    --recursive --endpoint-url "$ENDPOINT_URL"; then
    echo "✓ Successfully copied folder to ${TARGET_FOLDER}"
    log "Copy operation completed successfully"
else
    echo "✗ Failed to copy folder" >&2
    exit 1
fi

# Remove source folder if requested
if [[ "$REMOVE_SOURCE" == "true" ]]; then
    echo "Removing source folder ${SOURCE_FOLDER} ..."
    log "Running: aws s3 rm ${BUCKET}/${SOURCE_FOLDER}/ --recursive --endpoint-url $ENDPOINT_URL"
    
    if aws s3 rm "${BUCKET}/${SOURCE_FOLDER}/" \
        --recursive --endpoint-url "$ENDPOINT_URL"; then
        echo "✓ Successfully removed source folder ${SOURCE_FOLDER}"
        log "Source folder removal completed successfully"
    else
        echo "✗ Failed to remove source folder" >&2
        echo "Target folder ${TARGET_FOLDER} was created successfully, but source cleanup failed." >&2
        exit 1
    fi
fi

echo "✓ Operation completed successfully!"
log "S3 folder rename operation finished"

# Display final bucket state
echo ""
echo "Current bucket structure:"
aws s3 ls "$BUCKET/" --endpoint-url "$ENDPOINT_URL"
