# Module 04 — Workflow Runners
### i27Academy — GitHub Actions Course

---

## Agenda

1. What is a runner
2. GitHub-hosted runners
3. Runner specifications
4. Pre-installed software
5. Running on multiple OS
6. Self-hosted runners (preview)

---

## 1. What is a Runner

A runner is the machine where a job executes. Every job in a workflow needs a runner — it is where all your steps actually run.

Think of it like a fresh laptop GitHub hands to your job. Your job does its work on it and when the job completes GitHub takes it back and wipes it completely clean. The next job gets a brand new machine.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest    # ← this tells GitHub which runner to use
    steps:
      - run: echo "I am running on a fresh Ubuntu machine"
```

The `runs-on:` field is mandatory in every job. Without it GitHub does not know where to run your steps.

---

## 2. GitHub-Hosted Runners

GitHub provides and manages a pool of virtual machines you can use for free. You simply specify which one you want — GitHub does the rest.

**Three operating systems available:**

```yaml
runs-on: ubuntu-latest      # Ubuntu Linux
runs-on: windows-latest     # Windows Server
runs-on: macos-latest       # macOS
```

**ubuntu-latest** is the most commonly used runner because:
```
→ Fastest startup time
→ Cheapest (1x minute multiplier)
→ Best tool pre-installation
→ Most CI/CD tooling built for Linux
```

---

### 2.1 Ubuntu Runner

**04.1.1-ubuntu-runner.yml**

```yaml
name: 04.1.1-Ubuntu-Runner

on:
  workflow_dispatch:

jobs:
  ubuntu-demo:
    runs-on: ubuntu-latest
    steps:
      - name: Print OS Info
        run: |
          echo "============================="
          echo "RUNNER INFORMATION"
          echo "============================="
          echo "OS        : ${{ runner.os }}"
          echo "Runner    : ${{ runner.name }}"
          echo "Arch      : ${{ runner.arch }}"
          echo "============================="

      - name: Check pre-installed tools
        run: |
          echo "Java version   : $(java -version 2>&1 | head -1)"
          echo "Docker version : $(docker --version)"
          echo "Git version    : $(git --version)"
          echo "Maven version  : $(mvn --version | head -1)"
          echo "Node version   : $(node --version)"
          echo "Python version : $(python3 --version)"

      - name: Check machine specs
        run: |
          echo "CPU cores : $(nproc)"
          echo "RAM       : $(free -h | grep Mem | awk '{print $2}')"
          echo "Disk      : $(df -h / | tail -1 | awk '{print $2}')"
```

Observe:
```
→ runner.os prints: Linux
→ runner.arch prints: X64
→ Java, Docker, Git, Maven, Node, Python are all pre-installed
→ 2 CPU cores, ~7GB RAM, ~14GB disk
```

---

### 2.2 Windows Runner

**04.1.2-windows-runner.yml**

```yaml
name: 04.1.2-Windows-Runner

on:
  workflow_dispatch:

jobs:
  windows-demo:
    runs-on: windows-latest
    steps:
      - name: Print OS Info
        run: |
          echo "============================="
          echo "RUNNER INFORMATION"
          echo "============================="
          echo "OS        : ${{ runner.os }}"
          echo "Runner    : ${{ runner.name }}"
          echo "Arch      : ${{ runner.arch }}"
          echo "============================="

      - name: Check pre-installed tools
        run: |
          Write-Host "Java version   : $(java -version 2>&1 | Select-String 'version')"
          Write-Host "Git version    : $(git --version)"
          Write-Host "Node version   : $(node --version)"
          Write-Host "Python version : $(python --version)"
        shell: pwsh

      - name: Check machine specs
        run: |
          $cpu = (Get-WmiObject Win32_ComputerSystem).NumberOfLogicalProcessors
          $ram = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
          Write-Host "CPU cores : $cpu"
          Write-Host "RAM (GB)  : $ram"
        shell: pwsh
