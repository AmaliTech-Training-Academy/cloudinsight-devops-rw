# ingress-nginx Module

Deploys an ingress-nginx controller (external NLB) customized for AWS EKS.

## Inputs

- cluster_name (string)
- region (string)
- namespace (string)
- release_name (string) : also used as ingressClassResource name
- chart_version (string, optional)
- repository (string)
- load_balancer_scheme (internet-facing | internal)
- nlb_target_type (ip | instance)
- service_annotations_extra (map)

## Outputs

- release_name
- namespace
- chart_version

## Notes

Uses AWS NLB (type external) with IP targets by default.
