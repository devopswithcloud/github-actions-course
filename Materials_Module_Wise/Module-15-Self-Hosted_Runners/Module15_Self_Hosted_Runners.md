# Module 15 — Self-Hosted Runners
### i27Academy — GitHub Actions Course

---

## Agenda

1. What is a self-hosted runner
2. GitHub-hosted vs self-hosted
3. Use cases for self-hosted runners
4. Setting up a GCP VM
5. Installing runner software
6. Registering the runner
7. Runner labels
8. Running as a service (systemd)
9. Runner groups
10. Security considerations
11. Workflow files for self-hosted runner

---

## 1. What is a Self-Hosted Runner

A self-hosted runner is a machine that YOU provide and manage, registered with GitHub so it can receive and execute workflow jobs.

```
GitHub-hosted runner:
  → GitHub provides the VM
  → GitHub manages it
  → Fresh machine every run
  → You pay per minute (or use free tier)

Self-hosted runner:
  → YOU provide the VM (GCP, AWS, on-premise, laptop)
  → YOU manage it
  → Persistent — files survive between runs
  → You pay for the VM — no GitHub minutes consumed
```

---

## 2. GitHub-Hosted vs Self-Hosted

| | GitHub-Hosted | Self-Hosted (GCP) |
|---|---|---|
| Who provides VM | GitHub | You |
| Who manages | GitHub | You |
| Cost | GitHub minutes | GCP VM cost only |
| Environment | Fresh every run | Persistent |
| Pre-installed tools | Standard set | Whatever you install |
| Private network access | No | Yes |
| Custom software | Not possible | Yes — install anything |
| Speed | Standard | Depends on VM size |
| Security | GitHub managed | You are responsible |

---

## 3. Use Cases for Self-Hosted Runners

```
Private network access
  → Connect to databases, internal APIs, Kubernetes clusters
  → Not reachable from GitHub-hosted runners

Custom software
  → Specialized build tools, licensed software
  → Hardware-specific drivers

Cost reduction
  → Long-running builds consume many GitHub minutes
  → Self-hosted: no minutes consumed

The runner IS the deployment target
  → Deploy directly on the machine without SSH
  → Runner pulls the job and runs it locally

Compliance
  → Code must never leave your own infrastructure
  → Self-hosted keeps everything in-house

GCP-specific services
  → Access Cloud SQL, GCS, GKE from within the private VPC
  → Not possible with GitHub-hosted runners
```

---

## 4. Setting up a GCP VM

### Step 1 — Create a GCE VM instance

```
GCP Console → Compute Engine → VM instances → Create Instance

Name         : i27academy-runner
Region       : us-central1 (or nearest to you)
Zone         : us-central1-a
Machine type : e2-medium (2 vCPU, 4GB RAM)
Boot disk    : Ubuntu 22.04 LTS, 20GB standard disk
Firewall     : Allow HTTP traffic (for app access)
```

### Step 2 — SSH into the VM

```bash
# From GCP Console → VM instances → SSH button
# Or from local terminal:
gcloud compute ssh i27academy-runner --zone=us-central1-a
```

### Step 3 — Install required software on the VM

```bash
# Update packages
sudo apt-get update && sudo apt-get upgrade -y

# Install Java 21
sudo apt-get install -y openjdk-21-jdk

# Verify Java
java -version

# Install Maven
sudo apt-get install -y maven

# Verify Maven
mvn --version

# Install Docker
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group (no sudo needed)
sudo usermod -aG docker $USER
newgrp docker

# Verify Docker
docker --version

# Install Git
sudo apt-get install -y git

# Verify Git
git --version
```

### Step 4 — Create a directory for the runner

```bash
mkdir -p ~/actions-runner && cd ~/actions-runner
```

---

## 5. Installing Runner Software

### Step 1 — Get the download URL from GitHub

```
Go to your repo:
  i27academy-devops-dashboard-private

Repo → Settings → Actions → Runners → New self-hosted runner

Select:
  Operating System: Linux
  Architecture: x64

GitHub shows you the exact download commands — copy them
```

### Step 2 — Download and extract runner

