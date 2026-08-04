# Module 03 — Events that Trigger Workflows
### i27Academy — GitHub Actions Course

---

## Agenda

1. What is an event
2. workflow_dispatch
3. push
4. pull_request
5. schedule
6. workflow_run
7. repository_dispatch
8. Combining multiple triggers

---

## 1. What is an Event

An event is an activity that happens in or around your GitHub repository that triggers a workflow to run.

Every workflow must declare at least one event under `on:`. When that event occurs, GitHub Actions automatically starts the workflow.

```yaml
on: push              # runs when code is pushed
on: pull_request      # runs when a PR is opened or updated
on: workflow_dispatch # runs when manually triggered
on: schedule          # runs on a time schedule
```

GitHub supports many event types. In this module we cover the most commonly used ones in real CI/CD pipelines.

---

## 2. workflow_dispatch

`workflow_dispatch` adds a **Run workflow** button in the GitHub Actions UI. This allows you to trigger a workflow manually — without pushing any code.

This is the most useful event when you are learning — you control exactly when the workflow runs.

**03.1.1-workflow-dispatch.yml**

```yaml
name: 01-Workflow-Dispatch-Event

on:
  workflow_dispatch:

jobs:
  manual-trigger-demo:
    runs-on: ubuntu-latest

    steps:
      - name: Print Message
        run: echo "This workflow was triggered manually"

      - name: Print Trigger Info
        run: |
          echo "Event Name: ${{ github.event_name }}"
          echo "Branch Name: ${{ github.ref_name }}"
          echo "Triggered By: ${{ github.actor }}"
```

How to trigger:
```
GitHub → Actions tab
→ Select the workflow from the left sidebar
→ Click "Run workflow" button
→ Select branch
→ Click green "Run workflow"
```

Observe:
```
→ github.event_name prints: workflow_dispatch
→ github.ref_name prints: the branch you selected
→ github.actor prints: your GitHub username
```

Key points:
```
→ Adds a manual trigger button in the Actions tab
→ Only appears on the default branch
→ Can accept inputs (covered in detail in Module 06)
→ Useful for on-demand deployments and maintenance tasks
→ Jenkins equivalent: clicking "Build Now"
```

---

## 3. push

The `push` event triggers a workflow whenever code is pushed to the repository. This is the most common event in CI/CD pipelines.

### 3.1 Basic push — triggers on any branch

**03.2.1-push-event.yml**

```yaml
name: 02-Push-Event

on:
  push:

jobs:
  push-demo:
    runs-on: ubuntu-latest

    steps:
      - name: Print Event Details
        run: |
          echo "Workflow triggered by Push Event"
          echo "Event Name : ${{ github.event_name }}"
          echo "Repository : ${{ github.repository }}"
          echo "Branch     : ${{ github.ref_name }}"
          echo "Actor      : ${{ github.actor }}"
          echo "Commit SHA : ${{ github.sha }}"
```

Observe:
```
→ Push to ANY branch triggers this workflow
→ github.event_name prints: push
→ github.sha prints the commit SHA that triggered it
```

---

### 3.2 Push with branch filter — trigger only on specific branches

**03.2.2-push-branch-filter.yml**

```yaml
name: 03-Push-Branch-Filter

on:
  push:
    branches:
    - main

jobs:
  show-info:
    name: Push Trigger Info
    runs-on: ubuntu-latest
    steps:
      - name: Show what triggered this
        run: |
          echo "============================="
          echo "Triggered by: PUSH EVENT"
          echo "============================="
          echo "Branch    : ${{ github.ref_name }}"
          echo "Commit SHA: ${{ github.sha }}"
          echo "Pushed by : ${{ github.actor }}"
          echo "Repo      : ${{ github.repository }}"
          echo "============================="
```

Observe:
```
→ Only triggers when pushing to main
→ Push to any other branch — workflow does NOT run
```

---

### 3.3 Push with multiple branch filters

**03.2.3-push-multiple-branches.yml**

```yaml
name: 04-Push-Multiple-Branches

on:
  push:
    branches:
      - main
      - develop
      - release/*

jobs:
  multiple-branch-demo:
    runs-on: ubuntu-latest

    steps:
      - name: Print Branch Details
        run: |
          echo "Workflow triggered for selected branches"
          echo "Event Name : ${{ github.event_name }}"
          echo "Branch     : ${{ github.ref_name }}"
          echo "Actor      : ${{ github.actor }}"
```

Observe:
```
→ Triggers on push to main, develop, or any release/* branch
→ release/* is a pattern — matches release/1.0, release/2.0, etc.
→ Push to feature/my-feature — does NOT trigger
```

Key points:
```
→ branches: accepts exact names or patterns
→ * matches anything within a single path segment
→ ** matches across path segments
→ release/* matches release/1.0 but NOT release/1.0/hotfix
→ release/** matches release/1.0/hotfix as well
```

