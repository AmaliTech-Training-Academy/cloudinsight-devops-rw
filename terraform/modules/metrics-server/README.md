# Metrics Server Module

Deploys the Kubernetes Metrics Server via the official Helm chart.

## Features

- Uses official repository: https://kubernetes-sigs.github.io/metrics-server/
- Pinned chart version (3.13.0 / appVersion 0.8.0)
- Opinionated, production‑leaning defaults (secure port 10250, 15s metric resolution, kubelet preferred address ordering, node status port usage)
- Minimal inputs – ships with a bundled values file baked into the module for deterministic installs

## Bundled values

The module always loads the file:

```
${path.module}/values/metrics-server-values.yaml
```

If you need to customize arguments, edit that file (or fork / wrap the module). There is intentionally no variable to point to a different values file to keep usage consistent across environments.

## Inputs

| Name          | Type   | Default        | Description               |
| ------------- | ------ | -------------- | ------------------------- |
| name          | string | metrics-server | Helm release name         |
| namespace     | string | kube-system    | Namespace to install into |
| repository    | string | repo URL       | Helm repository URL       |
| chart_version | string | 3.13.0         | Chart version             |

## Outputs

| Name          | Description           |
| ------------- | --------------------- |
| release_name  | Helm release name     |
| namespace     | Namespace deployed to |
| chart_version | Chart version applied |

## Environment integration

Providers (`helm`, `kubernetes`, `aws`) are defined outside the module in each environment. The environment should supply cluster connection details (endpoint, token, CA) – for example via remote state outputs from the EKS stack.

## Updating chart / values

1. Update `chart_version` input (and optionally arguments in the YAML).
2. Run `terraform plan` in the metrics-server environment.
3. Apply after review.

## Security note

The metrics-server runs in the `kube-system` namespace with default RBAC from the upstream chart. Review RBAC before broad production rollout if you customize the chart.
