#!/bin/bash

# ==============================================================================
# BayesFlow UV Test Runner Script
# ==============================================================================
# This script downloads a specific BayesFlow branch, creates a UV environment,
# installs dependencies, and runs tests automatically.
#
# Usage:
#   ./run_bayesflow_tests.sh [OPTIONS]
#
# Examples:
#   ./run_bayesflow_tests.sh                                    # Use defaults
#   ./run_bayesflow_tests.sh -r bayesflow-org/bayesflow -b main # Specific repo/branch
#   ./run_bayesflow_tests.sh -p 3.11.2 -k tensorflow           # Custom Python/backend
# ==============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Default configuration
DEFAULT_REPO="bayesflow-org/bayesflow"
DEFAULT_BRANCH="main"
DEFAULT_PYTHON_VERSION="3.10.8"
DEFAULT_BACKEND="tensorflow"
DEFAULT_TEST_CMD="python -m pytest tests/test_approximators/test_approximator_standardization/test_approximator_standardization.py"

# Script configuration
REPO="${DEFAULT_REPO}"
BRANCH="${DEFAULT_BRANCH}"
PYTHON_VERSION="${DEFAULT_PYTHON_VERSION}"
BACKEND="${DEFAULT_BACKEND}"
TEST_CMD="${DEFAULT_TEST_CMD}"
CLEANUP_ON_EXIT=false
VERBOSE=false
VENV_NAME="bayesflow-test-env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ==============================================================================
# Helper Functions
# ==============================================================================

print_banner() {
    local title="$1"
    local char="${2:-═}"
    local width=80
    echo -e "${CYAN}"
    printf "╔"
    printf "%*s" $((width-2)) | tr ' ' "${char}"
    printf "╗\n"
    printf "║%*s║\n" $((width-2)) "$(printf "%*s" $(((width-2+${#title})/2)) "$title")"
    printf "╚"
    printf "%*s" $((width-2)) | tr ' ' "${char}"
    printf "╝\n"
    echo -e "${NC}"
}

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $*${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO] $*${NC}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $*${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $*${NC}"
}

log_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG] $*${NC}"
    fi
}

show_help() {
    cat << EOF
BayesFlow UV Test Runner

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -r, --repo REPO          Repository to clone (default: ${DEFAULT_REPO})
    -b, --branch BRANCH      Branch to checkout (default: ${DEFAULT_BRANCH})
    -p, --python VERSION     Python version (default: ${DEFAULT_PYTHON_VERSION})
    -k, --backend BACKEND    Keras backend: tensorflow, jax, torch/pytorch (default: ${DEFAULT_BACKEND})
    -t, --test-cmd CMD       Custom test command (default: approximator standardization test)
    -n, --venv-name NAME     Virtual environment name (default: ${VENV_NAME})
    -c, --cleanup            Clean up on exit
    -v, --verbose            Verbose output
    -h, --help              Show this help

EXAMPLES:
    # Use all defaults
    $0

    # Test specific branch
    $0 -r SermetPekin/bayesflow -b issue-591-fix

    # Custom Python version and backend
    $0 -p 3.11.2 -k jax

    # Test with PyTorch backend
    $0 -k torch

    # Custom test command
    $0 -t "python -m pytest tests/ -v"

    # Full customization
    $0 -r bayesflow-org/bayesflow -b main -p 3.10.8 -k jax -v -c

EOF
}

cleanup() {
    if [[ "$CLEANUP_ON_EXIT" == "true" ]]; then
        log_warn "Cleaning up..."
        if [[ -d "external" ]]; then
            log_info "Removing external directory..."
            rm -rf external
        fi
        if command -v uv >/dev/null 2>&1; then
            if uv venv list | grep -q "$VENV_NAME"; then
                log_info "Removing UV virtual environment..."
                uv venv remove "$VENV_NAME" || true
            fi
        fi
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# ==============================================================================
# Argument Parsing
# ==============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repo)
            REPO="$2"
            shift 2
            ;;
        -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
        -p|--python)
            PYTHON_VERSION="$2"
            shift 2
            ;;
        -k|--backend)
            BACKEND="$2"
            shift 2
            ;;
        -t|--test-cmd)
            TEST_CMD="$2"
            shift 2
            ;;
        -n|--venv-name)
            VENV_NAME="$2"
            shift 2
            ;;
        -c|--cleanup)
            CLEANUP_ON_EXIT=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# ==============================================================================
