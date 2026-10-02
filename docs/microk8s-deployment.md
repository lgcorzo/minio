# Deploying Custom MinIO Image to MicroK8s

This guide explains how to build, publish, and deploy this custom MinIO image to a MicroK8s Kubernetes cluster.

---

## 1. Automated CI/CD Pipeline (GitHub Actions)

The workflow [`.github/workflows/docker-publish.yml`](../.github/workflows/docker-publish.yml) automates building and publishing the Docker image on:
- Push to `master`, `main`, or `feat/**` / `feature/**` branches.
- Release creation and version tags (`RELEASE.*`, `v*`).
- Manual trigger via `workflow_dispatch` (with optional custom tag input).

### Published Registries:
1. **GitHub Container Registry (GHCR)**:
   - `ghcr.io/lgcorzo/minio:latest`
   - `ghcr.io/lgcorzo/minio:microk8s-latest`
   - `ghcr.io/lgcorzo/minio:<commit-sha>`
2. **Docker Hub** (when `DOCKER_HUB_USERNAME` and `DOCKER_HUB_ACCESS_TOKEN` secrets are provided):
   - `docker.io/<username>/minio:latest`
   - `docker.io/<username>/minio:microk8s-latest`

---

## 2. Direct Local MicroK8s Deployment

You can build and deploy the image directly to your local MicroK8s cluster without waiting for CI/CD using the provided helper script:

### Option A: Push to MicroK8s Built-in Registry (Recommended)
MicroK8s includes a container registry addon listening on `localhost:32000`.
```bash
./scripts/deploy-to-microk8s.sh registry microk8s-latest
```
This builds and pushes the image to:
```text
localhost:32000/minio:microk8s-latest
```

### Option B: Import Directly into MicroK8s Containerd
```bash
./scripts/deploy-to-microk8s.sh import microk8s-latest
```

---

## 3. Configuring MicroK8s MinIO Tenant

In your GitOps repository (`gitops_internal_lgcorzo/infrastructure/storage/mlflow-minio.yaml`), update the `spec.image` field to reference the image:

### Using GHCR Image:
```yaml
apiVersion: minio.min.io/v2
kind: Tenant
metadata:
  name: mlflow-minio
  namespace: storage
spec:
  image: ghcr.io/lgcorzo/minio:microk8s-latest
  # ... remaining configuration ...
```

### Using Local MicroK8s Registry Image:
```yaml
apiVersion: minio.min.io/v2
kind: Tenant
metadata:
  name: mlflow-minio
  namespace: storage
spec:
  image: localhost:32000/minio:microk8s-latest
  # ... remaining configuration ...
```
