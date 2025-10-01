project_name = "cloudinsight"
environment  = "dev-staging"
region       = "eu-west-1"

addon_version               = "v1.48.0-eksbuild.2"
namespace                   = "kube-system"
service_account_name        = "ebs-csi-controller-sa"
enable_encryption           = true
resolve_conflicts_on_update = "OVERWRITE"
resolve_conflicts_on_create = "NONE"

tags = {
  Owner = "team-alpha"
  Stage = "dev-staging"
}
