# EKS Pod Identity Agent Addon Module

Installs the AWS managed `eks-pod-identity-agent` addon on an existing EKS cluster.

## Why a module

Provides a reusable, version‑pinned wrapper so every environment enables Pod Identity uniformly and reproducibly.

## Features

- Pins addon version (default `v1.3.8-eksbuild.2`).
- Exposes conflict resolution strategy variables.
- Simple outputs (name, version, status) for health checks / cross-stack logic.
- Tag passthrough for cost / ownership metadata.

## Inputs

| Name                        | Type        | Default           | Description                  |
| --------------------------- | ----------- | ----------------- | ---------------------------- |
| cluster_name                | string      | n/a               | Target EKS cluster name      |
| addon_version               | string      | v1.3.8-eksbuild.2 | Addon version to install     |
| resolve_conflicts_on_update | string      | OVERWRITE         | Behavior on update conflicts |
| resolve_conflicts_on_create | string      | NONE              | Behavior on create conflicts |
| tags                        | map(string) | {}                | Tags to apply                |

## Outputs

| Name          | Description                           |
| ------------- | ------------------------------------- |
| addon_name    | Addon name (`eks-pod-identity-agent`) |
| addon_version | Installed version                     |
| addon_status  | Current status reported by AWS        |

## Example

```
module "pod_identity_agent" {
  source        = "../../../modules/eks-pod-identity-agent"
  cluster_name  = data.terraform_remote_state.eks.outputs.cluster_name
  addon_version = "v1.3.8-eksbuild.2"
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "addons"
  }
}
```

## Next steps

After enabling the agent, you can create `aws_eks_pod_identity_association` resources (e.g. for Cluster Autoscaler) to map service accounts to IAM roles.
