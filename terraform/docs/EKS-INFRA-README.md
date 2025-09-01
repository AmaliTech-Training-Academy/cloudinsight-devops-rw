<div align="center">

# CloudInsight Terraform & EKS Infrastructure

![CloudInsight](https://img.shields.io/badge/CloudInsight-Infrastructure-blue?style=for-the-badge)
![Terraform](https://img.shields.io/badge/Terraform-IaC-623CE4?style=for-the-badge&logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Cloud-orange?style=for-the-badge&logo=amazon-aws)
![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-326ce5?style=for-the-badge&logo=kubernetes)

<em>Modular, tagged, state-isolated AWS infrastructure delivering VPC networking and a production-ready EKS foundation.</em>

</div>

---

## 📚 Table of Contents
1. [Overview](#-overview)
2. [Repository Topology](#-repository-topology)
3. [Remote State Bootstrap](#-remote-state-bootstrap)
4. [Environment Strategy](#-environment-strategy)
5. [Networking Stack](#-networking-stack)
6. [Tagging Strategy](#-tagging-strategy)
7. [Cross-Stack Remote State](#-cross-stack-remote-state)
8. [EKS Module](#-eks-module)
9. [Node Group Parameters](#-node-group-parameters)
10. [Execution Flow](#-execution-flow)
11. [Post-Provision Access](#-post-provision-access)
12. [Design Decisions](#-design-decisions)
13. [Future Enhancements](#-future-enhancements)
14. [Operational Guidelines](#-operational-guidelines)
15. [Risks & Mitigations](#-risks--mitigations)
16. [tfvars Example](#-example-terraformtfvars)
17. [Quality Gates](#-quality-gates-summary)
18. [Quick Start](#-quick-start)
19. [Next Actions](#-next-actions)

---

## 🔎 Overview
End-to-end implementation of:
- Terraform remote state (S3 + DynamoDB locking)
- Modular networking (VPC, subnets, IGW, NAT, routes)
- Uniform tagging & CostCenter convention
- EKS cluster (v1.33) + parameterized managed node group

> Focus: A clear, evolvable baseline—secure & feature enhancements layered later (IRSA, addons, private endpoint, multi-AZ NAT, etc.).

## 🗂 Repository Topology
```
terraform/
  bootstrap/                  # Remote state backend (S3 + DynamoDB)
  modules/
    vpc/                      # VPC + subnets + discovery & LB role tags
    igw/                      # Internet Gateway
    nat-gateway/              # NAT Gateway + owned EIP
    eks/                      # EKS cluster + IAM + managed node group
  envs/
    dev-staging/
      networking/             # Composes VPC + IGW + NAT + routes
      eks/                    # EKS stack consuming networking outputs
```
State separation:
```
dev-staging/networking.tfstate
dev-staging/eks.tfstate
```

## 🔐 Remote State Bootstrap
Location: `terraform/bootstrap/`

| Component | Purpose |
|-----------|---------|
| S3 Bucket | Versioned & encrypted backend state storage |
| DynamoDB  | State locking & consistency guard |
| Tagging   | Standard keys for cost, ownership, automation |

CostCenter policy:
- Bootstrap stack → `<project>-bootstrap`
- Other stacks → `<project>-<environment>`

## 🧭 Environment Strategy
Single hybrid environment: `dev-staging` (accelerates early iteration). Naming leaves space for later promotion (split into `dev/` + `staging/`).

## 🏗 Networking Stack
Composition (`envs/dev-staging/networking`):
| Module / Block | Responsibility |
|----------------|----------------|
| `vpc` | VPC, public/private subnets, discovery & ELB tags |
| `igw` | Internet egress for public subnets |
| `nat-gateway` | Outbound access for private subnets (single NAT) |
| Inline routes | Public → IGW, Private → NAT (kept inline for clarity) |

Subnet discovery tags:
| Subnet Type | Tags |
|-------------|------|
| Public | `kubernetes.io/cluster/<name>=shared`, `kubernetes.io/role/elb=1` |
| Private | `kubernetes.io/cluster/<name>=shared`, `kubernetes.io/role/internal-elb=1` |

Outputs consumed downstream: `vpc_id`, `public_subnet_ids`, `private_subnet_ids`.

## 🏷 Tagging Strategy
| Tag | Meaning |
|-----|---------|
| Project | Logical workload grouping |
| Environment | Environment name (`dev-staging`) |
| Stack | Current layer (bootstrap / networking / eks) |
| ManagedBy | Always `terraform` |
| CostCenter | Chargeback keyword `<project>-<environment>` |
| Owner | Team ownership reference (e.g. `team-alpha`) |
| Stage | Redundant human-friendly env label |

## 🔁 Cross-Stack Remote State
`envs/dev-staging/eks/main.tf`:
```hcl
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "cloudinsight-tfstate"
    key    = "dev-staging/networking.tfstate"
    region = var.region
    encrypt = true
  }
}

locals {
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids
}
```
Deprecated `dynamodb_table` arg removed (lock already handled by writers).

## ☸ EKS Module
Contained in `modules/eks`:
| Resource | Notes |
|----------|-------|
| IAM Role (cluster) | Attached `AmazonEKSClusterPolicy` |
| IAM Role (nodes) | Worker, CNI, ECR ReadOnly policies |
| EKS Cluster | v1.33, public endpoint initially, API auth mode |
| Managed Node Group | Spot `t3.medium`, scaling & labels parameterized |

Outputs: `cluster_name`, `cluster_endpoint`, `cluster_version`, `cluster_arn`.

## ⚙ Node Group Parameters
| Variable | Purpose |
|----------|---------|
| `node_group_name` | Node group identifier |
| `node_instance_types` | Allowed EC2 types (list) |
| `node_capacity_type` | `SPOT` or `ON_DEMAND` |
| `node_min_size` / `node_desired_size` / `node_max_size` | Scaling boundaries |
| `node_max_unavailable` | Rolling upgrade disruption control |
| `node_labels` | Workload classification | 

Lifecycle: `desired_size` ignored → facilitates external autoscaler.

## 🏃 Execution Flow
```bash
# 1. Bootstrap (one-time)
cd terraform/bootstrap
terraform init && terraform apply -auto-approve

# 2. Networking stack
cd ../envs/dev-staging/networking
terraform init -backend-config=backend.hcl
terraform apply

# 3. EKS stack
cd ../eks
terraform init -backend-config=backend.hcl
terraform apply
```
Approx durations: Cluster ~7m, Node group ~5–6m.

Sample outputs:
```text
cluster_name     = cloudinsight-dev-staging
cluster_version  = 1.33
cluster_endpoint = https://<...>.eks.amazonaws.com
cluster_arn      = arn:aws:eks:eu-west-1:...:cluster/cloudinsight-dev-staging
```

## 🔑 Post-Provision Access
```bash
aws eks update-kubeconfig --name cloudinsight-dev-staging --region eu-west-1
kubectl get nodes
```

## 🧪 Design Decisions
| Choice | Rationale |
|--------|-----------|
| Split state per stack | Minimize blast radius & clarify ownership |
| Single `dev-staging` | Speed over early duplication |
| Single NAT | Cost-lean; can scale later to per-AZ |
| Inline route tables | Avoid premature abstraction |
| Public endpoint first | Simplifies bootstrap; harden later |
| Spot capacity | Immediate cost savings |
| Param node group | Reusable multi-pool future |
| Discovery tags | Enable LB + cluster provisioning |

## 🚀 Future Enhancements
1. OIDC provider + IRSA roles
2. Control plane logging (API, audit, authenticator)
3. Restrict public access (CIDRs) + enable private endpoint
4. Separate system / workload / on-demand node groups
5. Interface & gateway VPC endpoints (STS, ECR, S3, Logs)
6. Multi-AZ NAT expansion
7. Cluster Autoscaler + Metrics Server (Helm + IRSA)
8. AWS Load Balancer Controller
9. `aws_eks_addon` management (coredns, kube-proxy, vpc-cni) with versions
10. Policy-as-code (OPA / Conftest) in CI

## 🛠 Operational Guidelines
| Action | Guidance |
|--------|----------|
| Scale nodes | Adjust vars or rely on autoscaler (future) |
| Upgrade cluster | Bump version → apply → roll nodes |
| Add labels | Edit `node_labels` → apply |
| Switch capacity type | Node group recreation likely |
| Add subnets | Update VPC → apply networking before EKS |

## ⚠ Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Single NAT SPOF | Add per-AZ NAT gateways when HA needed |
| Public API exposed | Restrict CIDRs + enable private endpoint |
| Spot interruptions | Add on-demand system pool |
| Broad node IAM perms | Transition controllers to IRSA |
| Drift from manual tweaks | Enforce PR + CI plan gates |

## 🧾 Example `terraform.tfvars` (EKS)
```hcl
project_name        = "cloudinsight"
environment         = "dev-staging"
region              = "eu-west-1"
cluster_version     = "1.33"

node_group_name      = "general"
node_instance_types  = ["t3.medium"]
node_capacity_type   = "SPOT"
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
```

## ✅ Quality Gates Summary
| Gate | Result |
|------|--------|
| Format | Passed |
| Validate | Passed |
| Plan | Expected creates only |
| Apply | Successful |
| Deprecated params | Removed `dynamodb_table` from remote state data source |

## ⚡ Quick Start
1. Bootstrap remote state
2. Apply networking stack
3. Apply EKS stack
4. Generate kubeconfig & verify nodes
5. Layer operational addons (future)

## 🗺 Next Actions
- Implement IRSA + Autoscaler
- Enable control plane logs
- Introduce private API endpoint & CIDR restrictions
- Add additional node groups (system / specialized)
- Add CI policy & security scanning

---
<div align="center">
<sub>Maintained by the CloudInsight DevOps Team • Infrastructure as Code, done right.</sub>
</div>
