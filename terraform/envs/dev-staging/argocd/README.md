# ArgoCD Infrastructure - Development/Staging Environment

This directory contains the Terraform configuration for deploying ArgoCD (Argo Continuous Delivery) in the development/staging environment.

## Overview

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. This configuration deploys ArgoCD with:

- **Helm Chart Version**: 8.3.3 (ArgoCD v3.1.1)
- **EKS Pod Identity Integration**: Secure AWS access without IRSA
- **ECR Access**: Pull container images from CloudInsight ECR repositories
- **Insecure Mode**: For TLS termination at ingress level
- **Development Optimized**: Resource limits suitable for dev/staging workloads

## Quick Start

1. **Initialize Terraform:**

   ```bash
   terraform init -backend-config=backend.hcl
   ```

2. **Plan the deployment:**

   ```bash
   terraform plan
   ```

3. **Apply the configuration:**
   ```bash
   terraform apply -auto-approve
   ```

## Features

### 🔐 Security Features

- **EKS Pod Identity**: Integrated with existing pod-identity-agent
- **IAM Roles**: Automatic creation with ECR and Secrets Manager access
- **Namespace Isolation**: Dedicated namespace with proper labeling

### ⚙️ Configuration

- **Server Insecure Mode**: `server.insecure: true` for ingress TLS termination
- **Resource Optimization**: Development-appropriate resource requests/limits
- **Single Replicas**: Cost-effective for dev/staging environment

### 🎯 Components Deployed

- **ArgoCD Server**: Web UI and API server
- **Repository Server**: Git repository management
- **Application Controller**: Application lifecycle management
- **ApplicationSet Controller**: Multi-cluster application management
- **Redis**: In-memory database for caching

## Access ArgoCD

### Get Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Port Forward (for development)

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Then access ArgoCD at: `http://localhost:8080`

- **Username**: `admin`
- **Password**: (from the secret above)

### Production Access (via Ingress)

For production access, configure an ingress resource:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  tls:
    - hosts:
        - argocd.yourdomain.com
      secretName: argocd-server-tls
  rules:
    - host: argocd.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80
```

## GitOps Workflow

### 1. Connect Git Repository

```bash
# Add a Git repository to ArgoCD
argocd repo add https://github.com/your-org/your-k8s-manifests.git \
  --username your-username \
  --password your-token
```

### 2. Create Applications

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cloudinsight-frontend
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/cloudinsight-manifests.git
    targetRevision: main
    path: frontend
  destination:
    server: https://kubernetes.default.svc
    namespace: cloudinsight-frontend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Integration

### With ECR Repositories

The ArgoCD Pod Identity role includes ECR permissions to pull images from:

- `cloudinsight-frontend`
- `cloudinsight-api-gateway`
- `cloudinsight-*-service` (all backend services)

### With Existing Infrastructure

- **EKS Cluster**: Uses remote state from `eks.tfstate`
- **Pod Identity Agent**: Leverages existing pod identity infrastructure
- **Networking**: Works with VPC and security groups from networking stack

## Resource Usage

### Development Environment Resources:

- **ArgoCD Server**: 128Mi-256Mi memory, 50m-100m CPU
- **Controller**: 256Mi-512Mi memory, 100m-200m CPU
- **Repo Server**: 128Mi-256Mi memory, 50m-100m CPU
- **Redis**: 64Mi-128Mi memory, 25m-50m CPU

## Monitoring

### Health Checks

```bash
# Check ArgoCD health
kubectl get pods -n argocd

# Check application status
kubectl get applications -n argocd

# View ArgoCD logs
kubectl logs -n argocd deployment/argocd-server
```

### Common Commands

```bash
# List applications
argocd app list

# Sync application
argocd app sync myapp

# Get application details
argocd app get myapp

# Set application parameters
argocd app set myapp --parameter image.tag=v1.2.3
```

## Troubleshooting

### Pod Identity Issues

```bash
# Check pod identity associations
aws eks describe-pod-identity-association --cluster-name cloudinsight-dev-staging

# Verify service account annotations
kubectl get sa -n argocd -o yaml
```

### Application Sync Issues

```bash
# Check application events
kubectl describe application myapp -n argocd

# View sync status
argocd app get myapp --show-operation
```

## Upgrade

To upgrade ArgoCD, update the `chart_version` in `terraform.tfvars` and run:

```bash
terraform plan
terraform apply
```

## Security Considerations

- ArgoCD runs in insecure mode for ingress TLS termination
- Use strong admin passwords and rotate regularly
- Implement RBAC for multi-user access
- Consider enabling SSO for production environments
- Monitor application deployments and changes

## Next Steps

1. **Configure Ingress**: Set up external access with TLS
2. **Add Git Repositories**: Connect your application repositories
3. **Create Applications**: Deploy your microservices
4. **Set up RBAC**: Configure user access and permissions
5. **Enable Notifications**: Set up Slack/email notifications for deployments
