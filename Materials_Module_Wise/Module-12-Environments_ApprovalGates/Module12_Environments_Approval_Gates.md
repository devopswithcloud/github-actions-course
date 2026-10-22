# Module 12 — Environments & Approval Gates
### i27Academy — GitHub Actions Course

---

## Agenda

1. What are environments
2. Creating environments in GitHub UI
3. Using environments in workflows
4. Environment secrets
5. Environment URL
6. dev → staging → production promotion
7. Tag-based deployments
8. Concurrency in deployments
9. Jenkins input() vs GitHub Environments

---

## 1. What are Environments

An environment in GitHub Actions is a named deployment target with optional protection rules. When a job targets an environment, GitHub can:

- Pause the workflow and wait for approval
- Restrict which branches or tags can deploy
- Provide environment-specific secrets
- Record a full deployment audit trail

```
Without environments:
  → Code deploys to production automatically on every push
  → No approval, no audit trail, no access control

With environments:
  → dev deploys automatically
  → staging deploys automatically after dev
  → production STOPS — waits for human approval
  → Full audit trail — who approved, when, from which IP
```

---

## 2. Creating Environments in GitHub UI

```
Repo → Settings → Environments → New environment
```

**Create three environments:**

**development — no protection:**
```
Name: development
No required reviewers
No wait timer
All branches allowed
```

**staging — no protection:**
```
Name: staging
No required reviewers
No wait timer
All branches allowed
```

**production — protected:**
```
Name: production
Required reviewers: your GitHub username
Wait timer: 0 minutes
Deployment branches: Selected branches → main
```

Once production has required reviewers set — any job targeting this environment will pause and send a notification to reviewers before continuing.

---

## 3. Using Environments in Workflows

Add `environment:` to a job to target a specific environment.

**12.1.1-environment-basic.yml**

```yaml
name: 12.1.1-Environment-Basic

on:
  workflow_dispatch:

jobs:
  deploy-dev:
    name: Deploy to Development
    runs-on: ubuntu-latest
    environment:
      name: development
      url: https://dev.i27academy.com
    steps:
      - run: echo "Deploying to development ✅"

  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: deploy-dev
    environment:
      name: staging
      url: https://staging.i27academy.com
    steps:
      - run: echo "Deploying to staging ✅"

  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: deploy-staging
    environment:
      name: production
      url: https://i27academy.com
    steps:
      - run: echo "Deploying to production ✅"
```

**What happens when this runs:**

```
deploy-dev    → runs automatically ✅
deploy-staging → runs automatically after dev ✅
deploy-production → PAUSES ⏸️
  → GitHub sends notification to required reviewers
  → Reviewer goes to Actions tab
  → Clicks "Review deployments" button
  → Selects production → clicks "Approve and deploy"
  → Workflow continues → production deploys ✅
  → Full audit trail recorded in Deployments tab
```

**Simple form — just environment name:**
```yaml
environment: production
```

**Full form — with URL:**
```yaml
environment:
  name: production
  url: https://i27academy.com
```

The URL shows as a clickable link in the GitHub deployments UI.

---

## 4. Environment Secrets

Secrets scoped to a specific environment — only accessible when the job targets that environment.

**Setting up:**
```
Repo → Settings → Environments → staging → Add secret
  STAGING_DB_URL = jdbc:postgresql://staging-server/db

Repo → Settings → Environments → production → Add secret
  PROD_DB_URL = jdbc:postgresql://prod-server/db
```

**12.1.2-environment-secrets.yml**

```yaml
name: 12.1.2-Environment-Secrets

on:
  workflow_dispatch:

jobs:
  staging-deploy:
    runs-on: ubuntu-latest
    environment: staging              # unlocks staging secrets
    steps:
      - run: |
          echo "STAGING_DB_URL is set : ${{ secrets.STAGING_DB_URL != '' }}"
          echo "PROD_DB_URL is set    : ${{ secrets.PROD_DB_URL != '' }}"
          # STAGING_DB_URL → true ✅
          # PROD_DB_URL    → false ❌ (wrong environment)

  no-environment:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "STAGING_DB_URL is set : ${{ secrets.STAGING_DB_URL != '' }}"
          echo "PROD_DB_URL is set    : ${{ secrets.PROD_DB_URL != '' }}"
          # Both → false ❌ (no environment declared)
```

**Critical rule:**

```
environment: staging   → staging secrets accessible
environment: production → production secrets accessible
no environment:         → ALL environment secrets are SILENTLY EMPTY

No error is thrown — they are just empty strings
This is one of the most common gotchas in GitHub Actions
```

---

## 5. Tag-Based Deployments

Trigger production deployments only when a version tag is pushed.

**12.2.1-tag-based-deployment.yml**

