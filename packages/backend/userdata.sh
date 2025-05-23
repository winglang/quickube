#!/bin/bash

# Display all commands being executed
set -x

if [ "$(uname -m)" != "aarch64" ]; then
  echo "Unsupported architecture $(uname -m). This script is intended to run on an arm machine."
  exit 1
fi

echo "Installing kind..."
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
echo "-----------------------------------------------------------------------------------------------------"

sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
newgrp docker

kubectl_version=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
echo "Installing kubectl $kubectl_version..."
curl -LO "https://dl.k8s.io/release/$kubectl_version/bin/linux/arm64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# ----------------------------

# trying to delete any existing cluster
kind delete cluster || true

# 1. Create registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'

docker rm -f "$reg_name" || true
docker run -d --restart=always -p "$reg_port:5000" --network bridge --name "$reg_name" registry:2

# 2. Create kind cluster with containerd registry config dir enabled
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

networking:
  apiServerAddress: "0.0.0.0"
  apiServerPort: 7443

nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP

containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
EOF

# 3. Add the registry config to the nodes
REGISTRY_DIR="/etc/containerd/certs.d/kind-registry:$reg_port"
for node in $(kind get nodes); do
  docker exec "$node" mkdir -p "$REGISTRY_DIR"
  cat <<EOF | docker exec -i "$node" cp /dev/stdin "$REGISTRY_DIR/hosts.toml"
[host."http://$reg_name:5000"]
EOF
done

# 4. Connect the registry to the cluster network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "$reg_name")" = 'null' ]; then
  docker network connect "kind" "$reg_name"
fi

# 5. Document the local registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "kind-registry:$reg_port"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

# Deploy nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# OK, we have a cluster, let's put it in the pool bucket

kubeconfig_file="./kubeconfig.yaml"
kind export kubeconfig --kubeconfig $kubeconfig_file
kubeconfig="$(cat $kubeconfig_file | base64 -w0)"

metadata_service="http://169.254.169.254/latest/meta-data"
instance_id="$(curl -s $metadata_service/instance-id)"
region="$(curl -s $metadata_service/placement/region)"

cat <<EOF > cluster.json
{
  "provider": "aws",
  "kubeconfig": "$kubeconfig",
  "instanceId": "$instance_id",
  "publicIp": "$(curl -s $metadata_service/public-ipv4)",
  "publicDns": "$(curl -s $metadata_service/public-hostname)",
  "region": "$region",
  "size": "${tf_qkube_size}",
  "instanceType": "$(curl -s $metadata_service/instance-type)"
}
EOF

aws s3 cp cluster.json "s3://${tf_qkube_pool_bucket}/aws/$region/${tf_qkube_size}/$instance_id.json"
