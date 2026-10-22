# Module 13 — Implementing Custom Actions
### i27Academy — GitHub Actions Course

---

## Agenda

1. What is a custom action and why we need it
2. Types of actions
3. Composite action structure — action.yml
4. inputs, outputs and runs
5. shell: bash — the most important rule
6. Building our first composite action
7. Calling a local composite action
8. Calling a remote composite action
9. Integration with DevOps Dashboard project

---

## 1. What is a Custom Action and Why We Need It

Look at this workflow — three jobs all doing the same thing:

```yaml
jobs:
  test:
    steps:
      - uses: actions/checkout@v4     # repeated
      - uses: actions/setup-java@v4   # repeated
        with:
          java-version: '21'
          distribution: temurin
          cache: maven
      - run: mvn test

  build:
    steps:
      - uses: actions/checkout@v4     # repeated
      - uses: actions/setup-java@v4   # repeated
        with:
          java-version: '21'
          distribution: temurin
          cache: maven
      - run: mvn package

  code-quality:
    steps:
      - uses: actions/checkout@v4     # repeated
      - uses: actions/setup-java@v4   # repeated
        with:
          java-version: '21'
          distribution: temurin
          cache: maven
      - run: mvn verify
```

**The problems:**
```
→ Java version hardcoded in 3 places
→ Change version = edit 3 jobs (easy to miss one)
→ Same logic duplicated across workflows
→ More lines = more chances for mistakes
→ For 6 microservices — multiplied across 6 repos
```

**The solution — composite action:**
```
Write the repeated steps ONCE in an action.yml file
Call it with one uses: line in every job
Change Java version → update ONE file → all jobs get it
```

---

## 2. Types of Actions

```
Composite    → YAML steps bundled together
               No coding needed — uses existing actions and shell
               Most practical for DevOps engineers ✅

JavaScript   → Node.js code that runs directly on the runner
               Used for complex logic and GitHub API calls
               Requires coding knowledge

Docker       → Runs inside a container
               Used for specific OS environment requirements
               Slower — container needs to start first
```

For this course and for i27helpdesk — we use **composite actions**.

---

## 3. Composite Action Structure

A composite action lives in a folder with an `action.yml` file:

```
.github/
  actions/
    java-build/
      action.yml      ← the composite action
    notify-failure/
      action.yml      ← another composite action
```

**The `action.yml` file has 5 sections:**

```yaml
name:           # what the action is called
description:    # what it does
inputs:         # what values it accepts (optional)
outputs:        # what values it returns (optional)
runs:           # how it executes
```

---

## 4. inputs, outputs and runs

### inputs

```yaml
inputs:
  java-version:
    description: Java version to use
    required: false        # optional — has a default
    default: '21'

  run-tests:
    description: Run tests before building?
    required: false
    default: 'true'
```

Each input has:
```
description  → shown to users in documentation
required     → true = caller must provide, false = uses default
default      → value used when caller does not provide it
```

Access inputs inside the action:
```yaml
${{ inputs.java-version }}
${{ inputs.run-tests }}
```

### outputs

```yaml
outputs:
  jar-path:
    description: Path to the built JAR file
    value: ${{ steps.build.outputs.jar-path }}   # points to a step output

  test-result:
    description: passed or skipped
    value: ${{ steps.test.outputs.result }}
```

The `value:` must point to a step output. The step must have an `id:` for this to work.

### runs

```yaml
runs:
  using: composite       # always composite for step-based actions
  steps:
    - name: My step
      shell: bash        # REQUIRED — see next section
      run: echo "hello"
```

---

## 5. shell: bash — The Most Important Rule

**In regular workflows — shell is inherited automatically:**
```yaml
steps:
  - run: echo "hello"    # shell is bash by default — no need to specify
```

**In composite actions — shell must be specified on EVERY run: step:**
```yaml
runs:
  using: composite
  steps:
    - run: echo "hello"          # ❌ WRONG — will fail without shell:
    - run: echo "hello"          # ✅ CORRECT
      shell: bash
```

This is the number one mistake students make with composite actions. If you forget `shell: bash` the action will fail with a confusing error.

---

## 6. Building Our First Composite Action

