#!/usr/bin/env bash
# Manage full environment stack (create/destroy) in the current Terraform environment directory.
# Usage (run from inside an env directory, e.g. terraform/envs/dev-staging):
#   ../run-stack.sh --create
#   ../run-stack.sh --destroy
# You can also pass --init-only to just init all modules.
# Order (create): networking -> eks -> metrics-server -> eks-pod-identity-agent -> cluster-autoscaler -> aws-load-balancer-controller -> ingress-nginx -> cert-manager
# Destroy reverses the order.

set -euo pipefail

APPLY_ORDER=(
  networking
  eks
  metrics-server
  pod-identity-agent 
  cluster-autoscaler
  aws-load-balancer-controller
  ingress-nginx
  cert-manager
)

COLOR() { # usage: COLOR red "text"
  local c="$1"; shift || true
  local code
  case "$c" in
    red) code='\033[0;31m';;
    green) code='\033[0;32m';;
    yellow) code='\033[0;33m';;
    blue) code='\033[0;34m';;
    magenta) code='\033[0;35m';;
    cyan) code='\033[0;36m';;
    *) code='';;
  esac
  printf "%b%s%b" "${code}" "$*" "\033[0m"
}

log() { COLOR cyan "[stack]"; echo " $*"; }
warn() { COLOR yellow "[warn]"; echo " $*"; }
err() { COLOR red "[err ]"; echo " $*" >&2; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [--create|--destroy|--init-only] [--skip-missing] [--plan]

Actions (choose one):
  --create       terraform apply -auto-approve on all modules in order
  --destroy      terraform destroy -auto-approve on all modules in reverse order
  --init-only    only run terraform init (no apply/destroy)

Optional flags:
  --skip-missing skip missing module directories instead of failing
  --plan         run plan (read-only) instead of apply/destroy (ignored with --init-only)

Run this script from within an environment directory containing the module subfolders listed in APPLY_ORDER.
EOF
}

ACTION=""
SKIP_MISSING=false
DO_PLAN=false

for arg in "$@"; do
  case "$arg" in
    --create|--destroy|--init-only) ACTION="${arg#--}" ;;
    --skip-missing) SKIP_MISSING=true ;;
    --plan) DO_PLAN=true ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown argument: $arg"; usage; exit 1 ;;
  esac
done

if [[ -z "$ACTION" ]]; then
  err "No action specified"
  usage
  exit 1
fi

# Detect we are in an env dir by presence of at least one of the expected directories
FOUND=false
for d in "${APPLY_ORDER[@]}"; do
  if [[ -d "$d" ]]; then FOUND=true; break; fi
done
if ! $FOUND; then
  err "No expected module subdirectories found here; run from inside an environment directory."
  exit 1
fi

run_for_dir() {
  local dir="$1"; shift
  local tf_cmds=("$@")
  if [[ ! -d "$dir" ]]; then
    if $SKIP_MISSING; then
      warn "Skipping missing directory: $dir"
      return 0
    else
      err "Directory missing: $dir"
      exit 1
    fi
  fi
  pushd "$dir" >/dev/null
  if [[ -f backend.hcl ]]; then
    log "Init $(pwd)"
    terraform init -backend-config=backend.hcl -input=false -upgrade >/dev/null
  else
    log "Init (no backend.hcl) $(pwd)"
    terraform init -input=false -upgrade >/dev/null
  fi
  for cmd in "${tf_cmds[@]}"; do
    log "Terraform $cmd in $dir"
    if [[ "$cmd" == plan ]]; then
      terraform plan -no-color || return 1
    else
      terraform "$cmd" -auto-approve -input=false -no-color || return 1
    fi
  done
  popd >/dev/null
}

if [[ "$ACTION" == "init-only" ]]; then
  for d in "${APPLY_ORDER[@]}"; do
    run_for_dir "$d" init-only
  done
  log "Init-only completed"
  exit 0
fi

if [[ "$ACTION" == "create" ]]; then
  for d in "${APPLY_ORDER[@]}"; do
    if $DO_PLAN; then
      run_for_dir "$d" plan
    else
      run_for_dir "$d" apply
    fi
  done
  log "Create sequence finished"
  exit 0
fi

if [[ "$ACTION" == "destroy" ]]; then
  for (( idx=${#APPLY_ORDER[@]}-1 ; idx>=0 ; idx-- )); do
    d="${APPLY_ORDER[$idx]}"
    if $DO_PLAN; then
      run_for_dir "$d" plan
    else
      run_for_dir "$d" destroy
    fi
  done
  log "Destroy sequence finished"
  exit 0
fi

err "Unhandled action: $ACTION"
exit 1