```

Observe:
```
→ runner.os prints: Windows
→ Default shell on Windows is PowerShell
→ Use shell: pwsh for PowerShell commands
→ Use shell: bash if you want bash on Windows (Git Bash)
```

---

### 2.3 macOS Runner

**04.1.3-macos-runner.yml**

```yaml
name: 04.1.3-macOS-Runner

on:
  workflow_dispatch:

jobs:
  macos-demo:
    runs-on: macos-latest
    steps:
      - name: Print OS Info
        run: |
          echo "============================="
          echo "RUNNER INFORMATION"
          echo "============================="
          echo "OS        : ${{ runner.os }}"
          echo "Runner    : ${{ runner.name }}"
          echo "Arch      : ${{ runner.arch }}"
          echo "============================="

      - name: Check pre-installed tools
        run: |
          echo "Java version   : $(java -version 2>&1 | head -1)"
          echo "Git version    : $(git --version)"
          echo "Node version   : $(node --version)"
          echo "Python version : $(python3 --version)"
          echo "Brew version   : $(brew --version | head -1)"

      - name: Check machine specs
        run: |
          echo "CPU cores : $(sysctl -n hw.ncpu)"
          echo "RAM       : $(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 " GB"}')"
          echo "Disk      : $(df -h / | tail -1 | awk '{print $2}')"
```

Observe:
```
→ runner.os prints: macOS
→ Homebrew (brew) is pre-installed — useful for installing extra tools
→ macOS runners are the most expensive (10x minute multiplier)
→ Use only when macOS-specific testing is required
```

---

## 3. Runner Specifications

**04.2.1-runner-specs.yml**

```yaml
name: 04.2.1-Runner-Specs

on:
  workflow_dispatch:

jobs:
  runner-specs:
    runs-on: ubuntu-latest
    steps:
      - name: Runner context info
        run: |
          echo "============================="
          echo "RUNNER CONTEXT"
          echo "============================="
          echo "OS        : ${{ runner.os }}"
          echo "Arch      : ${{ runner.arch }}"
          echo "Name      : ${{ runner.name }}"
          echo "Temp dir  : ${{ runner.temp }}"
          echo "Tool cache: ${{ runner.tool_cache }}"
          echo "============================="

      - name: Machine specifications
        run: |
          echo "============================="
          echo "MACHINE SPECIFICATIONS"
          echo "============================="
          echo "CPU cores : $(nproc)"
          echo "RAM       : $(free -h | grep Mem | awk '{print $2}')"
          echo "Disk      : $(df -h / | tail -1 | awk '{print $2}')"
          echo "============================="

      - name: Pre-installed software
        run: |
          echo "============================="
          echo "PRE-INSTALLED SOFTWARE"
          echo "============================="
          echo "Java      : $(java -version 2>&1 | head -1)"
          echo "Maven     : $(mvn --version 2>&1 | head -1)"
          echo "Docker    : $(docker --version)"
          echo "Git       : $(git --version)"
          echo "Node      : $(node --version)"
          echo "Python    : $(python3 --version)"
          echo "kubectl   : $(kubectl version --client 2>&1 | head -1)"
          echo "AWS CLI   : $(aws --version 2>&1)"
          echo "============================="

      - name: Environment variables
        run: |
          echo "============================="
          echo "KEY ENVIRONMENT VARIABLES"
          echo "============================="
          echo "HOME             : $HOME"
          echo "RUNNER_OS        : $RUNNER_OS"
          echo "GITHUB_WORKSPACE : $GITHUB_WORKSPACE"
          echo "============================="
