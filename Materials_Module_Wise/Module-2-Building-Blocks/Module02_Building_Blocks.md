# Module 02 — GitHub Actions Building Blocks

### i27Academy — GitHub Actions Course

---

## Agenda

1. What is a Workflow?
2. Workflow File Location
3. Understanding the First Workflow
4. Multiple Steps in a Job
5. Multiple Jobs in a Workflow
6. Step and Job Failure Behaviour
7. Job Dependency using `needs`
8. Putting Everything Together

> In this module, we use only shell commands with `run:`.  
> Actions and the `uses:` keyword will be covered as a separate topic.

---

# 1. What is a Workflow?

A **workflow** is an automated process defined using a YAML file.

It tells GitHub Actions:

```text
→ When the automation should start
→ What work should be performed
→ Which machine should perform the work
→ In what order the tasks should execute
```

A workflow can automate activities such as:

```text
→ Validating source code
→ Running tests
→ Building an application
→ Building a Docker image
→ Deploying an application
```

Think of a workflow like a complete recipe:

```text
When should cooking begin?  → Event
Who performs the work?      → Runner
What major work is needed?  → Jobs
What individual tasks?      → Steps
```

## Key Points

```text
→ One YAML file represents one workflow
→ A repository can contain multiple workflows
→ Each workflow runs based on its configured event
→ Workflow files are stored and version-controlled with the source code
```

---

# 2. Where Do We Create a Workflow?

GitHub looks for workflow files only inside:

```text
.github/workflows/
```

Example:

```text
repository/
└── .github/
    └── workflows/
        └── 01-first-workflow.yaml
```

Workflow files can use either extension:

```text
.yml
.yaml
```

## Important Rules

```text
→ The folder must be .github/workflows/
→ One YAML file represents one workflow
→ The filename can be chosen by us
→ Use meaningful filenames
```

---

# 3. Understanding the First Workflow

We will first create one simple workflow and use it to understand all the basic building blocks.

## File: `01-first-workflow.yaml`

```yaml
name: First Workflow

on:
  workflow_dispatch:

jobs:
  first-job:
    runs-on: ubuntu-latest

    steps:
      - name: Print Welcome Message
        run: echo "Welcome to GitHub Actions"
```

---

## 3.1 Workflow Name

```yaml
name: First Workflow
```

The `name` field gives a display name to the workflow.

This name appears in the GitHub Actions UI.

```text
YAML filename : 01-first-workflow.yaml
Workflow name : First Workflow
```

The filename and workflow name do not have to be the same.

---

## 3.2 Event

```yaml
on:
  workflow_dispatch:
```

An **event** is what triggers a workflow.

Without an event, the workflow does not start.

Examples of events include:

```text
push               → Code is pushed
pull_request       → Pull request activity occurs
schedule           → A configured time is reached
workflow_dispatch  → User starts the workflow manually
```

For now, we use:

```yaml
workflow_dispatch:
```

This allows us to run the workflow manually from the GitHub Actions UI.

Detailed events will be covered separately.

---

## 3.3 Job

```yaml
jobs:
  first-job:
```

A **job** is a group of steps that run together on one machine.

Every workflow must contain at least one job.

Here:

```text
first-job → Job ID
```

The job ID:

```text
→ Must be unique inside the workflow
→ Must not contain spaces
→ Should be meaningful
```

Examples:

```yaml
jobs:
  build:
```

```yaml
jobs:
  test:
```

```yaml
jobs:
  deploy:
```

---

## 3.4 Runner

```yaml
runs-on: ubuntu-latest
```

A **runner** is the machine on which a job executes.

Think of it like this:

```text
Job    → Work that must be performed
Runner → Machine that performs the work
```

In this example:

```text
first-job runs on a GitHub-hosted Ubuntu machine
```

Every job must specify a runner using `runs-on`.

Detailed runner types will be covered separately.

---

## 3.5 Steps

```yaml
steps:
```

A **step** is one individual task inside a job.

Examples:

```text
→ Print a message
→ Display the current date
→ Run a command
→ Build an application
→ Execute tests
```

A job can contain one or more steps.

---

## 3.6 The `run` Keyword

```yaml
run: echo "Welcome to GitHub Actions"
```

`run` executes a shell command on the runner.

Examples:

```yaml
run: echo "Hello"
```

```yaml
run: date
```

```yaml
run: pwd
```

Multiple commands can be written using `|`:

```yaml
run: |
  echo "Starting"
  date
  pwd
```

---

## First Workflow Execution Flow