**.github/actions/java-build/action.yml**

```yaml
name: Java Build Action
description: |
  Composite action for i27Academy Java services.
  Handles Java setup and Maven build.

inputs:
  java-version:
    description: Java version to use
    required: false
    default: '21'
  distribution:
    description: Java distribution
    required: false
    default: 'temurin'
  run-tests:
    description: Run tests before building (true/false)
    required: false
    default: 'true'
  working-directory:
    description: Directory to run Maven commands in
    required: false
    default: '.'

outputs:
  jar-path:
    description: Path to the built JAR file
    value: ${{ steps.build.outputs.jar-path }}
  test-result:
    description: Result of test run — passed or skipped
    value: ${{ steps.test.outputs.result }}

runs:
  using: composite
  steps:
    - name: Set up JDK ${{ inputs.java-version }}
      uses: actions/setup-java@v4
      with:
        java-version: ${{ inputs.java-version }}
        distribution: ${{ inputs.distribution }}
        cache: maven

    - name: Run tests
      id: test
      if: inputs.run-tests == 'true'
      shell: bash
      working-directory: ${{ inputs.working-directory }}
      run: |
        mvn test
        echo "result=passed" >> $GITHUB_OUTPUT

    - name: Set test skipped output
      if: inputs.run-tests != 'true'
      shell: bash
      run: echo "result=skipped" >> $GITHUB_OUTPUT

    - name: Build JAR
      id: build
      shell: bash
      working-directory: ${{ inputs.working-directory }}
      run: |
        mvn package -DskipTests
        JAR=$(find target -name "*.jar" -not -name "*sources*" | head -1)
        echo "jar-path=$JAR" >> $GITHUB_OUTPUT
        echo "Built JAR: $JAR"
```

**.github/actions/notify-failure/action.yml**

```yaml
name: Notify on Failure
description: Send notification when pipeline fails

inputs:
  service-name:
    description: Service that failed
    required: true
  branch:
    description: Branch where failure occurred
    required: true
  commit:
    description: Commit SHA
    required: true
  actor:
    description: Who triggered the run
    required: true

runs:
  using: composite
  steps:
    - name: Send failure notification
      shell: bash
      run: |
        echo "============================="
        echo "❌ PIPELINE FAILURE ALERT"
        echo "============================="
        echo "Service : ${{ inputs.service-name }}"
        echo "Branch  : ${{ inputs.branch }}"
        echo "Commit  : ${{ inputs.commit }}"
        echo "Actor   : ${{ inputs.actor }}"
        echo "============================="
        echo "Would send Slack/email notification here"
```

---

## 7. Calling a Local Composite Action

**13.1.2-with-composite-action.yml**

```yaml
name: 13.1.2-With-Composite-Action

on:
  workflow_dispatch:

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4       # REQUIRED before local action

      - name: Build and test
        id: build                       # id needed to read outputs
        uses: ./.github/actions/java-build
        with:
          java-version: '21'
          run-tests: 'true'

      - name: Upload test reports
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: surefire-reports
          path: target/surefire-reports/
          retention-days: 7

      - name: Notify on failure
        if: failure()
        uses: ./.github/actions/notify-failure
        with:
          service-name: i27academy-devops-dashboard
          branch: ${{ github.ref_name }}
          commit: ${{ github.sha }}
          actor: ${{ github.actor }}

  build:
    name: Build
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4

      - name: Build JAR
        id: build
        uses: ./.github/actions/java-build
        with:
          java-version: '21'
          run-tests: 'false'            # tests already ran

      - name: Show build output
        run: |
          echo "JAR path    : ${{ steps.build.outputs.jar-path }}"
          echo "Test result : ${{ steps.build.outputs.test-result }}"

      - uses: actions/upload-artifact@v4
        with:
          name: devops-dashboard-jar
          path: ${{ steps.build.outputs.jar-path }}
          retention-days: 7
```

**Three key rules:**

```
1. actions/checkout@v4 MUST come before any local action
   → action files need to be on the runner first

2. id: on the step is only needed if you read outputs
   → steps.build.outputs.jar-path needs id: build

3. ./.github/actions/ACTION-NAME
   → ./ means current repo
   → path is relative to repo root
```

