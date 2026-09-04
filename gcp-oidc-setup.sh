#!/bin/bash

# ===========================================================================================
#
# What does this script do?
# STEP 1: Enables required GCP APIs
# STEP 2: Create Service Account
# Step 3: Granting admin/owner permissions to Service Account.
# Step 4: Creating Workload Identity Pool
# STEP 5: Create OIDC Provider linked to GitHub Actions
# Step 6: Bind Service Account to GitHub repository
# Step 7: Output values needed for GitHub Actions workflow

# ===========================================================================================

# ── CONFIGURATION — update these values before running ───────

# GCP project where resources will be created
export PROJECT_ID="i27learn-project"

# GitHub organization or username
export GITHUB_ORG="devopswithcloud"

# GitHub repository name (must be exact)
export GITHUB_REPO="i27-dashboard-b10"

# Service account name — identifies what this SA is for
export SA_NAME="i27academy-github-actions-sa"

# Workload identity pool ID — must be unique in the project
export POOL_ID="github-actions-pool"

# OIDC provider ID — identifies GitHub as the identity provider
export PROVIDER_ID="github-actions-provider"

# ── DERIVED VALUES — do not change these ─────────────────────

# Fetch project number automatically from project ID
export PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" \
  --format='value(projectNumber)')

# Full service account email
export SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# ─────────────────────────────────────────────────────────────
echo "============================="
echo "GCP OIDC SETUP"
echo "============================="
echo "Project ID     : $PROJECT_ID"
echo "Project Number : $PROJECT_NUMBER"
echo "GitHub Org     : $GITHUB_ORG"
echo "GitHub Repo    : $GITHUB_REPO"
echo "Service Account: $SA_EMAIL"
echo "Pool ID        : $POOL_ID"
echo "Provider ID    : $PROVIDER_ID"
echo "============================="
echo ""

# ── STEP 1: Enable required GCP APIs ─────────────────────────
echo "Step 1: Enabling required GCP APIs..."

gcloud services enable \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project="$PROJECT_ID"

# iamcredentials.googleapis.com — needed for generating OIDC tokens
# sts.googleapis.com            — Security Token Service — exchanges tokens
# cloudresourcemanager.googleapis.com — needed for IAM policy bindings

echo "APIs enabled ✅"
echo ""

# ── STEP 2: Create Service Account ───────────────────────────
echo "Step 2: Creating Service Account..."

gcloud iam service-accounts create "$SA_NAME" \
  --project="$PROJECT_ID" \
  --display-name="GitHub Actions Service Account (i27Academy)"

echo "Service Account created: $SA_EMAIL ✅"
echo ""

# ── STEP 3: Grant Permissions ────────────────────────────────
echo "Step 3: Granting permissions to Service Account..."

# Granting Project Owner for now
# In production — replace with least-privilege roles
# e.g. roles/compute.admin, roles/storage.admin, roles/run.developer
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/owner"

echo "Permissions granted ✅"
echo ""

# ── STEP 4: Create Workload Identity Pool ────────────────────
echo "Step 4: Creating Workload Identity Pool..."

gcloud iam workload-identity-pools create "$POOL_ID" \
  --project="$PROJECT_ID" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# A pool is a container for external identity providers
# We create one pool and add GitHub as a provider inside it

echo "Workload Identity Pool created ✅"
echo ""

# ── STEP 5: Create OIDC Provider ─────────────────────────────
echo "Step 5: Creating OIDC Provider for GitHub Actions..."

gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="$POOL_ID" \
  --display-name="GitHub Actions Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '${GITHUB_ORG}'"

# issuer-uri       — GitHub's OIDC issuer — fixed value, never changes
# attribute-mapping — maps GitHub token claims to GCP attributes
#   google.subject            ← assertion.sub (unique run identifier)
#   attribute.repository      ← assertion.repository (org/repo)
#   attribute.repository_owner ← assertion.repository_owner (org name)
# attribute-condition — restricts which GitHub orgs can authenticate
#   Only tokens from GITHUB_ORG are accepted

echo "OIDC Provider created ✅"
echo ""

# ── STEP 6: Bind Service Account to GitHub Repo ──────────────
echo "Step 6: Binding Service Account to GitHub repository..."

gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"

# This binding says:
#   "Allow GitHub Actions running from GITHUB_ORG/GITHUB_REPO
#    to impersonate this Service Account"
#
# The principalSet uses attribute.repository to scope access
# to a specific repo — not the entire org

echo "Service Account binding complete ✅"
echo ""

# ── STEP 7: OUTPUT — values needed for GitHub Actions workflow ────────
echo "============================="
echo "SETUP COMPLETE"
echo "============================="
echo ""
echo "Add these as GitHub Secrets in your repo:"
echo "  Repo → Settings → Secrets and variables → Actions → New secret"
echo ""
echo "GCP_SERVICE_ACCOUNT:"
echo "  ${SA_EMAIL}"
echo ""
echo "GCP_WORKLOAD_IDENTITY_PROVIDER:"
echo "  $(gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="$POOL_ID" \
  --format='value(name)')"
echo ""
echo "============================="
echo "NEXT STEPS"
echo "============================="
echo "1. Copy GCP_SERVICE_ACCOUNT value above"
echo "2. Copy GCP_WORKLOAD_IDENTITY_PROVIDER value above"
echo "3. Add both as GitHub Secrets in your repo"
echo "4. Use google-github-actions/auth@v2 in your workflow"
echo "============================="