# Main Script
# ==============================================================================

main() {
    print_banner "🚀 BAYESFLOW UV TEST RUNNER 🚀"
    
    # Display configuration
    log_info "Configuration:"
    echo "  📁 Repository: $REPO"
    echo "  🌿 Branch: $BRANCH"
    echo "  🐍 Python: $PYTHON_VERSION"
    echo "  ⚡ Backend: $BACKEND"
    echo "  🧪 Test Command: $TEST_CMD"
    echo "  📦 Environment: $VENV_NAME"
    echo "  🧹 Cleanup: $CLEANUP_ON_EXIT"
    echo ""

    # Step 1: Check prerequisites
    print_banner "📋 CHECKING PREREQUISITES"
    check_prerequisites

    # Step 2: Install UV if needed
    print_banner "📦 SETTING UP UV PACKAGE MANAGER"
    install_uv

    # Step 3: Clone repository
    print_banner "📥 CLONING BAYESFLOW REPOSITORY"
    clone_repository

    # Step 4: Create UV environment
    print_banner "🐍 CREATING UV ENVIRONMENT"
    create_uv_environment

    # Step 5: Install dependencies
    print_banner "📦 INSTALLING DEPENDENCIES"
    install_dependencies

    # Step 6: Verify environment
    print_banner "✅ VERIFYING ENVIRONMENT"
    verify_environment

    # Step 7: Run tests
    print_banner "🧪 RUNNING TESTS"
    run_tests

    log "🎉 Test execution completed successfully!"
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check git
    if ! command -v git >/dev/null 2>&1; then
        log_error "Git is not installed. Please install git and try again."
        exit 1
    fi
    log_debug "✓ Git found: $(git --version)"

    # Check Python (basic check)
    if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
        log_error "Python is not installed. Please install Python and try again."
        exit 1
    fi
    log_debug "✓ Python found"

    # Check curl for UV installation
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl is not installed. Please install curl and try again."
        exit 1
    fi
    log_debug "✓ curl found"

    log "✅ All prerequisites satisfied"
}

install_uv() {
    if command -v uv >/dev/null 2>&1; then
        log "UV is already installed: $(uv --version)"
        return
    fi

    log "Installing UV package manager..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Add to PATH for current session
    export PATH="$HOME/.cargo/bin:$PATH"
    
    # Verify installation
    if command -v uv >/dev/null 2>&1; then
        log "✅ UV installed successfully: $(uv --version)"
    else
        log_error "Failed to install UV or add it to PATH"
        exit 1
    fi
}

clone_repository() {
    local target_dir="external/bayesflow"
    
    log "Checking repository status..."
    
    # Check if we should clone
    local should_clone=false
    
    if [[ ! -d "$target_dir" ]]; then
        log_info "Repository not found, will clone"
        should_clone=true
    elif [[ ! -d "$target_dir/.git" ]]; then
        log_warn "Invalid repository found, will re-clone"
        rm -rf "$target_dir"
        should_clone=true
    else
        # Check if it's the same repo and branch
        local current_remote current_branch
        cd "$target_dir"
        current_remote=$(git remote get-url origin 2>/dev/null | sed 's/.*github\.com[:/]\([^.]*\).*/\1/' || echo "")
        current_branch=$(git branch --show-current 2>/dev/null || echo "")
        cd - >/dev/null
        
        if [[ "$current_remote" != "$REPO" ]] || [[ "$current_branch" != "$BRANCH" ]]; then
            log_warn "Different repo/branch detected, will re-clone"
            log_debug "Current: $current_remote@$current_branch"
            log_debug "Requested: $REPO@$BRANCH"
            rm -rf "$target_dir"
            should_clone=true
        else
            log "✅ Repository already cloned with correct repo/branch"
            log_debug "Using existing: $REPO@$BRANCH"
        fi
    fi
    
    if [[ "$should_clone" == "true" ]]; then
        log "Cloning $REPO (branch: $BRANCH)..."
        
        # Create parent directory
        mkdir -p "$(dirname "$target_dir")"

        # Clone repository
        if ! git clone --single-branch --branch "$BRANCH" "https://github.com/$REPO.git" "$target_dir"; then
            log_error "Failed to clone repository: $REPO (branch: $BRANCH)"
            exit 1
        fi
        
        log "✅ Repository cloned successfully"
    fi
    
    # Verify clone
    if [[ -d "$target_dir/.git" ]]; then
        log_debug "✓ Git repository structure confirmed"
    fi
    
    if [[ -d "$target_dir/tests" ]]; then
        log_debug "✓ Tests directory found"
    else
        log_warn "Tests directory not found - this might cause test failures"
    fi
}