**Comparison — before vs after:**

```
Before (without composite):
  test job  → 6 steps
  build job → 6 steps
  Total     → 12 steps, checkout+setup-java repeated 2 times

After (with composite):
  test job  → 3 steps (checkout + uses: java-build + upload)
  build job → 3 steps (checkout + uses: java-build + upload)
  Total     → 6 steps, java-build logic in ONE place
```

---

## 8. Calling a Remote Composite Action

A composite action from a different repository:

**13.1.3-remote-composite-action.yml**

```yaml
name: 13.1.3-Remote-Composite-Action

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build using remote action
        id: build
        uses: i27academy/i27academy-github-actions/.github/actions/java-build@main
        #     └──────────────┬──────────────┘  └─────────┬─────────┘  └──┬──┘
        #              owner/repo                  action path           branch

        with:
          java-version: '21'
          run-tests: 'true'

      - run: echo "JAR: ${{ steps.build.outputs.jar-path }}"
```

**Remote action syntax:**
```
uses: OWNER/REPO/.github/actions/ACTION-NAME@REF

REF options:
  @main      → latest on main (changes without warning)
  @v1.0.0    → specific tag (recommended)
  @abc1234   → exact SHA (most stable)
```

**When to use remote actions:**
```
→ Same action needed across multiple repos
→ Centralize in one shared repo
→ All service repos call from shared repo
→ Update once → all repos get the update

For i27Academy:
  Shared repo: i27academy/i27academy-github-actions
  All service repos call: i27academy/i27academy-github-actions/.github/actions/java-build@main
```

---

## 9. Integration with DevOps Dashboard Project

**13.2.1-project-with-composite.yml — project-ci-v6**

This is the DevOps Dashboard CI pipeline updated to use composite actions.

```yaml
name: i27Academy DevOps Dashboard - CI (v6 Composite Actions)

on:
  push:
    branches: [ main ]
    paths: [ 'src/**', 'pom.xml', 'Dockerfile' ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:

env:
  APP_NAME:   i27academy-devops-dashboard
  REGISTRY:   docker.io
  IMAGE_NAME: devopswithcloudhub/i27academy-devops-dashboard

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build and test
        id: build
        uses: ./.github/actions/java-build
        with:
          java-version: '21'
          run-tests: 'true'

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: surefire-reports
          path: target/surefire-reports/
          retention-days: 7

      - name: Notify on failure
        if: failure()
        uses: ./.github/actions/notify-failure
        with:
          service-name: ${{ env.APP_NAME }}
          branch: ${{ github.ref_name }}
          commit: ${{ github.sha }}
          actor: ${{ github.actor }}

  build:
    name: Build JAR
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4

      - name: Build JAR
        id: build
        uses: ./.github/actions/java-build
        with:
          java-version: '21'
          run-tests: 'false'

      - run: echo "IMAGE_TAG=${{ github.sha }}" >> $GITHUB_ENV

      - uses: actions/upload-artifact@v4
        with:
          name: ${{ env.APP_NAME }}
          path: ${{ steps.build.outputs.jar-path }}
          retention-days: 7

      - name: Job Summary
        run: |
          echo "## i27Academy DevOps Dashboard" >> $GITHUB_STEP_SUMMARY
          echo "| Item | Value |" >> $GITHUB_STEP_SUMMARY
          echo "| --- | --- |" >> $GITHUB_STEP_SUMMARY
          echo "| JAR | ${{ steps.build.outputs.jar-path }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Test Result | ${{ steps.build.outputs.test-result }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Image Tag | $IMAGE_TAG |" >> $GITHUB_STEP_SUMMARY
          echo "| Status | ✅ Build Successful |" >> $GITHUB_STEP_SUMMARY
```

**What changed from v5:**
```
v5 had:
  → checkout + setup-java repeated in every job
  → Java version hardcoded in multiple places

v6 adds:
  → .github/actions/java-build handles checkout + setup + build
  → .github/actions/notify-failure handles failure alerts
  → Java version in one place — the action input default
  → JAR path from composite action output
  → Test result from composite action output
```

---

*i27Academy · GitHub Actions Course · Module 13 · i27academy.com*