```

**Standard GitHub-hosted runner specs:**

| Runner | CPU | RAM | Disk | Minute multiplier |
|---|---|---|---|---|
| ubuntu-latest | 4 cores | 16 GB | 14 GB | 1x |
| windows-latest | 4 cores | 16 GB | 14 GB | 2x |
| macos-latest | 3 cores | 14 GB | 14 GB | 10x |

**The `runner.*` context:**

```
runner.os          → Linux / Windows / macOS
runner.arch        → X64 / ARM64
runner.name        → name of the runner machine
runner.temp        → path to a temporary directory
runner.tool_cache  → path where pre-installed tools are cached
```

---

## 4. Pre-Installed Software

GitHub-hosted runners come with a large set of tools pre-installed. You do not need to install common tools like Java, Node, Docker, Git — they are already there.

**What is pre-installed on ubuntu-latest:**

```
Languages:    Java, Node.js, Python, Ruby, Go, .NET
Build tools:  Maven, Gradle, npm, pip
Containers:   Docker, Docker Compose, Podman
Cloud CLIs:   AWS CLI, Azure CLI, Google Cloud SDK
DevOps:       kubectl, Helm, Terraform
Utilities:    Git, curl, wget, jq, zip, unzip
```

**Full list:** github.com/actions/runner-images

Even though Java is pre-installed, you should still use `actions/setup-java` in your workflows. Here is why:

```
Pre-installed Java  → fixed version, may not match your project
actions/setup-java  → you control the exact version
                      also sets JAVA_HOME correctly
                      enables Maven/Gradle caching
```

---

## 5. Running on Multiple OS

You can run the same job on multiple operating systems at the same time using a matrix strategy.

**04.3.1-multiple-os-matrix.yml**

```yaml
name: 04.3.1-Multiple-OS-Matrix

on:
  workflow_dispatch:

jobs:
  os-matrix:
    name: Run on ${{ matrix.os }}
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ ubuntu-latest, windows-latest, macos-latest ]

    steps:
      - name: Print OS Info
        run: |
          echo "Running on : ${{ runner.os }}"
          echo "Matrix OS  : ${{ matrix.os }}"
          echo "Arch       : ${{ runner.arch }}"

      - name: OS specific command (Linux)
        if: runner.os == 'Linux'
        run: echo "This step only runs on Linux"

      - name: OS specific command (Windows)
        if: runner.os == 'Windows'
        run: echo "This step only runs on Windows"
        shell: pwsh

      - name: OS specific command (macOS)
        if: runner.os == 'macOS'
        run: echo "This step only runs on macOS"
```

Observe:
```
→ Three parallel jobs created — one per OS
→ Run on ubuntu-latest
→ Run on windows-latest
→ Run on macos-latest
→ All three run at the same time
→ if: runner.os == 'Linux' — OS-specific steps
```

We cover matrix strategy in full detail in **Module 11 — Working with Matrices**.

---

## 6. Self-Hosted Runners (Preview)

In addition to GitHub-hosted runners you can register your own machine as a runner.

```yaml
runs-on: self-hosted                         # any self-hosted runner
runs-on: [ self-hosted, linux, java-21 ]    # target by labels
```

When to use self-hosted runners:
```
→ Need access to internal private network
→ Need custom software pre-installed
→ Want to reduce GitHub Actions minutes cost
→ Need more powerful hardware than GitHub provides
→ Deploy directly to a server — runner IS on the target machine
```

We cover self-hosted runners in full detail in **Module 15 — Self-Hosted Runners**.

---

## Module 04 Summary

- A runner is the machine where a job executes — every job needs `runs-on:`
- GitHub provides three hosted runners — ubuntu-latest, windows-latest, macos-latest
- ubuntu-latest is the most common — fastest, cheapest, best tooling
- GitHub-hosted runners are fresh VMs — wiped clean after every job
- Standard specs — 4 CPU cores, 16GB RAM, 14GB disk
- Common tools are pre-installed — Java, Docker, Git, Node, Python, AWS CLI
- Use `actions/setup-java` even though Java is pre-installed — for version control and caching
- Use matrix strategy to run the same job across multiple OS simultaneously
- Self-hosted runners use your own machines — covered in Module 15

---

---

*i27Academy · GitHub Actions Course · Module 04 · i27academy.com*
