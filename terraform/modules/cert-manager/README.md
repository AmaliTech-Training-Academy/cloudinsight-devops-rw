# cert-manager Terraform Module

Deploys cert-manager via the official Jetstack Helm chart.

## Inputs

- cluster_name (string, required): Cluster identifier (not currently used but reserved for future labels).
- region (string, required)
- namespace (string, default cert-manager)
- release_name (string, default cert-manager)
- chart_version (string, default v1.14.5)
- repository (string, default https://charts.jetstack.io)
- install_crds (bool, default true) - sets installCRDs
- extra_set (map(string)) - additional Helm set values

## Outputs

- release_name
- namespace
- chart_version

## Example

```hcl
module "cert_manager" {
  source        = "../../../modules/cert-manager"
  cluster_name  = data.terraform_remote_state.eks.outputs.cluster_name
  region        = var.region
  namespace     = "cert-manager"
  release_name  = "cert-manager"
  chart_version = "v1.14.5"
  extra_set     = { "prometheus.enabled" = "true" }
}
```