```text
workflow_dispatch
        ↓
First Workflow
        ↓
first-job
        ↓
ubuntu-latest runner
        ↓
Print Welcome Message step
        ↓
echo command executes
```

## Key Points

```text
→ name identifies the workflow
→ on defines the event
→ jobs contains the jobs
→ first-job is the job ID
→ runs-on selects the runner
→ steps contains individual tasks
→ run executes a shell command
```

---

# 4. Multiple Steps in One Job

A job can contain multiple steps.

Steps inside the same job execute **sequentially**, from top to bottom.

## File: `02-multi-steps.yaml`

```yaml
name: Multi Step Workflow

on:
  workflow_dispatch:

jobs:
  first-job:
    runs-on: ubuntu-latest

    steps:
      - name: Step 1
        run: echo "Executing Step 1"

      - name: Step 2
        run: echo "Executing Step 2"

      - name: Step 3
        run: echo "Executing Step 3"
```

## Execution Flow

```text
Step 1
  ↓
Step 2
  ↓
Step 3
```

Step 2 starts only after Step 1 completes.

Step 3 starts only after Step 2 completes.

## Steps Share the Same Runner

All steps inside one job execute on the same runner.

```text
first-job
└── Ubuntu Runner
    ├── Step 1
    ├── Step 2
    └── Step 3
```

Therefore, steps inside the same job share:

```text
→ The same machine
→ The same filesystem
→ The same working directory
```

Example:

```yaml
steps:
  - name: Create File
    run: echo "Hello" > message.txt

  - name: Read File
    run: cat message.txt
```

The second step can read the file created by the first step.

## Key Points

```text
→ Steps run sequentially
→ Steps run in the order they are written
→ Steps inside one job share the same runner
→ A later step normally runs only if the previous step succeeds
```

---

# 5. Multiple Jobs in One Workflow

A workflow can contain multiple jobs.

## File: `03-multiple-jobs.yaml`

```yaml
name: 1-My First Workflow

on:
  - workflow_dispatch

jobs:
  my-first-job:
    name: My First Job
    runs-on: ubuntu-latest

    steps:
    - name: Step 1 - Say Helloo
      run: |
        sleep 10
        echo "******* Welcome to My First Workflow *******"

    - name: Step 2 - What is the date today?
      run: date

    - name: Step 3 - Print working directory
      run: pwd

  my-second-job:
    name: My Second Job
    runs-on: ubuntu-latest

    steps:
    - name: Step 1 - Say Hello Again
      run: |
        sleep 5
        echo "******* Hello again from My Second Job *******"
```

## Jobs Run in Parallel by Default

If no dependency is defined, jobs start independently.

```text
My First Job   ───────────────→
My Second Job  ───────→
```

Both jobs start around the same time.

The second job can finish first even though it appears later in the YAML file.

## Job ID vs Job Name

```yaml
my-first-job:
  name: My First Job
```

```text
my-first-job → Internal job ID
My First Job → Display name shown in the UI
```

## Each Job Uses a Separate Runner

```text
my-first-job  → Runner A
my-second-job → Runner B
```

```text
Workflow
├── My First Job  → Runner A
│   ├── Step 1
│   ├── Step 2
│   └── Step 3
│
└── My Second Job → Runner B
    └── Step 1
```

Files created in one job are not automatically available in another job.

## Key Points

```text
→ A workflow can contain multiple jobs
→ Independent jobs run in parallel
→ YAML order does not control job execution order
→ Every job gets its own runner environment
→ Jobs do not automatically share files
```

---

# 6. What Happens When a Step Fails?

A command normally succeeds when it returns exit code `0`.

A non-zero exit code normally indicates failure.

```text
exit 0 → Success
exit 1 → Failure
```

## File: `04-step-failure.yaml`

```yaml
name: Step Failure Demo

on:
  workflow_dispatch:

jobs:
  first-job:
    runs-on: ubuntu-latest

    steps:
      - name: Step 1
        run: echo "Step 1 Successful"

      - name: Step 2 Fail Intentionally
        run: |
          echo "Failing this step intentionally"
          exit 1 

      - name: Step 3
        run: echo "This step will be skipped"
```

## Execution Flow

```text
Step 1 → Success
Step 2 → Failure
Step 3 → Skipped
Job    → Failed
```

When a step fails:

```text
→ The job is marked as failed
→ Remaining normal steps in the same job are skipped
→ The workflow run shows a failure
```

## Key Point

```text
A failed step affects the remaining steps inside the same job.
```

---

# 7. What Happens to Other Independent Jobs?

A failed job does not automatically stop another independent job.

## File: `05-independent-job-failure.yaml`

