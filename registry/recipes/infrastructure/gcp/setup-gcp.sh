#!/bin/bash
set -e

# ==========================================
# GCP BOOTSTRAP SETUP SCRIPT
# ==========================================
# This script sets up prerequisites for deploying this stack to GCP.
# Run this ONCE per GCP project before using the GitHub Actions workflows.
#
# What this script creates:
# 1. Enables Secret Manager API (other APIs are managed by Terraform)
# 2. Terraform service account (for infrastructure management)
# 3. GitHub Actions service account (for CI/CD)
# 4. Terraform state bucket (GCS)
# 5. Service account keys (for GitHub secrets)
#
# After running this script:
# 1. Upload the service account keys to GitHub Secrets
# 2. Configure GitHub Variables (GCP_PROJECT_ID, GCP_REGION, TERRAFORM_VERSION)
# 3. Run the "🏗️ Bootstrap" workflow to create core infrastructure
# 4. Push code to trigger the "🔄 Release" workflow
# ==========================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure we run from the infrastructure directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${GREEN}=== GCP bootstrap setup ===${NC}"
echo ""
echo -e "${BLUE}This script sets up prerequisites for Terraform + CI/CD on GCP.${NC}"
echo -e "${BLUE}Run this ONCE per GCP project.${NC}"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}ERROR: gcloud CLI is not installed${NC}"
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Prompt for project ID / env / region
read -p "Enter your GCP Project ID (required): " PROJECT_ID
read -p "Enter environment (development/staging/production) (default: development): " ENVIRONMENT
read -p "Enter region (default: europe-west1): " REGION
if [ -z "$PROJECT_ID" ]; then
  echo -e "${RED}ERROR: Project ID is required${NC}"
  exit 1
fi
REGION=${REGION:-europe-west1}
ENVIRONMENT=${ENVIRONMENT:-development}

echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Project ID: $PROJECT_ID"
echo "  Environment: $ENVIRONMENT"
echo "  Region: $REGION"
echo ""
read -p "Is this correct? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo -e "${GREEN}Step 1: Setting active project${NC}"
gcloud config set project "$PROJECT_ID"

echo ""
echo -e "${GREEN}Step 2: Enabling Secret Manager API${NC}"
gcloud services enable secretmanager.googleapis.com --quiet
echo -e "${GREEN}  ✓ Secret Manager API enabled${NC}"

echo ""
echo -e "${GREEN}Step 3: Enabling billing (if not already enabled)${NC}"
echo "Please ensure billing is enabled for this project in the Cloud Console"
echo "https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
read -p "Press enter to continue..."

echo ""
echo -e "${GREEN}Step 4: Creating Terraform service account${NC}"
gcloud iam service-accounts create terraform \
  --display-name="Terraform Service Account" \
  --description="Service account for Terraform infrastructure management" \
  || echo "Service account already exists"

echo ""
echo -e "${GREEN}Step 5: Granting IAM roles to Terraform service account${NC}"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"
echo "  - Cloud Run Admin (for deploying services + setting Cloud Run IAM policies like public invoker)"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/run.admin"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/compute.networkAdmin"
echo "  - Service Account Admin (Terraform creates additional service accounts for Cloud Run)"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountAdmin"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/resourcemanager.projectIamAdmin"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

echo ""
echo -e "${GREEN}Step 6: Creating GitHub Actions CI service account${NC}"
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions CI Service Account" \
  --description="Service account used by GitHub Actions to build and push Docker images" \
  || echo "GitHub Actions service account already exists"

echo ""
echo -e "${GREEN}Step 7: Granting permissions to GitHub Actions service account${NC}"
echo "  - Artifact Registry Writer (for pushing Docker images)"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
echo "  - Secret Manager Secret Accessor (for reading secrets)"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
echo "  - Secret Manager Admin (for creating/updating secrets)"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.admin"

echo ""
echo -e "${GREEN}Step 8: Creating Terraform service account key${NC}"
KEY_FILE="terraform-key-${ENVIRONMENT}.json"
KEY_FILE_ABS="${SCRIPT_DIR}/${KEY_FILE}"
gcloud iam service-accounts keys create "$KEY_FILE" \
  --iam-account=terraform@${PROJECT_ID}.iam.gserviceaccount.com \
  || echo "Key file already exists, reusing: $KEY_FILE_ABS"

echo ""
echo -e "${GREEN}Step 9: Creating GitHub Actions CI service account key${NC}"
GITHUB_KEY_FILE="github-actions-key-${ENVIRONMENT}.json"
GITHUB_KEY_FILE_ABS="${SCRIPT_DIR}/${GITHUB_KEY_FILE}"
gcloud iam service-accounts keys create "$GITHUB_KEY_FILE" \
  --iam-account=github-actions@${PROJECT_ID}.iam.gserviceaccount.com \
  || echo "GitHub Actions key file already exists, reusing: $GITHUB_KEY_FILE_ABS"