---

### 3.4 Push with branches-ignore — trigger on all except specific branches

**03.2.4-push-branches-ignore.yml**

```yaml
name: 05-Push-Branches-Ignore

on:
  push:
    branches-ignore:
      - feature/*
      - test/*

jobs:
  branches-ignore-demo:
    runs-on: ubuntu-latest

    steps:
      - name: Print Branch Details
        run: |
          echo "Workflow will not run for ignored branches"
          echo "Event Name : ${{ github.event_name }}"
          echo "Branch     : ${{ github.ref_name }}"
          echo "Actor      : ${{ github.actor }}"
```

Observe:
```
→ Triggers on push to ANY branch EXCEPT feature/* and test/*
→ Push to feature/my-feature — does NOT trigger
→ Push to main, develop, release/* — triggers
```

Key points:
```
→ branches-ignore: is the opposite of branches:
→ Use branches: when you know which branches to include
→ Use branches-ignore: when you know which branches to exclude
→ You cannot use branches: and branches-ignore: together
```

---

### 3.5 Push with path filter — trigger only when specific files change

**03.2.5-push-path-filter.yml**

```yaml
name: 06-Path-Filter

on:
  push:
    branches:
      - master
      - develop
    paths:
      - 'src/**'        # any file inside src folder
      - 'pom.xml'       # build file changed
      - 'Dockerfile'    # docker file changed

jobs:
  show-info:
    name: Push Trigger Info
    runs-on: ubuntu-latest
    steps:
      - name: Show what triggered this
        run: |
          echo "============================="
          echo "Triggered by: PUSH EVENT"
          echo "============================="
          echo "Branch    : ${{ github.ref_name }}"
          echo "Commit SHA: ${{ github.sha }}"
          echo "Pushed by : ${{ github.actor }}"
          echo "Repo      : ${{ github.repository }}"
          echo "============================="
```

Observe:
```
→ Push to master or develop AND change a file in src/, pom.xml or Dockerfile
  → workflow triggers ✅

→ Push to master but only change README.md
  → workflow does NOT trigger ✅

→ Push to feature/my-feature
  → workflow does NOT trigger (branch filter)
```

Why this matters:
```
Without paths filter:
  Developer updates README.md
  → Full CI pipeline runs — wasted minutes

With paths filter:
  Developer updates README.md
  → Nothing runs ✅
  Developer changes src/main/java/...
  → Pipeline runs ✅ because real code changed
```

---

### 3.6 Push with paths-ignore — trigger unless specific files change

**03.2.6-push-paths-ignore.yml**

```yaml
name: 07-Paths-Ignore

on:
  push:
    paths-ignore:
      - README.md
      - docs/**

jobs:
  paths-ignore-demo:
    runs-on: ubuntu-latest

    steps:
      - name: Print Path Ignore Information
        run: |
          echo "Workflow triggered because non-documentation files changed"
          echo "Branch : ${{ github.ref_name }}"
```

Observe:
```
→ Push that changes README.md or anything in docs/ — does NOT trigger
→ Push that changes any other file — triggers
```

Key points:
```
→ paths: — trigger only when these files change
→ paths-ignore: — trigger unless these files change
→ Cannot use paths: and paths-ignore: together
→ Very useful for mono-repos and large projects
→ Saves CI minutes by not running on documentation changes
```

---

## 4. pull_request

The `pull_request` event triggers a workflow when activity happens on a pull request. This is the most important event for teams — it validates code before it is merged.

### 4.1 Basic pull_request event

**03.3.1-pull-request-event.yml**

```yaml
name: 08-Pull-Request-Event

on:
  pull_request:

jobs:
  pr-validation:
    name: pr-validation-job
    runs-on: ubuntu-latest
    steps:
    - name: Print Pull Request Details
      run: |
        echo "Workflow triggered by Pull Request Event"
        echo "Event Name        : ${{ github.event_name }}"
        echo "Source Branch     : ${{ github.head_ref }}"
        echo "Target Branch     : ${{ github.base_ref }}"
        echo "Repository        : ${{ github.repository }}"
        echo "Triggered By      : ${{ github.actor }}"
        echo "Commit SHA        : ${{ github.sha }}"
        echo "Action            : ${{ github.event.action }}"
    - name: Checkout Source Code
      uses: actions/checkout@v4
    - name: List files
      run: ls -la
```

By default `pull_request` triggers on three activity types:
```
opened       → PR is created
synchronize  → new commit is pushed to the PR
reopened     → closed PR is reopened
```

Key context values available in pull_request:
```
github.head_ref         → source branch (the branch being merged)
github.base_ref         → target branch (the branch being merged into)
github.event.action     → what happened (opened, synchronize, reopened)
github.event.pull_request.number  → PR number
github.event.pull_request.title   → PR title
```

