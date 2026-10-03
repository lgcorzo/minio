# Kubernetes & MicroK8s Deployment Guide for MinIO

This repository is configured to build, package, and deploy MinIO entirely within the `lgcorzo/minio` GitHub ecosystem using GitHub Container Registry (GHCR) and Helm.

---

## 1. Container Images

Images are built by GitHub Actions ([`.github/workflows/docker-publish.yml`](../.github/workflows/docker-publish.yml)) and published to GHCR:

| Image | Registry URL | Contents |
| :--- | :--- | :--- |
| **MinIO Server** | `ghcr.io/lgcorzo/minio:latest` | MinIO server + embedded `mc` client |
| **MinIO Client** | `ghcr.io/lgcorzo/mc:latest` | Dedicated alias with `mc` client |
| **MicroK8s Optimized** | `ghcr.io/lgcorzo/minio:microk8s-latest` | Operator / Tenant compatible |

---

## 2. Deploying with Helm

### Option A: Install from Local Repository
```bash
# Clone repository
git clone https://github.com/lgcorzo/minio.git
cd minio

# Install Helm chart
helm install minio ./helm/minio \
  --namespace minio \
  --create-namespace \
  --set rootUser=admin \
  --set rootPassword=StrongPassword123
```

### Option B: Install via OCI from GHCR
```bash
helm install minio oci://ghcr.io/lgcorzo/charts/minio \
  --namespace minio \
  --create-namespace \
  --set rootUser=admin \
  --set rootPassword=StrongPassword123
```

---

## 3. Deploying with Raw Kubernetes / MicroK8s Manifests

### Standalone Deployment (Single Node with Persistent Storage)
```bash
kubectl apply -f k8s/standalone/minio.yaml
```

To access the MinIO console and API locally:
```bash
kubectl port-forward svc/minio 9000:9000 9001:9001 -n minio
```
- API: `http://localhost:9000`
- Web Console: `http://localhost:9001` (User: `minioadmin`, Password: `minioadmin`)

### Distributed HA Cluster (4 Replicas StatefulSet)
```bash
kubectl apply -f k8s/distributed/minio.yaml
```

---

## 4. Private Registry Authentication (if repository is private)

If your GHCR package is private, create a Kubernetes secret with your GitHub Personal Access Token (PAT with `read:packages`):

```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<GITHUB_USERNAME> \
  --docker-password=<GITHUB_PAT> \
  --namespace=minio
```

Then in `helm/minio/values.yaml`:
```yaml
imagePullSecrets:
  - name: ghcr-secret
```
