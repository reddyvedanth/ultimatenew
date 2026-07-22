# ArgoCD Setup (after EKS is running)

ArgoCD watches `k8s/app/` in GitHub and deploys manifests to the cluster (GitOps).

## Install ArgoCD

```bash
kubectl create namespace argocd

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd -n argocd --create-namespace
```

Wait for pods:

```bash
kubectl get pods -n argocd -w
```

## Get admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

## Open UI

**Terminal 1** (leave running):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open **http://localhost:8080** (not https)

Login: `admin` / password from above

## Register app (one-time bootstrap)

```bash
kubectl apply -f k8s/argocd/application.yaml
```

ArgoCD will sync `k8s/app/hello.yaml` from GitHub automatically.

## Verify

```bash
kubectl get application -n argocd
kubectl get pods -n ultimatenew
```

## GitOps test

1. Change `replicas: 2` in `k8s/app/hello.yaml`
2. `git push`
3. Wait ~3 min or hard refresh in ArgoCD UI
4. `kubectl get pods -n ultimatenew`
