region       = "eu-west-1"
project_name = "cloudinsight"
environment  = "dev-staging"

# CSI Driver Configuration
csi_driver_version     = "1.4.6"
aws_provider_version   = "0.3.9"
sync_secret_enabled    = true
enable_secret_rotation = true
rotation_poll_interval = "2m"

# tags shared across resources
tags = {
  Owner = "team-alpha"
  Stage = "dev-staging"
}
