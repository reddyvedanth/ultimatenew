# OIDC Setup — GitHub Actions to AWS (no access keys)

This guide configures **OpenID Connect (OIDC)** so GitHub Actions can assume an AWS IAM role without storing `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` in GitHub Secrets.

## What OIDC does

```text
GitHub Actions job starts
        ↓
Requests short-lived token from GitHub OIDC
        ↓
AWS validates token (IAM OIDC provider)
        ↓
Assumes IAM role → runs terraform plan/apply
```

**No long-lived AWS keys in GitHub.**

---

## One-time AWS setup

### Step 1 — Create OIDC identity provider

**AWS Console:** IAM → Identity providers → Add provider

| Field | Value |
|-------|-------|
| Provider type | OpenID Connect |
| Provider URL | `https://token.actions.githubusercontent.com` |
| Audience | `sts.amazonaws.com` |

**CLI:**

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

If it already exists, skip this step.

---

### Step 2 — Create IAM role

**Role name:** `github-actions-terraform`

**Trust policy** (restricts to your repo only):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::202264954476:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:reddyvedanth/ultimatenew:*"
        }
      }
    }
  ]
}
```

**Attach policy:** `AdministratorAccess` (learning only — scope down in production)

**Role ARN:**

```text
arn:aws:iam::202264954476:role/github-actions-terraform
```

---

### Step 3 — Terraform remote state (already configured)

| Resource | Name |
|----------|------|
| S3 bucket | `ultimatenew-tf-state-202264954476` |
| DynamoDB table | `ultimatenew-tf-lock` |
| State key | `eks/terraform.tfstate` |

---

## GitHub setup

### Manager approval (production environment)

1. Repo → **Settings → Environments** → **New environment** → `production`
2. **Required reviewers** → add manager GitHub account
3. **Deployment branches** → `main` only (optional)

### Workflow configuration (already in `.github/workflows/infra.yaml`)

Key settings:

```yaml
permissions:
  id-token: write    # required for OIDC
  contents: read

concurrency:
  group: terraform-infra
  cancel-in-progress: false
```

OIDC credentials step:

```yaml
- name: Configure AWS credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::202264954476:role/github-actions-terraform
    aws-region: us-east-1
```

Apply job uses approval gate:

```yaml
apply:
  environment: production   # waits for manager approval
```

### GitHub secrets to REMOVE (after OIDC works)

- `AWS_ACCESS_KEY_ID` — delete
- `AWS_SECRET_ACCESS_KEY` — delete
- `AWS_REGION` — delete (hardcoded in workflow)

---

## Deploy infrastructure

### Option A — Push terraform changes

```bash
git add terraform/
git commit -m "infra change"
git pull --rebase origin main
git push origin main
```

### Option B — Manual trigger

**Actions → Terraform Infra → Run workflow**

### Flow

```text
Push to main (terraform/**)
        ↓
plan job runs automatically
        ↓
apply job waits for manager approval
        ↓
Manager clicks "Approve and deploy"
        ↓
terraform apply (~15-20 min for EKS)
```

### PR flow

```text
Open PR with terraform changes → plan only (no apply)
Merge PR to main → plan + apply (with approval)
```

---

## Verify OIDC works

In GitHub Actions logs, look for:

```text
Assuming role with OIDC
Authenticated as assumedRoleId AROA...:GitHubActions
```

---

## Interview talking points

- OIDC replaces long-lived credentials with short-lived tokens
- Trust policy scopes access to specific GitHub repo/branch
- `id-token: write` permission required in workflow
- Manager approval via GitHub Environments before apply
