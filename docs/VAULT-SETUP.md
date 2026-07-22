# Vault + External Secrets Setup

Store secrets in **HashiCorp Vault** and sync them to Kubernetes using **External Secrets Operator (ESO)**.

> **Note:** Vault is NOT Terraform. Terraform builds AWS infra. Vault is a separate secrets tool installed on the cluster via Helm.

## Architecture

```text
Vault (secret/hello)
        ↓
External Secrets Operator
        ↓
K8s Secret (hello-vault-secret)
        ↓
App pod reads env var / volume
```

## Prerequisites

- EKS cluster running (`ultimatenew-eks-v2`)
- `kubectl` connected to cluster
- `helm` installed

```bash
export AWS_PROFILE=your-profile   # if needed
aws eks update-kubeconfig --region us-east-1 --name ultimatenew-eks-v2
kubectl get nodes
```

---

## Step 1 — Install Vault (dev mode, learning only)

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

kubectl create namespace vault

helm install vault hashicorp/vault -n vault \
  --set "server.dev.enabled=true"
```

Wait for pod:

```bash
kubectl get pods -n vault -w
```

**Dev mode warnings:**
- Root token is `root`
- Secrets stored **in memory** — lost on pod restart
- **NOT for production**

---

## Step 2 — Store a secret in Vault

Use **single quotes** in zsh (avoid `!` issues):

```bash
kubectl exec -n vault vault-0 -- vault kv put secret/hello message='Hello from Vault!'
```

Verify:

```bash
kubectl exec -n vault vault-0 -- vault kv get secret/hello
```

> If ESO later says "Secret does not exist", re-run this command (dev mode loses data on restart).

---

## Step 3 — Install External Secrets Operator

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace
```

Wait for pods:

```bash
kubectl get pods -n external-secrets
kubectl get crd | grep external-secrets
```

---

## Step 4 — Apply Kubernetes manifests

Files in `k8s/vault/`:

| File | Purpose |
|------|---------|
| `vault-token.yaml` | Vault login token for ESO (dev: `root`) |
| `secret-store.yaml` | Tells ESO how to connect to Vault |
| `external-secret.yaml` | Maps Vault secret → K8s secret |

```bash
kubectl create namespace ultimatenew --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f k8s/vault/vault-token.yaml
kubectl apply -f k8s/vault/secret-store.yaml
kubectl apply -f k8s/vault/external-secret.yaml
```

**API version:** use `external-secrets.io/v1` (not `v1beta1`) for newer ESO versions.

---

## Step 5 — Verify sync

```bash
kubectl get secretstore -n ultimatenew
kubectl get externalsecret -n ultimatenew
kubectl get secret hello-vault-secret -n ultimatenew
```

Decode secret:

```bash
kubectl get secret hello-vault-secret -n ultimatenew \
  -o jsonpath='{.data.message}' | base64 -d; echo
```

Expected: `Hello from Vault!`

### If sync fails

```bash
kubectl describe externalsecret hello-vault-secret -n ultimatenew
```

Common fixes:
1. Re-store secret in Vault (dev mode data loss)
2. Check Vault pod is Running: `kubectl get pods -n vault`
3. Re-apply external-secret:

```bash
kubectl delete externalsecret hello-vault-secret -n ultimatenew
kubectl apply -f k8s/vault/external-secret.yaml
```

---

## Step 6 (optional) — Use secret in hello app

Add to `k8s/app/hello.yaml` container spec:

```yaml
env:
  - name: VAULT_MESSAGE
    valueFrom:
      secretKeyRef:
        name: hello-vault-secret
        key: message
```

Push to Git → ArgoCD syncs (if ArgoCD is installed).

---

## Production vs dev (interview notes)

| Dev (this project) | Production |
|--------------------|------------|
| Vault dev mode | Vault HA cluster with persistent storage |
| Root token in K8s secret | Kubernetes auth / IAM auth to Vault |
| Token `root` | Least-privilege Vault policies |
| Manual Helm install | Terraform or GitOps for Vault install |

---

## Uninstall (cleanup)

```bash
kubectl delete -f k8s/vault/external-secret.yaml
kubectl delete -f k8s/vault/secret-store.yaml
kubectl delete -f k8s/vault/vault-token.yaml

helm uninstall external-secrets -n external-secrets
helm uninstall vault -n vault
```
