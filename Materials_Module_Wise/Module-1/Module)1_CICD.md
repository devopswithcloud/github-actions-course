## What Is CI/CD?

Before learning GitHub Actions, we should understand the problem it solves.

When developers write application code, that code must go through several stages before users can access the application.

A typical software delivery flow looks like this:

```text
Developer writes code
        ↓
Code is reviewed
        ↓
Application is built
        ↓
Tests are executed
        ↓
Application is deployed
        ↓
Users access the application
```

If every stage is performed manually, the process becomes slow, repetitive, and error-prone.

CI/CD helps automate this software delivery process.

---

## What Is CI?

**CI stands for Continuous Integration.**

Continuous Integration is the practice of frequently adding code changes to a shared repository and automatically validating those changes.

Whenever a developer pushes code, the CI process can automatically:

```text
→ Download the latest source code
→ Install required dependencies
→ Compile or build the application
→ Run unit tests
→ Perform code-quality checks
→ Identify problems early
```

### Simple Example

Assume three developers are working on the same application:

```text
Developer A → Login feature
Developer B → Payment feature
Developer C → Notification feature
```

They frequently push their changes to GitHub.

Without CI:

```text
Developers combine their code manually
        ↓
Conflicts or build errors may appear later
        ↓
The team spends more time finding the issue
```

With CI:

```text
Developer pushes code
        ↓
CI workflow starts automatically
        ↓
Application is built
        ↓
Tests are executed
        ↓
Team immediately knows whether the change is valid
```

### Main Goal of CI

```text
Integrate code frequently and identify problems as early as possible.
```

---

## What Is CD?

**CD can mean Continuous Delivery or Continuous Deployment.**

Both start after the CI process successfully validates the application.

---

## Continuous Delivery

Continuous Delivery means every successful code change is automatically built, tested, and usually deployed through lower environments, while remaining ready for production deployment through manual approval.

The process may automatically:

```text
→ Build the application package
→ Create a Docker image
→ Push the image to a registry
→ Deploy to a test or staging environment
→ Run additional validation
```

However, production deployment normally requires manual approval.

```text
Code pushed
    ↓
Build
    ↓
Test
    ↓
Package
    ↓
Deploy to staging
    ↓
Manual approval
    ↓
Deploy to production
```

### Main Goal

```text
Keep the application ready for production deployment at any time.
```

---

## Continuous Deployment

Continuous Deployment goes one step further.

When all validations pass, the application is automatically deployed to production without manual approval.

```text
Code pushed
    ↓
Build
    ↓
Test
    ↓
Package
    ↓
Deploy automatically to production
```

### Main Goal

```text
Deliver successful code changes to users automatically.
```

---

## Continuous Delivery vs Continuous Deployment

| Continuous Delivery                  | Continuous Deployment                               |
| ------------------------------------ | --------------------------------------------------- |
| Application is ready for production  | Application is automatically released to production |
| Production deployment needs approval | No manual production approval                       |
| Safer for controlled releases        | Faster release cycle                                |
| Common in enterprise environments    | Common in highly automated environments             |

---

## Complete CI/CD Flow

```text
Developer pushes code
        ↓
Continuous Integration
        ├── Build
        ├── Test
        └── Validate
        ↓
Continuous Delivery
        ├── Package application
        ├── Create deployment artifact
        └── Prepare for deployment
        ↓
Continuous Deployment
        └── Deploy automatically to production
```

---

## Real-World Example

Consider the i27Helpdesk application.

A developer changes the login functionality and pushes the code to GitHub.

The CI/CD process may perform the following steps:

```text
1. Download the latest source code
2. Compile the backend application
3. Run unit tests
4. Build the frontend application
5. Create Docker images
6. Push images to a container registry
7. Deploy the application to Kubernetes
8. Verify that the application is running
```

Instead of a DevOps engineer performing these tasks manually every time, the complete process can be automated.

---

## Where Does GitHub Actions Fit?

GitHub Actions is an automation platform that can implement CI/CD workflows directly inside GitHub.

For example:

```text
Developer pushes code to GitHub
        ↓
GitHub Actions workflow starts
        ↓
Application is built
        ↓
Tests are executed
        ↓
Docker image is created
        ↓
Application is deployed
```

GitHub Actions is not CI/CD itself.

It is a tool that allows us to create and execute CI/CD automation.

---

## Why Do We Need CI/CD?

```text
→ Reduces manual work
→ Detects errors early
→ Provides consistent build and deployment steps
→ Helps teams release applications faster
→ Reduces human mistakes
→ Makes deployments repeatable
→ Provides execution logs and visibility
→ Improves collaboration between development and operations teams
```

---

## Important Clarification

CI/CD does not mean that every code change must be deployed directly to production.

Organizations decide:

```text
→ Which events start the pipeline
→ Which tests must pass
→ Which environments are used
→ Whether approval is required
→ When production deployment should happen
```

CI/CD automates the process according to the organization’s rules.

---

## Simple Summary

```text
CI
→ Integrate, build and test the code continuously

Continuous Delivery
→ Keep the application ready for deployment

Continuous Deployment
→ Automatically deploy successful changes to production

GitHub Actions
→ Tool used to automate these CI/CD activities
```