```bash
# Download (version may differ — use what GitHub shows you)
curl -o actions-runner-linux-x64-2.320.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.320.0/actions-runner-linux-x64-2.320.0.tar.gz

# Extract
tar xzf ./actions-runner-linux-x64-2.320.0.tar.gz
```

---

## 6. Registering the Runner

### Step 1 — Get the registration token from GitHub

```
Repo → Settings → Actions → Runners → New self-hosted runner
Scroll to "Configure" section
Copy the token shown — looks like: ABCDEFGH1234567890
```

### Step 2 — Configure the runner

```bash
./config.sh \
  --url https://github.com/i27academy/i27academy-devops-dashboard-private \
  --token YOUR_TOKEN_HERE \
  --name i27academy-gcp-runner \
  --labels self-hosted,linux,gcp \
  --work _work
```

You will be prompted:
```
Enter the name of the runner group to add this runner to: [press Enter for Default]
Enter the name of the runner: [i27academy-gcp-runner]
This runner will have the following labels: self-hosted, linux, gcp
Enter any additional labels: [press Enter or add more]
Enter name of work folder: [_work]
```

### Step 3 — Test run the runner

```bash
./run.sh
```

You should see:
```
Connected to GitHub
Listening for Jobs
```

Go to GitHub → Repo → Settings → Actions → Runners
You should see your runner listed as **Idle** with a green dot.

---

## 7. Runner Labels

Labels are used to target specific runners in your workflow.

**Labels added during registration:**
```bash
--labels self-hosted,linux,gcp
```

**Default labels always added automatically:**
```
self-hosted   → marks it as self-hosted
linux         → operating system
x64           → CPU architecture
```

**Add custom labels anytime:**
```
GitHub → Repo → Settings → Actions → Runners → click runner → Edit
Add labels: gcp, production, java21, docker
```

**Target by labels in workflow:**
```yaml
# Any self-hosted runner
runs-on: self-hosted

# Must match ALL labels (AND logic)
runs-on: [ self-hosted, linux, gcp ]

# More specific targeting
runs-on: [ self-hosted, linux, gcp, production ]
```

---

## 8. Running as a Service (systemd)

Running the runner manually (`./run.sh`) stops when you close the SSH session. To keep it running permanently — install as a systemd service.

### Step 1 — Install the service

```bash
# Must be run as sudo
sudo ./svc.sh install
```

### Step 2 — Start the service

```bash
sudo ./svc.sh start
```

### Step 3 — Verify the service is running

```bash
sudo ./svc.sh status
```

You should see:
```
● actions.runner.i27academy-devops-dashboard-private.i27academy-gcp-runner.service
   Active: active (running)
```

### Step 4 — Other service commands

```bash
sudo ./svc.sh stop       # stop the runner
sudo ./svc.sh restart    # restart the runner
sudo ./svc.sh uninstall  # remove the service
```

**The runner now starts automatically when the VM boots.**

---

## 9. Runner Groups

Runner groups let you organize runners and control which repositories can use them.

```
Organization → Settings → Actions → Runner groups → New runner group

Name: gcp-runners
Access: Selected repositories → i27academy-devops-dashboard-private
```

**Target by group in workflow:**
```yaml
runs-on:
  group: gcp-runners
  labels: [ linux, gcp ]
```

Runner groups are most useful in organizations with many runners and repos.

---

## 10. Security Considerations

Self-hosted runners introduce security responsibilities that GitHub-hosted runners handle for you.

**Critical rules:**

```
Never use self-hosted runners on public repositories
  → Anyone can fork your repo and run malicious code
  → Use ONLY on private repos

Keep the runner software updated
  → GitHub releases updates regularly
  → Outdated runners may have security vulnerabilities

Limit runner permissions
  → Runner process should not run as root
  → Use a dedicated low-privilege user account

Clean up after runs
  → Self-hosted runners are persistent
  → Sensitive files from one run may be accessible in the next
  → Use ephemeral runners or clean up in post steps

Network security
  → Runner only needs outbound HTTPS to github.com
  → No inbound ports needed
  → Keep runner in a private subnet if possible
```

**Ephemeral runners (recommended for production):**
```bash
# Runner registers, runs ONE job, then unregisters
./config.sh --ephemeral --url ... --token ...
```

Each job gets a fresh runner instance — more secure, no state leakage between runs.

