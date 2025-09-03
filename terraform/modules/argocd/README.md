# ArgoCD Terraform Module

This module deploys ArgoCD (GitOps continuous delivery tool) on an EKS cluster using Helm.

## Features

- **Clean Helm Deployment**: Simple Helm-based ArgoCD installation
- **Configurable**: Customizable via Helm values
- **Secure**: Runs in dedicated namespace with proper RBAC
- **Notifications**: Built-in notification controller for deployment alerts
- **ApplicationSet**: Support for application templating and automation

## Architecture

```
ArgoCD Components:
├── Server (UI & API)
├── Repository Server (Git operations)
├── Application Controller (Kubernetes sync)
├── Notifications Controller (Alerts & webhooks)
└── ApplicationSet Controller (App templating)
```

## Usage

```hcl
module "argocd" {
  source = "../../modules/argocd"

  cluster_name = var.cluster_name
  region       = var.region

  # ArgoCD Configuration
  namespace     = "argocd"
  release_name  = "argocd"
  chart_version = "8.3.3"

  # Security Configuration
  server_insecure = true  # For TLS termination at ingress

  # Pod Identity Integration
  create_pod_identity_association = true

  # Custom values (optional)
  custom_values = {
    server = {
      replicas = 2  # Override default replica count
    }
  }

  tags = var.tags
}
```

## Pod Identity Integration

The module automatically:

1. Creates an IAM role with ECR and Secrets Manager permissions
2. Sets up EKS Pod Identity associations for ArgoCD components:
   - ArgoCD Server
   - Repository Server
   - Application Controller
3. Configures service accounts with proper annotations

## Configuration

### Default Configuration

The module applies the following default configuration:

```yaml
configs:
  params:
    server.insecure: true # For ingress TLS termination

server:
  replicas: 1
  service:
    type: ClusterIP
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: <IAM_ROLE_ARN>

repoServer:
  replicas: 1
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: <IAM_ROLE_ARN>

controller:
  replicas: 1
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: <IAM_ROLE_ARN>

redis:
  enabled: true

applicationSet:
  enabled: true
  replicas: 1

notifications:
  enabled: true # Enabled for deployment notifications
  replicas: 1
```

### Custom Values

You can override any default configuration using the `custom_values` variable:

```hcl
custom_values = {
  server = {
    replicas = 2
    resources = {
      requests = {
        memory = "256Mi"
        cpu    = "100m"
      }
      limits = {
        memory = "512Mi"
        cpu    = "200m"
      }
    }
  }

  notifications = {
    enabled = true
  }

  configs = {
    cm = {
      "application.instanceLabelKey" = "argocd.argoproj.io/instance"
    }
  }
}
```

## Security Features

### IAM Permissions

The automatically created IAM role includes:

- **ECR Access**: Pull container images from ECR repositories
- **Secrets Manager**: Access secrets for application configuration

### Pod Identity

Uses EKS Pod Identity (not IRSA) for:

- Better security isolation
- Automatic credential rotation
- Integration with existing pod-identity-agent

## Access

### Admin Password

The ArgoCD admin password is automatically generated and stored in a Kubernetes secret:

```bash
# Get the admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Port Forwarding (for testing)

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Then access ArgoCD at `http://localhost:8080`

## Ingress Integration

The module configures ArgoCD in insecure mode to work with ingress TLS termination:

```yaml
# Example ingress configuration
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
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

## Outputs

- `release_name`: Helm release name
- `namespace`: ArgoCD namespace
- `chart_version`: Deployed chart version
- `server_service_name`: ArgoCD server service name
- `server_service_port`: ArgoCD server service port
- `iam_role_arn`: IAM role ARN for Pod Identity
- `pod_identity_associations`: Pod Identity association IDs

## Prerequisites

- EKS cluster with Pod Identity Agent addon enabled
- Helm provider configured with cluster access
- AWS provider with appropriate permissions

## Integration with Other Modules

This module integrates seamlessly with:

- **EKS Module**: Uses cluster name and endpoint
- **Pod Identity Agent**: Leverages existing pod identity infrastructure
- **Ingress NGINX**: Works with ingress for external access
- **Cert Manager**: Compatible with TLS certificate management

## Version Compatibility

- **ArgoCD**: v3.1.1 (via Helm chart 8.3.3)
- **Kubernetes**: 1.28+
- **EKS**: 1.28+
- **Terraform**: 1.5+
