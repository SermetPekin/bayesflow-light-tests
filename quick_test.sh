#!/bin/bash

# Simple BayesFlow Test Runner
# Usage: ./quick_test.sh [repo] [branch] [python_version] [backend]

set -e

# Configuration
REPO="${1:-bayesflow-org/bayesflow}"
BRANCH="${2:-main}"
PYTHON_VERSION="${3:-3.10.8}"
BACKEND="${4:-tensorflow}"
VENV_NAME="bf-test"

echo "🚀 Quick BayesFlow Test Setup"
echo "Repository: $REPO"
echo "Branch: $BRANCH" 
echo "Python: $PYTHON_VERSION"
echo "Backend: $BACKEND"
echo ""

# Install UV if needed
if ! command -v uv >/dev/null 2>&1; then
    echo "📦 Installing UV..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Clean up previous environment (but keep repo if it exists)
echo "🧹 Cleaning up previous environment..."
uv venv remove "$VENV_NAME" 2>/dev/null || true

# Clone repository only if it doesn't exist or is different
REPO_DIR="external/bayesflow"
SHOULD_CLONE=false

if [[ ! -d "$REPO_DIR" ]]; then
    echo "📥 Repository not found, will clone..."
    SHOULD_CLONE=true
elif [[ ! -d "$REPO_DIR/.git" ]]; then
    echo "📥 Invalid repository found, will re-clone..."
    rm -rf "$REPO_DIR"
    SHOULD_CLONE=true
else
    # Check if it's the same repo and branch
    cd "$REPO_DIR"
    CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null | sed 's/.*github\.com[:/]\([^.]*\).*/\1/' || echo "")
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    cd - >/dev/null
    
    if [[ "$CURRENT_REMOTE" != "$REPO" ]] || [[ "$CURRENT_BRANCH" != "$BRANCH" ]]; then
        echo "📥 Different repo/branch detected, will re-clone..."
        echo "  Current: $CURRENT_REMOTE@$CURRENT_BRANCH"
        echo "  Requested: $REPO@$BRANCH"
        rm -rf "$REPO_DIR"
        SHOULD_CLONE=true
    else
        echo "✅ Repository already cloned with correct repo/branch"
        echo "  Using existing: $REPO@$BRANCH"
    fi
fi

if [[ "$SHOULD_CLONE" == "true" ]]; then
    echo "📥 Cloning $REPO@$BRANCH..."
    mkdir -p external
    git clone --single-branch --branch "$BRANCH" "https://github.com/$REPO.git" "$REPO_DIR"
fi

# Check Python availability and install if needed
echo "🐍 Checking Python $PYTHON_VERSION availability..."

# First check exact match
if uv python list | grep -q "$PYTHON_VERSION"; then
    echo "✅ Python $PYTHON_VERSION already available"
    FINAL_PYTHON_VERSION="$PYTHON_VERSION"
else
    echo "⚠️  Python $PYTHON_VERSION not found"
    
    # Try to find a close match (same major.minor)
    MAJOR_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f1,2)
    echo "🔍 Looking for Python $MAJOR_MINOR.x alternatives..."
    
    # Get available versions for the same major.minor
    AVAILABLE_VERSIONS=$(uv python list | grep "cpython-$MAJOR_MINOR" | head -3)
    
    if [[ -n "$AVAILABLE_VERSIONS" ]]; then
        echo "📋 Available Python $MAJOR_MINOR.x versions:"
        echo "$AVAILABLE_VERSIONS"
        echo ""
        
        # Try to find the first available version for this major.minor
        FALLBACK_VERSION=$(echo "$AVAILABLE_VERSIONS" | head -1 | grep -o "cpython-[0-9]\+\.[0-9]\+\.[0-9]\+" | head -1 | sed 's/cpython-//')
        
        if [[ -n "$FALLBACK_VERSION" ]]; then
            echo "💡 Using closest available version: $FALLBACK_VERSION"
            
            # Check if it's already installed or needs download
            if echo "$AVAILABLE_VERSIONS" | head -1 | grep -q "<download available>"; then
                echo "📦 Installing Python $FALLBACK_VERSION..."
                if ! uv python install "$FALLBACK_VERSION"; then
                    echo "❌ Failed to install Python $FALLBACK_VERSION"
                    echo "📋 All available Python versions:"
                    uv python list
                    exit 1
                fi
            fi
            FINAL_PYTHON_VERSION="$FALLBACK_VERSION"
        else
            echo "❌ No suitable Python $MAJOR_MINOR.x version found"
            echo "📋 All available Python versions:"
            uv python list
            exit 1
        fi
    else
        echo "❌ No Python $MAJOR_MINOR.x versions available"
        echo "📋 All available Python versions:"
        uv python list
        exit 1
    fi
fi

# Create environment
echo "🐍 Creating UV environment with Python $FINAL_PYTHON_VERSION..."
# Ensure we're in the root directory when creating the environment
cd "$(dirname "$0")"
ROOT_DIR="$(pwd)"
echo "Creating environment in: $ROOT_DIR"
uv venv "$VENV_NAME" --python "$FINAL_PYTHON_VERSION"

# Install dependencies
echo "📦 Installing dependencies..."
cd external/bayesflow

# Get the absolute path to the virtual environment
VENV_PATH="$ROOT_DIR/$VENV_NAME"
echo "Using virtual environment: $VENV_PATH"

# Install BayesFlow with all dependencies
uv pip install --python "$VENV_PATH" ".[all]"

# Install backend-specific dependencies
case "$BACKEND" in
    "tensorflow")
        echo "📦 Installing TensorFlow backend..."
        uv pip install --python "$VENV_PATH" tensorflow
        ;;
    "jax")
        echo "📦 Installing JAX backend..."
        uv pip install --python "$VENV_PATH" "jax[cpu]" jaxlib
        ;;
    "torch"|"pytorch")
        echo "📦 Installing PyTorch backend..."
        uv pip install --python "$VENV_PATH" torch
        ;;
    *)
        echo "⚠️  Unknown backend '$BACKEND', installing TensorFlow as fallback..."
        uv pip install --python "$VENV_PATH" tensorflow
        ;;
esac

# Always install pytest
uv pip install --python "$VENV_PATH" pytest

# Run test
echo "🧪 Running test with $BACKEND backend..."
export KERAS_BACKEND="$BACKEND"

# Change back to root directory before running the test to ensure correct venv path
cd "$ROOT_DIR"
uv run --python "$VENV_PATH" python -m pytest external/bayesflow/tests/test_approximators/test_approximator_standardization/test_approximator_standardization.py

echo "✅ Done!"