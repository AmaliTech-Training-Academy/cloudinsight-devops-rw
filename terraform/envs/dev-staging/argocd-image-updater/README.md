# ArgoCD Image Updater - Dev-Staging Environment

This directory contains the Terraform configuration for deploying ArgoCD Image Updater in the dev-staging environment.

## Overview

ArgoCD Image Updater automatically monitors ECR repositories and updates container images in ArgoCD applications when new versions are available.

## Configuration

### Remote State Integration

This configuration uses remote state data blocks to import information from:

- **EKS Module**: Cluster name, endpoint, and authentication
- **ECR Module**: Repository URLs and registry information
- **ArgoCD Module**: Namespace and service information

### IAM and Pod Identity

- Creates an IAM role with ECR read-only permissions
- Configures EKS Pod Identity association for secure AWS access
- No need for IRSA or manual credential management

### ECR Authentication

- Uses auth scripts for dynamic ECR token generation
- Automatically discovers ECR registry from repository URLs
- Supports all CloudInsight service repositories

## Deployment

1. **Initialize Terraform**:

   ```bash
   terraform init -backend-config=backend.hcl
   ```

2. **Plan the deployment**:

   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## ECR Registry Configuration

The Image Updater is configured to monitor all ECR repositories:

```yaml
registries:
  - name: ECR
    api_url: https://182399707265.dkr.ecr.eu-west-1.amazonaws.com
    prefix: 182399707265.dkr.ecr.eu-west-1.amazonaws.com
    ping: yes
    insecure: no
    credentials: ext:/scripts/auth.sh
    credsexpire: 10h
```

## Application Configuration

To enable image updates for an ArgoCD Application, add these annotations:

### Basic Configuration

```yaml
metadata:
  annotations:
    argocd-image-updater.argoproj.io/image-list: app-image=182399707265.dkr.ecr.eu-west-1.amazonaws.com/cloudinsight-user-service
    argocd-image-updater.argoproj.io/app-image.update-strategy: semver
```

### Advanced Configuration

```yaml
metadata:
  annotations:
    # Specify the image to monitor
    argocd-image-updater.argoproj.io/image-list: app-image=182399707265.dkr.ecr.eu-west-1.amazonaws.com/cloudinsight-user-service

    # Update strategy: semver, latest, digest, or name
    argocd-image-updater.argoproj.io/app-image.update-strategy: semver

    # Allow only semantic version tags
    argocd-image-updater.argoproj.io/app-image.allow-tags: regexp:^v[0-9]+\.[0-9]+\.[0-9]+$

    # Ignore specific tags
    argocd-image-updater.argoproj.io/app-image.ignore-tags: latest,dev

    # How to update: git or argocd (default: argocd)
    argocd-image-updater.argoproj.io/write-back-method: argocd
```

## Update Strategies

### Semantic Versioning (`semver`)

- Updates to newer semantic versions (e.g., v1.2.3 → v1.2.4)
- Respects version constraints (allow minor/patch updates)

### Latest (`latest`)

- Always updates to the most recently pushed image
- Useful for development environments

### Digest (`digest`)

- Updates based on image digests for immutable deployments
- Most secure option

### Name (`name`)

- Alphabetical sorting of tag names
- Custom tag naming schemes

## Monitoring

Image Updater provides:

- **Logs**: Check pod logs for update activities
- **Metrics**: Prometheus metrics on port 8080
- **Events**: Kubernetes events for update operations

## Verification

After deployment, verify Image Updater is working:

1. **Check pod status**:

   ```bash
   kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-image-updater
   ```

2. **View logs**:

   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater
   ```

3. **Check registry access**:
   ```bash
   kubectl exec -n argocd deployment/argocd-image-updater -- /scripts/auth.sh
   ```

## Troubleshooting

### Common Issues

1. **ECR Authentication Fails**:

   - Check IAM role permissions
   - Verify Pod Identity association
   - Ensure ECR repositories exist

2. **Images Not Updating**:

   - Verify application annotations
   - Check allowed/ignored tag patterns
   - Review update strategy configuration

3. **Registry Connectivity**:
   - Test ECR API access from cluster
   - Verify auth script execution
   - Check network policies

### Logs and Debugging

- **Image Updater logs**: `kubectl logs -n argocd deployment/argocd-image-updater`
- **ArgoCD Application events**: `kubectl describe application <app-name> -n argocd`
- **Pod Identity logs**: Check CloudTrail for assume role calls

## Dependencies

- EKS cluster must be deployed
- ArgoCD must be running
- ECR repositories must exist
- Pod Identity Agent must be enabled on EKS