---

### 4.2 pull_request with branch and type filters

**03.3.2-pull-request-types.yml**

```yaml
name: 09-Trigger - Pull Request

on:
  pull_request:
    branches:
      - master
    types:
      - opened        # PR created
      - synchronize   # new commit pushed to PR
      - reopened      # closed PR reopened

jobs:
  show-info:
    name: PR Trigger Info
    runs-on: ubuntu-latest
    steps:
      - name: Show what triggered this
        run: |
          echo "============================="
          echo "Triggered by: PULL REQUEST"
          echo "============================="
          echo "PR Number  : ${{ github.event.pull_request.number }}"
          echo "PR Title   : ${{ github.event.pull_request.title }}"
          echo "From Branch: ${{ github.head_ref }}"
          echo "To Branch  : ${{ github.base_ref }}"
          echo "Author     : ${{ github.actor }}"
          echo "============================="
```

Test this workflow:

**Test 1 — Open a PR (should trigger):**
```bash
git checkout -b feature/pr-trigger-test
echo "pr test" >> random-commit.txt
git add .
git commit -m "test: testing PR trigger"
git push origin feature/pr-trigger-test
# Go to GitHub → Pull Requests → New Pull Request
# base: master ← compare: feature/pr-trigger-test → Create PR
```

**Test 2 — Push another commit to the same PR (should trigger again):**
```bash
echo "another change" >> random-commit.txt
git add .
git commit -m "test: second commit on PR"
git push origin feature/pr-trigger-test
```

**Test 3 — Push directly to master without a PR (should NOT trigger):**
```bash
git checkout master
echo "direct push" >> random-commit.txt
git add .
git commit -m "test: direct push to master"
git push origin master
```

---

### 4.3 Pull Request and Branch Protection

The `pull_request` event combined with **branch protection rules** is how teams enforce code quality. Nobody can merge to master unless the CI passes.

**Setting up branch protection:**
```
Repo → Settings → Branches → Add branch protection rule
  Branch name pattern: master
  ✅ Require status checks to pass before merging
     → Select your workflow job name
  ✅ Require branches to be up to date before merging
```

Once configured:
```
PR opened
    │
    ▼
CI runs automatically
    │
    ├── CI fails → Merge button GREYED OUT ❌
    │              "Required status checks have not passed"
    │
    └── CI passes → Merge button GREEN ✅
                    "All checks have passed"
```

Nobody can override this — not even repo admins. This is how real teams enforce quality on every merge.

Key points:
```
→ pull_request triggers on opened, synchronize, reopened by default
→ Use types: to control exactly which activities trigger the workflow
→ Use branches: to only trigger for PRs targeting specific branches
→ Combined with branch protection — enforces quality before every merge
→ Jenkins equivalent: multibranch pipeline with PR validation
```

---

## 5. schedule

The `schedule` event triggers a workflow at a set time using cron syntax. No push, no PR, no manual click — it runs automatically on a schedule.

Common use cases:
```
→ Nightly full test suite
→ Weekly security and dependency scans
→ Daily health checks
→ Cleanup of old artifacts and images
```

**03.4.1-schedule-event.yml**

```yaml
name: 10-schedule-event

on:
  schedule:
  - cron: '*/5 * * * *'

jobs:
  schedule-demo:
    runs-on: ubuntu-latest
    steps:
    - name: Print Schedule Information
      run: |
        echo "Event type is : ${{ github.event_name }}"
```

**Cron syntax:**

```
┌─────────── minute (0-59)
│ ┌───────── hour (0-23)
│ │ ┌─────── day of month (1-31)
│ │ │ ┌───── month (1-12)
│ │ │ │ ┌─── day of week (0=Sunday, 6=Saturday)
│ │ │ │ │
* * * * *

Examples:
  '*/5 * * * *'     every 5 minutes
  '0 2 * * *'       every day at 2am UTC
  '0 8 * * MON'     every Monday at 8am UTC
  '0 0 1 * *'       first day of every month
```

Important notes:
```
→ All schedule times are in UTC — calculate accordingly
→ Minimum interval is 5 minutes
→ GitHub may delay scheduled runs by up to 15 minutes during high load
→ Schedule only runs on the default branch (main/master)
→ Jenkins equivalent: triggers { cron('H 2 * * *') }
```

---

## 6. workflow_run

The `workflow_run` event triggers a workflow after another workflow completes. This is used to cleanly separate CI from CD.

```yaml
on:
  workflow_run:
    workflows: [ "CI Pipeline" ]   # must match the name: field exactly
    branches: [ master ]
    types: [ completed ]

jobs:
  deploy:
    if: github.event.workflow_run.conclusion == 'success'
    runs-on: ubuntu-latest
    steps:
      - run: echo "CI passed — deploying now"
```

