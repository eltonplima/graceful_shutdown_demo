#!/bin/bash
set -o errexit

declare -r CLUSTER_NAME="${1}"
declare -r reg_name='kind-registry'
declare -r reg_port='5001'

function create_k8s_cluster() {
  # create registry container unless it already exists
  if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
    echo "Creating local registry"
    docker run \
      -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
      registry:2
  fi

  # create a cluster with the local registry enabled in containerd
  cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
nodes:
  # the control plane node config
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 8080
        protocol: TCP
      - containerPort: 443
        hostPort: 8443
        protocol: TCP
  # the three workers
  - role: worker
  - role: worker
  - role: worker
EOF
}

# https://kind.sigs.k8s.io/docs/user/local-registry/
function configure_local_registry() {
  # 3. Add the registry config to the nodes
  #
  # This is necessary because localhost resolves to loopback addresses that are
  # network-namespace local.
  # In other words: localhost in the container is not localhost on the host.
  #
  # We want a consistent name that works from both ends, so we tell containerd to
  # alias localhost:${reg_port} to the registry container when pulling images
  REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
  for node in $(kind get nodes); do
    echo "Adding registry to the nodes..."
    docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
    cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"]
EOF
  done

  # 4. Connect the registry to the cluster network if not already connected
  # This allows kind to bootstrap the network but ensures they're on the same network
  if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
    docker network connect "kind" "${reg_name}"
  fi

  # 5. Document the local registry
  # https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

# allow pods to access host(allow access to local database)
# https://github.com/kubernetes-sigs/kind/issues/1200#issuecomment-1304855791
  cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Endpoints
metadata:
  name: dockerhost
subsets:
- addresses:
  - ip: 172.17.0.1 # this is the gateway IP in the "bridge" docker network
---
apiVersion: v1
kind: Service
metadata:
  name: dockerhost
spec:
  clusterIP: None
EOF
# Use this for MacOS
#  cat <<EOF | kubectl apply -f -
#---
#apiVersion: v1
#kind: Service
#metadata:
#  name: dockerhost
#spec:
#  type: ExternalName
#  externalName: host.docker.internal
# EOF
}

function adjust_file_permissions() {
  printf '=%.0s' {1..100} && echo ""
  echo "Adjusting .kube/config permissions"
  printf '=%.0s' {1..100} && echo ""
  chmod 600 ~/.kube/config
}

function install_helm() {
  printf '=%.0s' {1..100} && echo ""
  echo "Installing helm3"
  printf '=%.0s' {1..100} && echo ""
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
  helm repo add "kubernetes-dashboard" "https://kubernetes.github.io/dashboard/"
  helm repo add "stable" "https://charts.helm.sh/stable" --force-update
}

function install_k8s_dashboard() {
  printf '=%.0s' {1..100} && echo ""
  echo "Installing k8s dashboard"
  printf '=%.0s' {1..100} && echo ""
  #  helm install dashboard kubernetes-dashboard/kubernetes-dashboard -n kubernetes-dashboard --create-namespace
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
}

create_k8s_cluster
configure_local_registry
adjust_file_permissions
install_helm
install_k8s_dashboard

# install dashboard
#  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
# access dashboard
#  kube proxy
# access dashboard
#  http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login
echo "kubectl proxy"
