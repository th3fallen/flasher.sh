# HDD Activity Light Flasher

A simple bash script to flash a hard drive's activity light in distinctive patterns, making it easy to physically identify which drive is which when you have multiple drives in a server.

## Overview

When you're looking at a server with multiple hard drives and need to identify which physical drive corresponds to `/dev/sda`, `/dev/sdb`, etc., this script creates recognizable disk I/O patterns that cause the specific drive's activity light to flash. No more guessing which drive is which!

## Features

- 🚨 **SOS Morse Code Pattern** - Classic distress signal (... --- ...)
- 💡 **Multiple Flash Patterns** - Blink, rapid, slow, and double-blink patterns
- 🎯 **Device-Specific** - Target any block device by path
- 🔒 **Safe & Non-Destructive** - Only reads from the drive, never writes
- ⚡ **Direct I/O** - Bypasses cache for guaranteed activity light response
- 🛑 **Easy Stop** - Just press Ctrl+C when you've found your drive

## Requirements

- Linux operating system
- Root access (sudo)
- Block device to flash (e.g., `/dev/sda`, `/dev/nvme0n1`)
- Standard utilities: `dd`, `lsblk`, `sleep`

## Installation

```bash
# Download the script
wget https://github.com/th3fallen/flasher.sh/raw/main/flasher.sh

# Make it executable
chmod +x flasher.sh
```

## Usage

### Basic Usage

```bash
# Flash /dev/sda with default SOS pattern
sudo ./flasher.sh -device /dev/sda
```

### Pattern Options

```bash
# Simple on/off blink pattern
sudo ./flasher.sh -device /dev/sda -p blink

# Fast blinking
sudo ./flasher.sh -device /dev/sdb -p rapid

# Slow blinking
sudo ./flasher.sh -device /dev/sdc -p slow

# Double-blink pattern
sudo ./flasher.sh -device /dev/nvme0n1 -p double

# SOS Morse code (default)
sudo ./flasher.sh -device /dev/sda -p morse_sos
```

### Help

```bash
./flasher.sh -h
```

## Available Patterns

| Pattern | Description | Visual |
|---------|-------------|--------|
| `morse_sos` | SOS in Morse code (... --- ...) | ░█░█░█░░███░███░███░░█░█░█░░░░ |
| `blink` | Simple on/off blinking | █░█░█░█░ |
| `rapid` | Fast blinking | █░█░█░█░█░█░ |
| `slow` | Slow blinking | ██░░██░░██░░ |
| `double` | Two quick flashes then pause | █░█░░░█░█░░░ |

## How It Works

1. **Direct Device Access** - The script reads directly from the specified block device (e.g., `/dev/sda`)
2. **Direct I/O Flag** - Uses `iflag=direct` to bypass the operating system's cache
3. **Physical Disk Activity** - Forces the drive controller to perform actual reads from the disk
4. **Activity Light Response** - The hard drive's activity LED responds to these read operations
5. **Pattern Creation** - Alternates between read phases (light on) and pause phases (light off)

## Safety

✅ **This script is completely safe:**
- It only **reads** from the device, never writes
- No data is modified or at risk
- Uses standard `dd` utility with read-only operations
- Can be safely interrupted with Ctrl+C at any time

## Use Cases

- **Drive Identification** - Figure out which physical drive is `/dev/sdb` in a multi-drive server
- **Hot-Swap Bays** - Identify drives in hot-swap caddies before removal
- **Failed Drive Replacement** - Locate the exact drive that needs replacing
- **Storage Expansion** - Verify new drives are detected in the correct bays
- **Cable Tracing** - Confirm which SATA/SAS port connects to which drive
- **RAID Configuration** - Identify physical drives before adding to arrays
- **Server Maintenance** - Verify drive bay numbers match device names

## Technical Details

### Default Configuration

- **Block Size**: 4KB (4096 bytes)
- **Block Count**: 256 blocks per read (1MB total)
- **I/O Method**: Direct I/O (bypasses cache)
- **Device Types**: Any block device (HDD, SSD, NVMe)

### Pattern Timing

- **Short flash (dot)**: ~3 quick reads
- **Long flash (dash)**: ~5 reads
- **Pause duration**: 0.1 to 2 seconds depending on pattern

## Troubleshooting

### Script exits immediately
- Ensure you're running as root: `sudo ./flasher.sh -device /dev/sda`
- Verify the device exists: `lsblk -d`
- Check device path is correct (e.g., `/dev/sda` not `sda`)

### Activity light not visible
- **SSDs/NVMe**: Some solid-state drives have less visible activity lights
- **RAID controllers**: Activity lights may behave differently on hardware RAID
- **Try a different pattern**: Use `-p rapid` or `-p blink` for more frequent flashing
- **Check the right light**: Ensure you're watching the correct drive's LED

### Permission denied
- Must run with sudo: `sudo ./flasher.sh -device /dev/sda`
- Verify device is accessible: `ls -l /dev/sda`

### List available devices
```bash
lsblk -d -o NAME,SIZE,MODEL
```

## Examples

### Identify which physical drive is /dev/sdb
```bash
# You have 4 drives in your server and need to replace /dev/sdb
# Run the flasher on /dev/sdb
sudo ./flasher.sh -device /dev/sdb -p morse_sos

# Look at your server's drive bays - the one flashing SOS is /dev/sdb
# Press Ctrl+C when found
```

### Identify multiple drives at once
```bash
# On one terminal/session - flash /dev/sda
sudo ./flasher.sh -device /dev/sda -p rapid

# On another terminal - flash /dev/sdb
sudo ./flasher.sh -device /dev/sdb -p slow

# On another terminal - flash /dev/sdc
sudo ./flasher.sh -device /dev/sdc -p double

# Now you can see which physical drive corresponds to each device
```

### Before removing a failed drive
```bash
# SMART reports /dev/sdf is failing
# Flash it to locate the physical drive
sudo ./flasher.sh -device /dev/sdf -p blink

# Remove the drive that's blinking
# Press Ctrl+C after you've identified it
```

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

### Ideas for enhancements:
- Custom pattern definition from command line
- LED brightness control (if supported by hardware)
- Multiple device flashing simultaneously
- Pattern speed adjustment
- Web interface for remote triggering

## License

MIT License - feel free to use and modify as needed.

## Acknowledgments

Inspired by the age-old problem of "where the hell is this drive on my server?" and countless trips to the rack with a laptop running `dd if=/dev/zero of=/tmp/test` in a loop.

---

**Note**: This script is intended for legitimate system administration purposes. Always ensure you have proper authorization before accessing any hardware or servers.

