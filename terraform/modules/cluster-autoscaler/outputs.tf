output "cluster_autoscaler_role_arn" { value = aws_iam_role.cluster_autoscaler.arn }
output "cluster_autoscaler_service_account" { value = var.service_account_name }
