# BayesFlow Light Tests 🚀

[![GitHub Actions](https://github.com/SermetPekin/bayesflow-light-tests/workflows/Complete%20Clone%20Test%20BayesFlow/badge.svg)](https://github.com/SermetPekin/bayesflow-light-tests/actions)
[![Python](https://img.shields.io/badge/python-3.10%2B-blue.svg)](https://www.python.org/downloads/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A lightweight testing repository for rapid BayesFlow validation across multiple platforms and Python versions. This project enables developers to quickly test BayesFlow changes without consuming resources from the main repository's CI/CD pipeline.

## 🎯 Purpose

**Problem**: Comprehensive tests in the main BayesFlow repository consume significant CI/CD resources and time, making rapid development iterations challenging.

**Solution**: A dedicated testing environment that allows:
- 🚀 **Fast feedback loops** during development
- 🌍 **Multi-platform testing** (Ubuntu, macOS, Windows)
- 🐍 **Multi-version Python support** (3.10.8, 3.11.2, etc.)
- ⚡ **Flexible backend testing** (TensorFlow, JAX, PyTorch, NumPy)
- 🎯 **Targeted test execution** instead of full test suites

## 🛠️ Features

### GitHub Actions Workflows
- **`q5.yaml`**: Sparse checkout workflow with optimized file fetching
- **`q_all.yaml`**: Complete repository clone for comprehensive testing
- **Manual triggers**: Test any repository branch with custom parameters

### Python Test Runner
- **Local execution**: Run tests without GitHub Actions
- **Configuration files**: JSON-based test matrix setup
- **Cross-platform**: Works on any system with Python

### Default Test Configuration
```bash
DEFAULT_PYTEST_CMD: 'python -m pytest tests/test_approximators/test_approximator_standardization/test_approximator_standardization.py'
```

## 🚀 Quick Start

### Using GitHub Actions (Manual Trigger)
1. Go to [Actions](https://github.com/SermetPekin/bayesflow-light-tests/actions)
2. Select "Complete Clone Test BayesFlow" workflow
3. Click "Run workflow"
4. Configure parameters:
   - **Repository**: `bayesflow-org/bayesflow` (or your fork)
   - **Branch**: `main` (or feature branch)
   - **Python Version**: `3.10.8`
   - **OS**: `ubuntu`, `windows`, `macos`, or `all`
   - **Backend**: `tensorflow`, `jax`, `torch`, `numpy`

### Using Local Python Runner
```bash
# Basic usage
python bayesflow_test_runner.py

# Test specific branch
python bayesflow_test_runner.py --repo username/bayesflow --branch feature-branch

# Multi-backend testing
python bayesflow_test_runner.py --backend jax

# Custom test command
python bayesflow_test_runner.py --pytest-command "python -m pytest tests/ -v"
```

## 📊 Issue Reproduction Example

### Python 3.10.8 Cross-Platform Test Results

This repository successfully reproduces and tracks cross-platform issues. Example test results:

| Platform | Status | Details |
|----------|--------|---------|
| 🐧 **Ubuntu** | ❌ Failed | [View Run](https://github.com/SermetPekin/bayesflow-light-tests/actions/runs/18851109612/job/53787677842) |
| 🍎 **macOS** | ❌ Failed | [View Run](https://github.com/SermetPekin/bayesflow-light-tests/actions/runs/18851262436/job/53788192073) |
| 🪟 **Windows** | ❌ Failed | [View Run](https://github.com/SermetPekin/bayesflow-light-tests/actions/runs/18851335808/job/53788438944) |

> **Use Case**: These results demonstrate consistent cross-platform failures, helping identify environment-specific issues in BayesFlow approximator standardization tests.

## 🎛️ Manual Testing Interface

![Manual Testing for quick branch and versions](image.png)

*Interactive workflow dispatch interface for testing any repository branch with custom parameters.*

## 📁 Repository Structure

```
bayesflow-light-tests/
├── .github/workflows/
│   ├── q5.yaml              # Sparse checkout workflow
│   └── q_all.yaml           # Complete clone workflow
├── bayesflow_test_runner.py # Local Python test runner
├── test_config.json         # Example configuration
├── PYTHON_RUNNER_README.md  # Python runner documentation
└── README.md               # This file
```

## 🔧 Advanced Configuration

### JSON Configuration Example
```json
{
  "repo": "bayesflow-org/bayesflow",
  "branch": "main",
  "python_version": "3.10.8",
  "backend": "tensorflow",
  "pytest_command": "python -m pytest tests/test_approximators/ -v"
}
```

### Environment Variables
- `KERAS_BACKEND`: Set automatically based on backend choice
- `DEFAULT_PYTEST_CMD`: Configurable default test command

## 🤝 Contributing to BayesFlow

This repository serves as a **development tool** for BayesFlow contributors:

1. **Test your changes** before opening PRs
2. **Reproduce issues** across platforms
3. **Validate fixes** quickly and efficiently
4. **Debug environment-specific problems**

### Workflow Integration
- Complements main BayesFlow CI/CD (doesn't replace it)
- Provides fast feedback during development
- Reduces load on main repository resources

## 📈 Benefits

| Traditional Approach | BayesFlow Light Tests |
|---------------------|----------------------|
| ⏰ Long CI queue times | ⚡ Immediate execution |
| 💰 Consumes repo CI minutes | 🆓 Uses separate allocation |
| 🔒 Limited to repo members | 🌍 Anyone can fork and test |
| 🎯 Full test suite only | 🎛️ Targeted test execution |

## 🔗 Related Links

- **Main BayesFlow Repository**: [bayesflow-org/bayesflow](https://github.com/bayesflow-org/bayesflow)
- **Issue Tracking**: Use this repo to reproduce and validate issues
- **Documentation**: [BayesFlow Docs](https://bayesflow.org)

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ for the BayesFlow community**

```
  DEFAULT_PYTEST_CMD: 'python -m pytest bayesflow/tests/test_approximators/test_approximator_standardization/test_approximator_standardization.py'


```

## reproduction of the error (python 3.10.8)
```plaintext  

python 3.10.8
Failures 
ubuntu 
https://github.com/SermetPekin/bayesflow-light-tests/actions/runs/18851109612/job/53787677842

Mac 
https://github.com/SermetPekin/bayesflow-light-tests/actions/runs/18851262436/job/53788192073

Windows 
https://github.com/SermetPekin/bayesflow-light-tests/actions/runs/18851335808/job/53788438944

```

![Manual Testing for quick branch and versions](image.png)