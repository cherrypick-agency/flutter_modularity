#!/bin/bash
# Setup git hooks for auto-formatting and analysis

echo "Setting up git hooks..."

# Copy pre-commit hook
cp .githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo "✓ Git hooks installed successfully!"
echo ""
echo "Before each commit:"
echo "  • dart fix --apply (auto-fix lint issues)"
echo "  • dart format (code formatting)"
echo "  • flutter analyze (block commit on errors)"
