#  vim: set sw=4

create-cluster:
  mkdir -p $(pwd)/.data
  k3d cluster create librepod \
    --verbose \
    --image rancher/k3s:v1.25.3-k3s1 \
    --api-port 127.0.0.1:6443 \
    --port 80:80@loadbalancer \
    --port 443:443@loadbalancer \
    --port 53:53@loadbalancer \
    --volume $(pwd)/.data:/var/lib/rancher/k3s/storage@all
  helm install forecastle ./charts/forecastle
  until [ -n "$(kubectl wait deployment -n kube-system traefik --for condition=Available=True)" ]; do sleep 5; done
  kubectl create -f ./charts/traefik/traefik-dashboard.yaml
  echo "✅ k3d cluster is ready to use!"

delete-cluster:
  k3d cluster delete librepod

install chart:
  helm dependencies update ./charts/{{chart}} \
  && helm install {{chart}} ./charts/{{chart}} \
    --set hostIP=$(kubectl get node -o=jsonpath='{.items[0].status.addresses[0].address}') \
    --set persistence.config.storageClass=local-path \
    --set persistence.uploads.storageClass=local-path \
    --set postgres.config.persistence.storageClass=local-path

install-dry-run chart:
  helm dependencies update ./charts/{{chart}} \
  && helm install {{chart}} ./charts/{{chart}} \
    --set hostIP=$(kubectl get node -o=jsonpath='{.items[0].status.addresses[0].address}') \
    --set persistence.config.storageClass=local-path \
    --set persistence.uploads.storageClass=local-path \
    --set postgres.persistence.config.storageClass=local-path \
    --debug \
    --dry-run

uninstall chart:
  helm uninstall {{chart}}