---

## 11. Workflow Files

### Verify Runner is Connected

**15.1.1-self-hosted-runner-verify.yml**

```yaml
name: 15.1.1-Self-Hosted-Runner-Verify

on:
  workflow_dispatch:

jobs:
  verify-runner:
    name: Verify Self-Hosted Runner
    runs-on: [ self-hosted, linux, gcp ]

    steps:
      - name: Print runner information
        run: |
          echo "Runner OS    : ${{ runner.os }}"
          echo "Runner Name  : ${{ runner.name }}"
          echo "Hostname     : $(hostname)"
          echo "CPU cores    : $(nproc)"
          echo "RAM          : $(free -h | grep Mem | awk '{print $2}')"
          echo "Java         : $(java -version 2>&1 | head -1)"
          echo "Docker       : $(docker --version)"
```

Run this after setup to confirm your runner is working.

---

### GitHub-Hosted vs Self-Hosted Comparison

**15.1.2-github-hosted-vs-self-hosted.yml**

```yaml
on:
  workflow_dispatch:

jobs:
  github-hosted:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "GitHub-hosted runner"
          echo "Hostname : $(hostname)"
          echo "Fresh VM — managed by GitHub"

  self-hosted:
    runs-on: [ self-hosted, linux, gcp ]
    steps:
      - run: |
          echo "Self-hosted runner on GCP"
          echo "Hostname : $(hostname)"
          echo "Persistent VM — managed by you"
```

Run both jobs and compare the output — notice the hostname is different every time for GitHub-hosted but consistent for self-hosted.

---

### Runner Labels Demo

**15.2.1-runner-labels.yml**

```yaml
on:
  workflow_dispatch:

jobs:
  any-self-hosted:
    runs-on: self-hosted

  gcp-linux:
    runs-on: [ self-hosted, linux, gcp ]   # must match ALL labels

  mix:
    runs-on: ubuntu-latest                 # GitHub-hosted
    needs: gcp-linux
    steps:
      - run: echo "Back on GitHub-hosted after GCP job"
```

---

### Build on GitHub-Hosted, Deploy on Self-Hosted

**15.3.1-build-deploy-self-hosted.yml**

```yaml
on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest            # GitHub-hosted for build
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: temurin
          cache: maven
      - run: mvn package -DskipTests
      - uses: actions/upload-artifact@v4
        with:
          name: devops-dashboard-jar
          path: target/devops-dashboard-1.0.0.jar

  deploy:
    runs-on: [ self-hosted, linux, gcp ]   # self-hosted for deploy
    needs: build
    environment: development
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: devops-dashboard-jar
          path: ./app
      - name: Deploy
        run: |
          pkill -f "devops-dashboard" || true
          nohup java -jar ./app/devops-dashboard-1.0.0.jar &
          echo "Deployed ✅"
```

**Why this pattern:**
```
Build on GitHub-hosted:
  → Clean environment every time
  → No leftover files from previous builds
  → Consistent build environment

Deploy on self-hosted GCP:
  → Runner IS on the deployment target
  → No SSH, no SCP needed
  → Direct access to GCP network
  → Runner pulls the job — no inbound connections needed
```

---

## Complete Runner Setup — Quick Reference

```bash
# 1. Create GCE VM (Ubuntu 22.04, e2-medium)

# 2. Install dependencies
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y openjdk-21-jdk maven docker.io git
sudo usermod -aG docker $USER

# 3. Create runner directory
mkdir -p ~/actions-runner && cd ~/actions-runner

# 4. Download runner (get exact URL from GitHub UI)
curl -o actions-runner-linux-x64.tar.gz -L DOWNLOAD_URL_FROM_GITHUB
tar xzf actions-runner-linux-x64.tar.gz

# 5. Register runner
./config.sh \
  --url https://github.com/i27academy/i27academy-devops-dashboard-private \
  --token YOUR_TOKEN \
  --name i27academy-gcp-runner \
  --labels self-hosted,linux,gcp

# 6. Install as service
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status

# 7. Verify in GitHub
# Repo → Settings → Actions → Runners → should show Idle (green)
```

---


---

*i27Academy · GitHub Actions Course · Module 15 · i27academy.com*
