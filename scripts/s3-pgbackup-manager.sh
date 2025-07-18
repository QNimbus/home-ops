#!/bin/bash

# CloudNative-PG S3 Backup Manager Script
# Manages S3 folders for CloudNative-PG backup/restore operations
# Usage: ./s3-pgbackup-manager.sh [OPTIONS] [SOURCE_FOLDER] [TARGET_FOLDER]

set -euo pipefail

# Default values
BUCKET="s3://cloudnative-pg"
ENDPOINT_URL="https://gateway.storjshare.io"
REMOVE_SOURCE=false
REMOVE_TARGET=false
VERBOSE=false
OPERATION="rename"
RECURSIVE_LIST=false

# Handle broken pipe errors gracefully
# This prevents the "Broken pipe" error message when piping to head, grep, etc.
handle_sigpipe() {
    if [[ -n "${TRAP_SIGPIPE_APPLIED:-}" ]]; then
        return 0
    fi
    TRAP_SIGPIPE_APPLIED=1
    # Ignore SIGPIPE signals
    trap '' PIPE
}

# Function to check if we're being piped
is_piped() {
    [[ ! -t 1 ]]
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] [SOURCE_FOLDER] [TARGET_FOLDER]

Manage S3 folders for CloudNative-PG backup/restore operations.

OPERATIONS:
    rename              Rename/move a folder (default operation)
    remove              Remove a folder completely
    list                List the contents of a folder/bucket

ARGUMENTS:
    SOURCE_FOLDER      For rename: Name of the source folder to rename (e.g., postgres-v17)
                       For remove: Name of the folder to remove
                       For list: Path to list (optional, lists bucket root if omitted)
    TARGET_FOLDER      For rename: Name of the target folder (e.g., postgres-v17-backup)
                       For remove/list: Not used

OPTIONS:
    -b, --bucket BUCKET        S3 bucket name (default: $BUCKET)
    -e, --endpoint ENDPOINT    S3 endpoint URL (default: $ENDPOINT_URL)
    -r, --remove-source        Remove source folder after successful copy (for rename)
    -d, --delete               Use delete operation to remove a folder
    -l, --list                 Use list operation to view contents
    -R, --recursive            List contents recursively (for list operation)
    -v, --verbose              Enable verbose output
    -h, --help                 Show this help message

EXAMPLES:
    # Rename folder
    $0 postgres-v17 postgres-v17-backup

    # Rename with source removal (move operation)
    $0 -r postgres-v17 postgres-v17-backup

    # Remove a folder completely
    $0 -d postgres-v17-backup

    # List bucket contents
    $0 -l

    # List specific folder contents
    $0 -l postgres-v17

    # List folder contents recursively
    $0 -l -R postgres-v17

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
        -d|--delete)
            OPERATION="remove"
            shift
            ;;
        -l|--list)
            OPERATION="list"
            shift
            ;;
        -R|--recursive)
            RECURSIVE_LIST=true
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

# Apply SIGPIPE handler if we're being piped
if is_piped; then
    handle_sigpipe
fi

# Process based on the selected operation
if [[ "$OPERATION" == "rename" ]]; then
    # Check if we have the required arguments for rename
    if [[ $# -ne 2 ]]; then
        echo "Error: SOURCE_FOLDER and TARGET_FOLDER are required for rename operation" >&2
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
        echo "Warning: Target folder '${TARGET_FOLDER}' already exists in bucket '$BUCKET'" >&2
        read -p "Do you want to overwrite the existing target folder? (y/N): " overwrite
        if [[ "${overwrite,,}" != "y" ]]; then
            echo "Operation aborted by user." >&2
            exit 1
        fi

        # Remove the target folder first
        echo "Removing existing target folder ${TARGET_FOLDER} ..."
        log "Running: aws s3 rm ${BUCKET}/${TARGET_FOLDER}/ --recursive --endpoint-url $ENDPOINT_URL"

        if aws s3 rm "${BUCKET}/${TARGET_FOLDER}/" \
            --recursive --endpoint-url "$ENDPOINT_URL"; then
            echo "✓ Successfully removed existing target folder ${TARGET_FOLDER}"
        else
            echo "✗ Failed to remove existing target folder" >&2
            exit 1
        fi
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

    echo "✓ Rename operation completed successfully!"

elif [[ "$OPERATION" == "remove" ]]; then
    # Check if we have the required argument for remove
    if [[ $# -ne 1 ]]; then
        echo "Error: FOLDER_TO_REMOVE is required for remove operation" >&2
        usage
        exit 1
    fi

    FOLDER_TO_REMOVE="$1"

    # Validate input
    if [[ -z "$FOLDER_TO_REMOVE" ]]; then
        echo "Error: FOLDER_TO_REMOVE cannot be empty" >&2
        exit 1
    fi

    log "Starting S3 folder remove operation"
    log "Folder to remove: ${BUCKET}/${FOLDER_TO_REMOVE}/"
    log "Endpoint: $ENDPOINT_URL"

    # Check if folder exists
    if ! folder_exists "$FOLDER_TO_REMOVE"; then
        echo "Error: Folder '${FOLDER_TO_REMOVE}' does not exist in bucket '$BUCKET'" >&2
        exit 1
    fi

    # Confirm removal
    read -p "Are you sure you want to permanently remove folder '${FOLDER_TO_REMOVE}'? This cannot be undone. (y/N): " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        echo "Operation aborted by user." >&2
        exit 1
    fi

    # Perform the remove operation
    echo "Removing folder ${BUCKET}/${FOLDER_TO_REMOVE}/ ..."
    log "Running: aws s3 rm ${BUCKET}/${FOLDER_TO_REMOVE}/ --recursive --endpoint-url $ENDPOINT_URL"

    if aws s3 rm "${BUCKET}/${FOLDER_TO_REMOVE}/" \
        --recursive --endpoint-url "$ENDPOINT_URL"; then
        echo "✓ Successfully removed folder ${FOLDER_TO_REMOVE}"
        log "Remove operation completed successfully"
    else
        echo "✗ Failed to remove folder" >&2
        exit 1
    fi

    echo "✓ Remove operation completed successfully!"

elif [[ "$OPERATION" == "list" ]]; then
    # List operation accepts an optional folder path
    FOLDER_PATH=""
    if [[ $# -eq 1 ]]; then
        FOLDER_PATH="$1/"
    fi

    log "Starting S3 folder list operation"
    log "Path to list: ${BUCKET}/${FOLDER_PATH}"
    log "Endpoint: $ENDPOINT_URL"
    log "Recursive: $RECURSIVE_LIST"

    # Build the list command
    LIST_CMD="aws s3 ls ${BUCKET}/${FOLDER_PATH} --endpoint-url ${ENDPOINT_URL}"
    if [[ "$RECURSIVE_LIST" == "true" ]]; then
        LIST_CMD+=" --recursive"
    fi

    echo "Listing contents of ${BUCKET}/${FOLDER_PATH} ..."
    log "Running: $LIST_CMD"

    # When being piped, don't show extra output to avoid broken pipe errors
    if is_piped; then
        # Just run the command without checking exit status
        eval "$LIST_CMD" || true
        exit 0
    else
        # Not being piped, so check exit status and show success message
        if ! eval "$LIST_CMD"; then
            echo "✗ Failed to list contents" >&2
            exit 1
        fi
        echo "✓ List operation completed successfully!"
    fi
fi

log "S3 backup manager operation finished"

# Only show bucket structure if not being piped
if ! is_piped; then
    echo ""
    echo "Current bucket structure:"
    aws s3 ls "$BUCKET/" --endpoint-url "$ENDPOINT_URL"
fi
