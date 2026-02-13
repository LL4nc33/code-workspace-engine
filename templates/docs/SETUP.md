# Setup: {{PROJECT_NAME}}

## Prerequisites

- [Runtime] v[version]+
- [Package manager]
- [Other dependencies]

## Installation

```bash
# Clone
git clone {{REPO_URL}}
cd {{PROJECT_NAME}}

# Install dependencies
{{INSTALL_COMMAND}}

# Environment
cp .env.example .env
# Edit .env with your settings
```

## Development

```bash
# Start dev server
{{DEV_COMMAND}}

# Run tests
{{TEST_COMMAND}}

# Lint
{{LINT_COMMAND}}
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NODE_ENV` | No | `development` | Environment |
| `PORT` | No | `3000` | Server port |

## Project Structure

```
{{PROJECT_NAME}}/
├── src/           # Source code
├── tests/         # Test files
├── docs/          # Documentation
└── ...
```

## Troubleshooting

### Common Issues

**Issue:** [description]
**Fix:** [solution]