echo ""
echo -e "${GREEN}Step 10: Creating GCS bucket for Terraform state${NC}"
BUCKET_NAME="${PROJECT_ID}-terraform-state-${ENVIRONMENT}"
gsutil mb -p "$PROJECT_ID" -l "$REGION" "gs://${BUCKET_NAME}" || echo "Bucket already exists"
gsutil versioning set on "gs://${BUCKET_NAME}"

echo ""
echo -e "${GREEN}Step 11: Exporting Terraform credentials${NC}"
export GOOGLE_APPLICATION_CREDENTIALS="$KEY_FILE_ABS"

# Persist for common shells (zsh and bash)
if [ -f "$HOME/.zshrc" ]; then
  echo "export GOOGLE_APPLICATION_CREDENTIALS=\"${KEY_FILE_ABS}\"" >> "$HOME/.zshrc"
fi
if [ -f "$HOME/.bashrc" ]; then
  echo "export GOOGLE_APPLICATION_CREDENTIALS=\"${KEY_FILE_ABS}\"" >> "$HOME/.bashrc"
fi

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}                     NEXT STEPS                                ${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}1. Update Terraform backend config:${NC}"
echo "   Edit: infrastructure/environments/${ENVIRONMENT}/backend.hcl"
echo "   Set: bucket = \"${BUCKET_NAME}\""
echo ""
echo -e "${BLUE}2. Update Terraform variables:${NC}"
echo "   Edit: infrastructure/environments/${ENVIRONMENT}/terraform.tfvars"
echo ""
echo -e "${BLUE}3. Upload service account keys to GitHub Secrets:${NC}"
echo "   - GCP_TERRAFORM_SA_KEY = contents of ${KEY_FILE}"
echo "   - GCP_GITHUB_SA_KEY = contents of ${GITHUB_KEY_FILE}"
echo "   - DB_USER = your database username"
echo "   - DB_PASSWORD = your database password"
echo "   - TYPESENSE_API_KEY = your Typesense API key"
echo ""
echo -e "${BLUE}4. Configure GitHub Variables:${NC}"
echo "   - GCP_PROJECT_ID = ${PROJECT_ID}"
echo "   - GCP_REGION = ${REGION}"
echo "   - TERRAFORM_VERSION = 1.7.0 (or your preferred version)"
echo ""
echo -e "${BLUE}5. Run the Bootstrap workflow (one-time):${NC}"
echo "   Go to GitHub Actions → '🏗️ Bootstrap (One-Time Setup)'"
echo "   Select environment: ${ENVIRONMENT}"
echo "   This creates: Registry, Database, Redis, VPC, IAM"
echo ""
echo -e "${BLUE}6. Deploy applications:${NC}"
echo "   Option A: Push code to 'develop' or 'production' branch"
echo "   Option B: Run '🔄 Release' workflow manually"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}                  DEPLOYMENT TIMELINE                          ${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────┐"
echo "  │  PHASE 1: PREREQUISITES (this script) - Run ONCE            │"
echo "  │  ─────────────────────────────────────────────────────────  │"
echo "  │  • Creates service accounts                                 │"
echo "  │  • Creates Terraform state bucket                           │"
echo "  │  • Generates service account keys                           │"
echo "  └─────────────────────────────────────────────────────────────┘"
echo "                              ↓"
echo "  ┌─────────────────────────────────────────────────────────────┐"
echo "  │  PHASE 2: BOOTSTRAP (GitHub Actions) - Run ONCE             │"
echo "  │  ─────────────────────────────────────────────────────────  │"
echo "  │  Workflow: '🏗️ Bootstrap (One-Time Setup)'                  │"
echo "  │  Creates:                                                   │"
echo "  │  • Artifact Registry (Docker images)                        │"
echo "  │  • Cloud SQL (PostgreSQL)                                   │"
echo "  │  • Redis (Memorystore)                                      │"
echo "  │  • VPC & Networking                                         │"
echo "  │  • Service Accounts & IAM                                   │"
echo "  └─────────────────────────────────────────────────────────────┘"
echo "                              ↓"
echo "  ┌─────────────────────────────────────────────────────────────┐"
echo "  │  PHASE 3: RELEASE (GitHub Actions) - Run on every deploy    │"
echo "  │  ─────────────────────────────────────────────────────────  │"
echo "  │  Workflow: '🔄 Release'                                     │"
echo "  │  Triggered: Push to develop/production OR manual            │"
echo "  │  Does:                                                      │"
echo "  │  • Builds & pushes Docker images                            │"
echo "  │  • Deploys Cloud Run services                               │"
echo "  │  • Runs database migrations                                 │"
echo "  │  • (Optional) Seeds database                                │"
echo "  │  • (Optional) Typesense migration                           │"
echo "  └─────────────────────────────────────────────────────────────┘"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "- ${KEY_FILE} and ${GITHUB_KEY_FILE} are in .gitignore"
echo "- Never commit service account keys to Git"
echo ""
