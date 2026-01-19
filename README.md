# cckill

A macOS CLI tool to kill Claude Code CLI processes.

## Installation

The easiest way to install cckill is to use [nest](https://github.com/mtj0928/nest).

```bash
nest install Ryu0118/cckill
```

### Swift Package Manager

```bash
git clone https://github.com/Ryu0118/cckill.git
cd cckill
swift build -c release
cp .build/release/cckill /usr/local/bin/
```

## Usage

### List Processes

```bash
cckill --list
# or
cckill -l
```

Output:
```
Claude Code Processes:
  PID 12345: claude (CPU: 5.2%, MEM: 1.3%)
  PID 12346: claude --resume (CPU: 0.1%, MEM: 0.8%)
```

### Kill Processes (SIGTERM)

```bash
cckill
```

### Force Kill (SIGKILL)

```bash
cckill --force
# or
cckill -f
```

### Help

```bash
cckill --help
```

## Requirements

- macOS 15.0+
- Swift 6.2+

## License

MIT License