```yaml
name: 12.2.1-Tag-Based-Deployment

on:
  push:
    tags:
      - 'v*'          # v1.0.0, v1.2.3, v2.0.0

jobs:
  build:
    outputs:
      version: ${{ steps.ver.outputs.value }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: temurin
          cache: maven
      - run: mvn package -DskipTests
      - id: ver
        run: echo "value=${{ github.ref_name }}" >> $GITHUB_OUTPUT

  deploy-staging:
    needs: build
    environment:
      name: staging
      url: https://staging.i27academy.com
    steps:
      - run: echo "Deploying ${{ needs.build.outputs.version }} to staging"

  deploy-production:
    needs: [ build, deploy-staging ]
    environment:
      name: production
      url: https://i27academy.com
    steps:
      - run: |
          echo "Version    : ${{ needs.build.outputs.version }}"
          echo "Tag        : ${{ github.ref_name }}"
          echo "Approved by: ${{ github.actor }}"
```

**How to trigger:**
```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub detects the `v*` tag and fires the workflow automatically.

**Branch restriction in environment settings:**
```
Settings → Environments → production
→ Deployment branches and tags
→ Add pattern: main
→ Add pattern: v*
```

Now only `main` branch and `v*` tags can deploy to production — feature branches cannot reach production even if someone manually triggers the workflow.

---

## 6. Concurrency in Deployments

**12.3.1-concurrency-deployments.yml**

```yaml
jobs:
  ci:
    concurrency:
      group: ci-${{ github.ref }}
      cancel-in-progress: true      # cancel old CI — new commit arrived

  deploy-dev:
    concurrency:
      group: deploy-development
      cancel-in-progress: false     # NEVER cancel a running deploy

  deploy-production:
    concurrency:
      group: deploy-production
      cancel-in-progress: false     # NEVER cancel production deploy
```

**cancel-in-progress: true vs false:**

| Setting | Behaviour | Use for |
|---|---|---|
| `true` | New run arrives → old run cancelled | CI runs — only latest matters |
| `false` | New run arrives → queues and waits | Deploys — never interrupt mid-flight |

**group naming:**
```
ci-${{ github.ref }}    → separate group per branch
                          master CI and develop CI don't block each other

deploy-production       → global group
                          only one production deploy runs at a time worldwide
```

---

## 7. Full Promotion Pipeline

**12.4.1-full-promotion-pipeline.yml**

The complete dev → staging → production pipeline with all concepts combined.

```yaml
on:
  push:
    branches: [ main ]
    paths: [ 'src/**', 'pom.xml', 'Dockerfile' ]
  workflow_dispatch:

jobs:
  build:
    outputs:
      image-tag: ${{ steps.tag.outputs.value }}
    steps: [...]

  deploy-dev:
    needs: build
    concurrency: { group: deploy-development, cancel-in-progress: false }
    environment: { name: development, url: https://dev.i27academy.com }
    steps: [...]

  deploy-staging:
    needs: [ build, deploy-dev ]
    concurrency: { group: deploy-staging, cancel-in-progress: false }
    environment: { name: staging, url: https://staging.i27academy.com }
    steps: [...]

  deploy-production:
    needs: [ build, deploy-staging ]
    concurrency: { group: deploy-production, cancel-in-progress: false }
    environment: { name: production, url: https://i27academy.com }
    steps: [...]

  summary:
    needs: [ build, deploy-dev, deploy-staging, deploy-production ]
    if: always()
    steps: [write deployment summary...]
```

**Full flow:**
```
Push to main (src/ or pom.xml or Dockerfile changes)
        ↓
build (test + package + upload JAR)
        ↓
deploy-dev (automatic)
        ↓
deploy-staging (automatic)
        ↓
deploy-production ⏸️ PAUSES — awaits approval
        ↓ approved
production deployed ✅
        ↓
summary (always — shows all results)
```

---

## 8. Jenkins input() vs GitHub Environments

**Jenkins approach:**
```groovy
stage('Deploy to Production') {
  input {
    message 'Deploy to production?'
    submitter 'sivasre,teamlead'
    timeout(time: 300, unit: 'SECONDS')
  }
  steps {
    sh './deploy.sh production'
  }
}
```

**GitHub Actions approach:**
```yaml
deploy-production:
  environment: production    # protection configured in GitHub UI
  steps:
    - run: ./deploy.sh production
```

**Comparison:**

| | Jenkins input() | GitHub Environments |
|---|---|---|
| Blocks executor | Yes — costs a build slot | No — zero cost while waiting |
| Audit trail | Minimal | Full — who, when, IP address |
| Named reviewers | `submitter` param in code | Required reviewers in GitHub UI |
| Branch restriction | Manual if check | Built into environment config |
| Notification | None by default | Email + GitHub notification |
| Environment secrets | Not scoped | Scoped per environment |
| Timeout | `timeout()` wrapper | Wait timer in Settings |

---


---

*i27Academy · GitHub Actions Course · Module 12 · i27academy.com*