create_uv_environment() {
    log "Creating UV virtual environment with Python $PYTHON_VERSION..."
    
    # Remove existing environment if it exists
    if uv venv list 2>/dev/null | grep -q "$VENV_NAME"; then
        log_warn "Removing existing environment: $VENV_NAME"
        uv venv remove "$VENV_NAME" || true
    fi

    # Check if Python version is available
    log "Checking Python $PYTHON_VERSION availability..."
    local final_python_version="$PYTHON_VERSION"
    
    if uv python list | grep -q "$PYTHON_VERSION"; then
        log_debug "✓ Python $PYTHON_VERSION already available"
    else
        log_warn "Python $PYTHON_VERSION not found"
        
        # Try to find a close match (same major.minor)
        local major_minor=$(echo "$PYTHON_VERSION" | cut -d. -f1,2)
        log_info "Looking for Python $major_minor.x alternatives..."
        
        # Get available versions for the same major.minor
        local available_versions=$(uv python list | grep "cpython-$major_minor" | head -3)
        
        if [[ -n "$available_versions" ]]; then
            log_info "Available Python $major_minor.x versions:"
            echo "$available_versions"
            
            # Try to find the first available version for this major.minor
            local fallback_version=$(echo "$available_versions" | head -1 | grep -o "cpython-[0-9]\+\.[0-9]\+\.[0-9]\+" | head -1 | sed 's/cpython-//')
            
            if [[ -n "$fallback_version" ]]; then
                log_info "Using closest available version: $fallback_version"
                
                # Check if it needs to be downloaded
                if echo "$available_versions" | head -1 | grep -q "<download available>"; then
                    log "Installing Python $fallback_version..."
                    if ! uv python install "$fallback_version"; then
                        log_error "Failed to install Python $fallback_version"
                        log_info "All available Python versions:"
                        uv python list || true
                        exit 1
                    fi
                fi
                final_python_version="$fallback_version"
            else
                log_error "No suitable Python $major_minor.x version found"
                log_info "All available Python versions:"
                uv python list || true
                exit 1
            fi
        else
            log_error "No Python $major_minor.x versions available"
            log_info "All available Python versions:"
            uv python list || true
            exit 1
        fi
    fi

    # Create new environment
    if ! uv venv "$VENV_NAME" --python "$final_python_version"; then
        log_error "Failed to create UV environment with Python $final_python_version"
        log_info "Available Python versions on system:"
        uv python list || true
        exit 1
    fi

    log "✅ UV environment created successfully with Python $final_python_version"
}

install_dependencies() {
    local bayesflow_dir="external/bayesflow"
    
    log "Installing BayesFlow and dependencies..."
    
    # Get the absolute path to the virtual environment first (before changing directories)
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    local venv_path="$(cd "$script_dir" && pwd)/$VENV_NAME"
    log_debug "Using virtual environment path: $venv_path"
    
    # Change to BayesFlow directory
    if ! cd "$bayesflow_dir"; then
        log_error "Failed to change to BayesFlow directory: $bayesflow_dir"
        exit 1
    fi

    # Check for setup files
    if [[ ! -f "pyproject.toml" && ! -f "setup.py" && ! -f "setup.cfg" ]]; then
        log_error "No setup files found in BayesFlow directory"
        exit 1
    fi

    # Install BayesFlow with all dependencies
    log "Installing BayesFlow with all dependencies..."
    if ! uv pip install --python "$venv_path" ".[all]"; then
        log_error "Failed to install BayesFlow dependencies"
        cd - >/dev/null
        exit 1
    fi

    # Install backend-specific dependencies based on BACKEND variable
    case "$BACKEND" in
        "tensorflow")
            log "Installing TensorFlow backend..."
            if ! uv pip install --python "$venv_path" tensorflow; then
                log_error "Failed to install TensorFlow"
                cd - >/dev/null
                exit 1
            fi
            ;;
        "jax")
            log "Installing JAX backend..."
            if ! uv pip install --python "$venv_path" "jax[cpu]" jaxlib; then
                log_error "Failed to install JAX"
                cd - >/dev/null
                exit 1
            fi
            ;;
        "torch"|"pytorch")
            log "Installing PyTorch backend..."
            if ! uv pip install --python "$venv_path" torch; then
                log_error "Failed to install PyTorch"
                cd - >/dev/null
                exit 1
            fi
            ;;
        *)
            log_warn "Unknown backend '$BACKEND', installing TensorFlow as fallback..."
            if ! uv pip install --python "$venv_path" tensorflow; then
                log_error "Failed to install TensorFlow"
                cd - >/dev/null
                exit 1
            fi
            ;;
    esac

    # Ensure pytest is installed
    log "Ensuring pytest is properly installed..."
    if ! uv pip install --python "$venv_path" pytest; then
        log_error "Failed to install pytest"
        cd - >/dev/null
        exit 1
    fi

    # Go back to original directory
    cd - >/dev/null

    log "✅ Dependencies installed successfully"
}

