project_name = "cloudinsight"
environment  = "dev-staging"
region       = "eu-west-1"
# Latest standard support version per docs (update as needed)
cluster_version = "1.33"

node_group_name      = "general"
node_instance_types  = ["t3.medium"]
node_capacity_type   = "ON_DEMAND"
node_min_size        = 0
node_desired_size    = 1
node_max_size        = 10
node_max_unavailable = 1
node_labels = {
  role     = "general"
  workload = "general"
}

tags = {
  Owner = "team-alpha"
  Stage = "dev-staging"
}