Key points:
```
→ The workflow name must match exactly — character for character
→ Use conclusion == 'success' to only deploy when CI passes
→ Keeps CI and CD in separate workflow files — clean separation
→ Jenkins equivalent: upstream/downstream job configuration
```

### Complete example — two separate workflow files

This example shows the full picture: one workflow (`workflow-1`) that runs first (including a step that intentionally fails), and a second workflow (`workflow-2`) that only runs after `workflow-1` completes, and only proceeds if `workflow-1` succeeded.

**File 1: `.github/workflows/workflow-1.yml`**

```yaml
name: workflow-1
on:
  workflow_dispatch:
jobs:
  job1:
    runs-on: ubuntu-latest
    steps:
      - name: Print Name
        run: |
          echo "Actor is : ${{ github.actor }}"
          echo "Commit SHA is:        ${{ github.sha }}"
      - name: Step 2
        run: |
          echo "Intentionally Failing this step"
          exit 1
```

**File 2: `.github/workflows/workflow-2.yml`**

```yaml
name: workflow-2
on:
  workflow_run:
    workflows:
      - workflow-1
    types:
      - completed
jobs:
  job1:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    steps:
      - name: Printing
        run: echo "This workflow is triggered because workflow is completed"
```

Walking through what happens:
```
→ workflow-1 is triggered manually (workflow_dispatch)
→ Its "Step 2" runs exit 1, so the job — and the whole workflow — fails
→ workflow-2 still fires, because workflow_run triggers on completion,
  regardless of whether that completion was a success or a failure
→ Inside workflow-2, the if: condition checks
  github.event.workflow_run.conclusion == 'success'
→ Since workflow-1's conclusion was 'failure', the condition is false,
  so job1 in workflow-2 is skipped (shown as skipped, not failed)
→ If Step 2 in workflow-1 did NOT fail, workflow-2's job1 would run
  and print its message
```

This is the key gotcha with `workflow_run`: the trigger itself fires on *any* completion (success, failure, or cancelled) — it is the `if:` condition on `github.event.workflow_run.conclusion` that decides whether your downstream job actually does anything.

---

## 7. repository_dispatch

The `repository_dispatch` event triggers a workflow from outside GitHub via an API call. Any external system that can make an HTTP request can trigger your workflow.

```yaml
on:
  repository_dispatch:
    types: [ deploy-request ]
```

Trigger it from the command line:

```bash
curl -X POST \
  -H "Authorization: token YOUR_PAT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/YOUR_ORG/YOUR_REPO/dispatches \
  -d '{
    "event_type": "deploy-request",
    "client_payload": {
      "version": "v1.2.3",
      "environment": "staging"
    }
  }'
```

Key points:
```
→ Requires a Personal Access Token (PAT) with repo scope
→ client_payload passes custom data to the workflow
→ Access payload in workflow: ${{ github.event.client_payload.version }}
→ Useful for triggering GitHub Actions from Jenkins during migration
→ Jenkins equivalent: remote build trigger via webhook URL
```

---

## 8. Combining Multiple Triggers

A single workflow can be triggered by multiple events. 

```yaml
on:
  push:
    branches: [ master, develop ]
    paths:
      - 'src/**'
      - 'pom.xml'
      - 'Dockerfile'

  pull_request:
    branches: [ master ]
    types: [ opened, synchronize, reopened ]

  schedule:
    - cron: '0 2 * * *'     # nightly at 2am UTC

  workflow_dispatch:         # always allow manual trigger
```

What this achieves:
```
Push to master/develop (only src or pom.xml or Dockerfile)
  → CI runs automatically

PR raised against master
  → CI runs — blocks merge if it fails

Every night at 2am UTC
  → Full regression run

Manual trigger anytime
  → Run on demand
```

Key points:
```
→ Combine as many triggers as needed in one workflow
→ Use filters (branches:, paths:, types:) to control when each fires
→ workflow_dispatch should always be included — allows manual run anytime
→ github.event_name tells you which trigger fired in the current run
```

---

## Module 03 Summary

- An event is what triggers a workflow — every workflow needs at least one
- `workflow_dispatch` adds a manual Run button in the GitHub UI
- `push` triggers on code push — filter by branches: or paths:
- `branches-ignore:` and `paths-ignore:` are the inverse filters
- `pull_request` triggers on PR activity — opened, synchronize, reopened by default
- Combined with branch protection rules — enforces CI before every merge
- `schedule` uses cron syntax — all times are in UTC
- `workflow_run` triggers after another workflow completes — separates CI from CD
- `repository_dispatch` triggers from external systems via API
- Multiple triggers can be combined in one workflow

---