verify_environment() {
    local bayesflow_dir="external/bayesflow"
    
    log "Verifying environment setup..."
    
    # Set environment variables
    export KERAS_BACKEND="$BACKEND"
    log_debug "Set KERAS_BACKEND=$BACKEND"

    # Get the absolute path to the virtual environment
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    local venv_path="$(cd "$script_dir" && pwd)/$VENV_NAME"

    # Test Python and package imports
    log "Testing Python and package imports..."
    
    # Test basic Python
    if ! uv run --python "$venv_path" python --version; then
        log_error "Failed to run Python in UV environment"
        exit 1
    fi

    # Test backend-specific imports
    case "$BACKEND" in
        "tensorflow")
            if ! uv run --python "$venv_path" python -c "import tensorflow as tf; print(f'TensorFlow version: {tf.__version__}')"; then
                log_error "Failed to import TensorFlow"
                exit 1
            fi
            ;;
        "jax")
            if ! uv run --python "$venv_path" python -c "import jax; import jaxlib; print(f'JAX version: {jax.__version__}, JAXlib version: {jaxlib.__version__}')"; then
                log_error "Failed to import JAX"
                exit 1
            fi
            ;;
        "torch"|"pytorch")
            if ! uv run --python "$venv_path" python -c "import torch; print(f'PyTorch version: {torch.__version__}')"; then
                log_error "Failed to import PyTorch"
                exit 1
            fi
            ;;
        *)
            log_warn "Unknown backend '$BACKEND', skipping backend-specific verification"
            ;;
    esac

    # Test pytest availability
    if ! uv run --python "$venv_path" python -c "import pytest; print(f'pytest version: {pytest.__version__}')"; then
        log_error "Failed to import pytest"
        exit 1
    fi

    # Test BayesFlow import (from the installed package)
    if ! uv run --python "$venv_path" python -c "import bayesflow; print('BayesFlow imported successfully')"; then
        log_warn "Failed to import BayesFlow - this might be expected if not properly installed"
    fi

    # Show environment info
    log "Environment information:"
    echo "  🐍 Python: $(uv run --python "$venv_path" python --version)"
    echo "  ⚡ Backend: $KERAS_BACKEND"
    echo "  📦 UV Environment: $VENV_NAME"

    log "✅ Environment verification completed"
}

run_tests() {
    local bayesflow_dir="external/bayesflow"
    
    log "Running tests with command: $TEST_CMD"
    
    # Get the absolute path to the virtual environment 
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    local venv_path="$(cd "$script_dir" && pwd)/$VENV_NAME"
    log_debug "Virtual environment path: $venv_path"
    
    # Verify that the BayesFlow directory exists
    if [[ ! -d "$bayesflow_dir" ]]; then
        log_error "BayesFlow directory not found: $bayesflow_dir"
        exit 1
    fi

    # Set environment variables
    export KERAS_BACKEND="$BACKEND"
    
    # Convert the test command to use full paths from root directory
    local full_test_cmd="$TEST_CMD"
    # Replace "tests/" with "external/bayesflow/tests/" 
    full_test_cmd="${full_test_cmd//tests\//$bayesflow_dir/tests/}"
    
    log_debug "Modified test command: $full_test_cmd"

    # Run tests from the root directory using full paths
    log "Executing: $full_test_cmd"
    if uv run --python "$venv_path" $full_test_cmd; then
        log "✅ Tests completed successfully!"
        test_result=0
    else
        log_error "Tests failed!"
        test_result=1
    fi

    return $test_result
}

# ==============================================================================
# Script Execution
# ==============================================================================

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi