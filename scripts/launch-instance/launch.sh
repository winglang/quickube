#!/bin/sh
set -euo pipefail

wing compile -t tf-aws main.w

cd target/main.tfaws
terraform init
terraform apply -auto-approve

terraform output -raw pem > /tmp/quickube.pem
chmod 600 /tmp/quickube.pem

echo "pem file: /tmp/quickube.pem"
kubectl exec -it busybox -- /bin/sh

