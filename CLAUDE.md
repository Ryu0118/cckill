# cckill

macOS CLI tool to kill Claude Code CLI processes.

## Architecture

```
Sources/
├── cckill/           # Entry point
├── CCKillCLI/        # CLI command definition
└── CCKillKit/        # Reusable library
    ├── Models/       # Data models
    └── Errors/       # Error types
```

## Process Detection Logic

To distinguish from Claude Desktop App:

1. `comm == "claude"`
2. args does not contain `/Applications/Claude.app`
3. args starts with `claude`

## Build & Run

```bash
swift build
swift run cckill --list
swift run cckill --force
```
