#!/bin/bash

# Hard Drive Activity Light Flasher
# Creates distinctive disk I/O patterns to help identify a server in a rack

# Configuration
DEVICE=""
PATTERN="morse_sos"
BLOCK_SIZE=4096  # 4KB blocks
BLOCK_COUNT=256  # 1MB total per write
CYCLE=0

# Cleanup on exit
cleanup() {
    echo -e "\nStopped"
    echo "Total cycles completed: $CYCLE"
    exit 0
}

trap cleanup EXIT INT TERM

# Help message
show_help() {
    cat << EOF
Usage: $(basename "$0") -device DEVICE [OPTIONS]

Flash hard drive activity light in identifiable patterns by reading from a specific device

Options:
    -device DEVICE  Device to read from (e.g., /dev/sda, /dev/nvme0n1)
                    REQUIRED
    -p PATTERN      Pattern to use (default: morse_sos)
                    Available: morse_sos, blink, rapid, slow, double
    -h              Show this help message

Examples:
    $(basename "$0") -device /dev/sda                    # SOS pattern on /dev/sda
    $(basename "$0") -device /dev/sdb -p blink           # Blink on /dev/sdb
    $(basename "$0") -device /dev/nvme0n1 -p rapid       # Rapid flash on NVMe drive

Patterns:
    morse_sos - SOS in Morse code (... --- ...)
    blink     - Simple on/off blinking
    rapid     - Fast blinking
    slow      - Slow blinking
    double    - Double-blink pattern

Note: This script must be run as root (sudo) to access block devices.
      It only READS from the device, so it's safe and non-destructive.
      Press Ctrl+C to stop.
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -device)
            DEVICE="$2"
            shift 2
            ;;
        -p)
            PATTERN="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use -h for help" >&2
            exit 1
            ;;
    esac
done

# Validate device parameter
if [ -z "$DEVICE" ]; then
    echo "Error: -device parameter is required" >&2
    echo "Use -h for help" >&2
    exit 1
fi

# Check if device exists
if [ ! -b "$DEVICE" ]; then
    echo "Error: $DEVICE is not a valid block device" >&2
    echo "Available devices:"
    lsblk -d -o NAME,SIZE,MODEL 2>/dev/null | grep -v "^loop" || ls -la /dev/sd* /dev/nvme* 2>/dev/null
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)" >&2
    exit 1
fi

# Read function - creates disk I/O for a given duration
read_data() {
    local duration=$1
    
    # Determine number of reads based on duration
    local num_reads=3
    if [ "$duration" -ge 1 ] 2>/dev/null; then
        num_reads=$((duration * 5))  # 5 reads per second for longer durations
    fi
    
    # Perform the reads
    local count=0
    while [ $count -lt $num_reads ]; do
        dd if="$DEVICE" of=/dev/null bs=$BLOCK_SIZE count=$BLOCK_COUNT iflag=direct 2>/dev/null
        count=$((count + 1))
    done
}

# Pause function
pause_data() {
    local duration=$1
    sleep "$duration"
}

# Flash pattern - takes pairs of on/off durations
flash_sequence() {
    local on_duration=$1
    local off_duration=$2
    
    echo -n "█"
    read_data "$on_duration"
    echo -n "░"
    pause_data "$off_duration"
}

# Pattern definitions (on_duration off_duration pairs)
run_pattern() {
    case $PATTERN in
        morse_sos)
            # S: dot-dot-dot (short flashes)
            flash_sequence 0 0.2
            flash_sequence 0 0.2
            flash_sequence 0 0.5
            # O: dash-dash-dash (long flashes)
            flash_sequence 1 0.2
            flash_sequence 1 0.2
            flash_sequence 1 0.5
            # S: dot-dot-dot (short flashes)
            flash_sequence 0 0.2
            flash_sequence 0 0.2
            flash_sequence 0 2.0
            ;;
        blink)
            flash_sequence 1 0.5
            ;;
        rapid)
            flash_sequence 0 0.1
            ;;
        slow)
            flash_sequence 2 1.0
            ;;
        double)
            flash_sequence 0 0.2
            flash_sequence 0 1.0
            ;;
        *)
            echo "Unknown pattern: $PATTERN"
            echo "Available: morse_sos, blink, rapid, slow, double"
            exit 1
            ;;
    esac
}

# Main execution
main() {
    echo "Starting '$PATTERN' pattern on $DEVICE..."
    echo "Device info:"
    lsblk "$DEVICE" -o NAME,SIZE,MODEL,MOUNTPOINT 2>/dev/null || echo "  $(basename $DEVICE)"
    echo "Press Ctrl+C to stop"
    echo "$(printf '%.0s-' {1..50})"
    
    while true; do
        CYCLE=$((CYCLE + 1))
        echo -n "Cycle $CYCLE: "
        run_pattern || true
        echo
    done
}

main