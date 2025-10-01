# EBS CSI Driver Module

This Terraform module deploys the AWS EBS CSI driver addon to an EKS cluster using Pod Identity for authentication.

## Features

- Deploys AWS EBS CSI driver as an EKS addon
- Creates IAM role with necessary permissions
- Configures Pod Identity association for authentication
- Optional support for EBS encryption
- Configurable addon version and conflict resolution strategies

## Usage

```hcl
module "ebs_csi_driver" {
  source       = "../../../modules/ebs-csi-driver"
  cluster_name = "my-eks-cluster"
  addon_version = "v1.48.0-eksbuild.2"
  enable_encryption = true
  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## Requirements

- EKS cluster with Pod Identity agent enabled
- Terraform >= 1.0
- AWS provider >= 5.0

## Inputs

| Name                        | Description                                  | Type          | Default                   | Required |
| --------------------------- | -------------------------------------------- | ------------- | ------------------------- | :------: |
| cluster_name                | Name of the EKS cluster                      | `string`      | n/a                       |   yes    |
| addon_version               | Version of the EBS CSI driver addon          | `string`      | `"v1.48.0-eksbuild.2"`    |    no    |
| namespace                   | Kubernetes namespace for the service account | `string`      | `"kube-system"`           |    no    |
| service_account_name        | Name of the Kubernetes service account       | `string`      | `"ebs-csi-controller-sa"` |    no    |
| enable_encryption           | Enable EBS encryption support                | `bool`        | `true`                    |    no    |
| resolve_conflicts_on_update | Conflict resolution strategy on update       | `string`      | `"OVERWRITE"`             |    no    |
| resolve_conflicts_on_create | Conflict resolution strategy on create       | `string`      | `"NONE"`                  |    no    |
| tags                        | Tags to apply to resources                   | `map(string)` | `{}`                      |    no    |

## Outputs

| Name                        | Description                                 |
| --------------------------- | ------------------------------------------- |
| ebs_csi_driver_role_arn     | ARN of the IAM role for the EBS CSI driver  |
| ebs_csi_driver_role_name    | Name of the IAM role for the EBS CSI driver |
| addon_name                  | Name of the EBS CSI driver addon            |
| addon_version               | Version of the EBS CSI driver addon         |
| pod_identity_association_id | ID of the pod identity association          |
| service_account_name        | Name of the service account                 |
| namespace                   | Namespace where the driver is deployed      |

## Notes

- This module depends on the Pod Identity agent being deployed in the cluster
- The EBS CSI driver is deployed in the `kube-system` namespace by default
- Encryption support is enabled by default and grants necessary KMS permissions