```yaml
name: 4-Failure-Demo
on: 
  workflow_dispatch:
jobs: 
  first-job:
    name: First-Job-Failure-Demo
    runs-on: ubuntu-latest
    steps:
    - name: Failure replication step
      run: |
        echo "This job will fail intentionally"
        exit 1
    - name: This step will be skipped due to the failure of the previous step
      run: echo "This step will be skipped"
    
  second-job:
    runs-on: ubuntu-latest
    steps:
    - name: This job runs even if the first job fails
      run: |
        echo "This job will run even if the first job fails"
        echo "This demonstrates that the workflow continues despite the failure of the first job"
```

## Execution Flow

```text
First Job  → Fails
Second Job → Runs independently
```

The complete workflow is marked as failed because one job failed.

However, the second job continues because it does not depend on the first job.

## Step Failure vs Independent Job Failure

### Steps in the same job

```text
Step 1 → Success
Step 2 → Failure
Step 3 → Skipped
```

### Independent jobs

```text
Job 1 → Failure
Job 2 → Continues
```

## Key Points

```text
→ Independent jobs run separately
→ Failure of one independent job does not stop another
→ The workflow is marked failed if any job fails
```

---

# 8. Job Dependency Using `needs`

Jobs run in parallel by default.

When jobs must execute in a specific order, use `needs`.

Example:

```text
Build
  ↓
Test
  ↓
Deploy
```

## File: `06-job-dependency.yaml`

```yaml
name: Job Dependecny
on:
  workflow_dispatch:
jobs: 
  build:
    runs-on: ubuntu-latest
    steps: 
    - name: Build 
      run: |
        echo "Building the project..."
        sleep 10
        echo "Build completed successfully"
  test:
    name: Test Job
    runs-on: ubuntu-latest
    needs: build
    steps: 
    - name: Run Tests
      run: |
        echo "Running tests..."
        sleep 10
        echo "All tests passed successfully"
  deploy:
    name: Deploy Job
    runs-on: ubuntu-latest
    needs:
    - build
    - test
    steps: 
    - name: Deploy Application
      run: |
        echo "Deploying the application..."
        sleep 10
        echo "Application deployed successfully"
```

## Understanding `needs`

```yaml
needs: build
```

This means:

```text
The test job waits for the build job to complete successfully.
```

```yaml
needs:
  - build
  - test
```

This means:

```text
The deploy job waits for both build and test.
```

## Execution Flow

```text
build
  ↓
test
  ↓
deploy
```

## Failure Behaviour

If `build` fails:

```text
build  → Failed
test   → Skipped
deploy → Skipped
```

A dependent job normally runs only when all jobs listed in `needs` complete successfully.

## Key Points

```text
→ Jobs run in parallel by default
→ needs creates job dependencies
→ A dependent job waits for required jobs
→ If a required job fails, the dependent job is skipped
→ needs can reference one job or multiple jobs
```

---

# 9. Putting Everything Together

```text
Event
  ↓
Triggers the Workflow
  ↓
Workflow contains Jobs
  ↓
Each Job runs on a Runner
  ↓
Each Job contains Steps
  ↓
Each Step executes a command using run
```

## Default Behaviour

```text
Steps inside a job → Sequential
Independent jobs   → Parallel
```

## Controlled Behaviour

```text
needs → Makes jobs wait for other jobs
```

## Failure Behaviour

```text
Failed step
  ↓
Remaining steps in that job are skipped
```

```text
Failed independent job
  ↓
Other independent jobs continue
```

```text
Failed required job
  ↓
Dependent jobs are skipped
```

---

# 10. Quick Comparison

| Building Block | Purpose |
|---|---|
| Workflow | Complete automated process |
| Event | Starts the workflow |
| Job | Group of related steps |
| Runner | Machine that executes a job |
| Step | Individual task inside a job |
| `run` | Executes a shell command |
| `needs` | Creates a dependency between jobs |

---

# 11. Module Summary

```text
→ A workflow is an automated process defined in YAML
→ Workflow files live inside .github/workflows/
→ An event triggers a workflow
→ A workflow contains one or more jobs
→ A job runs on a runner
→ A job contains one or more steps
→ Steps inside a job execute sequentially
→ Steps inside one job share the same runner
→ Independent jobs run in parallel
→ Every job gets its own runner environment
→ A failed step skips later normal steps in the same job
→ A failed independent job does not stop other independent jobs
→ needs creates job dependencies
→ A failed required job causes dependent jobs to be skipped
```

---

*i27Academy · GitHub Actions Course · Module 02*
