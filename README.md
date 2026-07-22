# ultimatenew — DevOps/GitOps Learning Project

EKS infrastructure with Terraform, GitHub Actions (OIDC), ArgoCD GitOps, App CI/CD, and HashiCorp Vault + External Secrets.

## Architecture

```text
GitHub Repo
├── terraform/          → VPC + EKS (GitHub Actions + OIDC)
├── app/                  → App source + Dockerfile
├── k8s/app/              → Kubernetes manifests (ArgoCD syncs)
├── k8s/argocd/           → ArgoCD Application
├── k8s/vault/            → Vault + External Secrets configs
└── .github/workflows/
    ├── infra.yaml        → Terraform plan/apply (OIDC + approval)
    └── app-ci.yml        → Build image → GHCR → update manifest
```

## Project values (update if yours differ)

| Item | Value |
|------|-------|
| AWS Account | `202264954476` |
| AWS Region | `us-east-1` |
| EKS Cluster | `ultimatenew-eks-v2` |
| GitHub Repo | `reddyvedanth/ultimatenew` |
| Terraform State S3 | `ultimatenew-tf-state-202264954476` |
| DynamoDB Lock | `ultimatenew-tf-lock` |
| IAM OIDC Role | `github-actions-terraform` |

## Quick rebuild order

1. [OIDC Setup](docs/OIDC-SETUP.md) — one-time AWS + GitHub config
2. [Infra Deploy](docs/OIDC-SETUP.md#deploy-infrastructure) — Terraform via GitHub Actions
3. [ArgoCD Setup](docs/ARGOCD-SETUP.md) — GitOps for app manifests
4. [Vault Setup](docs/VAULT-SETUP.md) — secrets via External Secrets Operator
5. [Troubleshooting](docs/TROUBLESHOOTING.md) — common errors and fixes

## Prerequisites (local laptop)

```bash
aws --version
terraform --version
kubectl version --client
helm version
```

Configure AWS profile (if needed):

```bash
export AWS_PROFILE=your-profile
aws sts get-caller-identity
```

Connect to cluster after EKS is up:

```bash
aws eks update-kubeconfig --region us-east-1 --name ultimatenew-eks-v2
kubectl get nodes
```

## Cost warning

EKS + NAT Gateway costs ~$100+/month while running. Run `terraform destroy` (with manager approval) when not learning.

## Documentation

- [OIDC Setup (GitHub Actions → AWS)](docs/OIDC-SETUP.md)
- [Vault + External Secrets Setup](docs/VAULT-SETUP.md)
- [ArgoCD Setup](docs/ARGOCD-SETUP.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
