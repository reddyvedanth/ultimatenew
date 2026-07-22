# Troubleshooting Guide

Common errors encountered in this project and how to fix them.

---

## Terraform state lock

**Error:**
```text
Error acquiring the state lock
ConditionalCheckFailedException
```

**Cause:** Another terraform run holds the DynamoDB lock (or stale lock from crashed run).

**Fix:**
1. Cancel in-progress GitHub Actions workflows
2. Force unlock:
   ```bash
   cd terraform
   terraform force-unlock <LOCK_ID>
   ```
3. Re-run workflow

**Prevention:** `concurrency: group: terraform-infra` in `infra.yaml`

---

## KMS alias already exists

**Error:**
```text
AlreadyExistsException: alias/eks/ultimatenew-eks already exists
```

**Cause:** Previous `terraform destroy` left KMS alias/key (7-day deletion window).

**Fix options:**
1. Change cluster name in `terraform.tfvars` (e.g. `ultimatenew-eks-v2`)
2. Or cancel KMS deletion + delete alias:
   ```bash
   aws kms cancel-key-deletion --key-id <KEY_ID> --region us-east-1
   aws kms delete-alias --alias-name alias/eks/ultimatenew-eks --region us-east-1
   ```

---

## CloudWatch log group already exists

**Fix:**
```bash
aws logs delete-log-group \
  --log-group-name /aws/eks/<cluster-name>/cluster \
  --region us-east-1
```

---

## Git push rejected (non-fast-forward)

**Cause:** GitHub Actions bot committed back to repo (e.g. `ci: update hello image`).

**Fix:**
```bash
git pull --rebase origin main
git push origin main
```

---

## ArgoCD namespace not found (Helm)

**Error:**
```text
namespaces "argocd" not found
```

**Fix:**
```bash
kubectl create namespace argocd
# or
helm install argocd argo/argo-cd -n argocd --create-namespace
```

---

## ArgoCD UI not reachable

**Causes:**
1. Port-forward stopped (Ctrl+C) — restart it
2. Used `https://` instead of `http://localhost:8080`

**Fix:**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open http://localhost:8080
```

---

## ExternalSecret CRD not found

**Error:**
```text
no matches for kind "SecretStore" in version "external-secrets.io/v1beta1"
```

**Fix:**
1. Install ESO first (see [VAULT-SETUP.md](VAULT-SETUP.md))
2. Use `apiVersion: external-secrets.io/v1` in manifests

---

## Vault secret not syncing

**Error:** `Secret does not exist` or `connection refused`

**Fixes:**
1. Vault dev mode loses secrets on pod restart — re-store:
   ```bash
   kubectl exec -n vault vault-0 -- vault kv put secret/hello message='Hello from Vault!'
   ```
2. Check Vault is running: `kubectl get pods -n vault`
3. Re-apply external-secret:
   ```bash
   kubectl delete externalsecret hello-vault-secret -n ultimatenew
   kubectl apply -f k8s/vault/external-secret.yaml
   ```

---

## zsh quote error (`dquote>`)

**Cause:** `!` inside double quotes in zsh.

**Fix:** Use single quotes:
```bash
kubectl exec -n vault vault-0 -- vault kv put secret/hello message='Hello from Vault!'
```

---

## AWS profile wrong command

**Wrong:** `aws config my-profile`

**Correct:**
```bash
export AWS_PROFILE=my-profile
aws sts get-caller-identity
```

---

## Second pod Pending (replicas: 2)

**Cause:** Cluster capacity / node scaling delay.

**Check:**
```bash
kubectl describe pod <pod-name> -n ultimatenew
kubectl get nodes
```

Wait for EKS Auto Mode to scale nodes.
