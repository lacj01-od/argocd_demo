#!/bin/bash


declare -A waitlist
waitlist['deployments.apps/argo-cd-argocd-server']='argo-cd'
waitlist['deployments.apps/argo-cd-argocd-redis']='argo-cd'
waitlist['deployments.apps/argo-cd-argocd-applicationset-controller']='argo-cd'
waitlist['deployments.apps/argo-cd-argocd-notifications-controller']='argo-cd'
waitlist['deployments.apps/argo-cd-argocd-repo-server']='argo-cd'

function waitforit() {
    local namespace
    local target
    local rtry
    namespace="$1"
    target="$2"
    rtry=60

    echo "Waiting on ${namespace} ${target}"
    while [[ ${rtry} -ne 0 ]] && ! kubectl -n "${namespace}" wait --for condition=Available=True --timeout=600s "${target}"; do
      echo "Waiting on ${namespace} ${target}"
      rtry=$(( rtry - 1 ))
      sleep 10
    done

    [[ ${rtry} -eq 0 ]] && exit 255
}

set --
dockerd-entrypoint.sh &
DOCKERD=$!

RTRY=10
while [[ ${RTRY} -ne 0 ]] &&  ! docker info  > /dev/null 2>&1 ; do
  echo Waiting on docker
  RTRY=$(( RTRY - 1 ))
  sleep 1
done

[[ ${RTRY} -eq 0 ]] && exit 255

if [ ! -e /root/running ] ; then
  k3d cluster create bootstrap --api-port 0.0.0.0:12376  --registry-create bootstrap:0.0.0.0:5577
  cat ~/.kube/config
  helm repo add kubevela https://kubevelacharts.oss-accelerate.aliyuncs.com/core
  helm repo update
  echo "Waiting on metric server to start..."
  waitforit kube-system deployment/metrics-server
  helm repo add argo https://argoproj.github.io/argo-helm
  helm dependency build /charts/argo-cd
  helm upgrade argo-cd ./charts/argo-cd --install --namespace argo-cd --create-namespace

  for k in "${!waitlist[@]}"; do
    waitforit "${waitlist[$k]}" "$k"
  done
  helm dependency build /charts/vela
  helm install --create-namespace -n vela-system kubevela /charts/vela
  waitforit vela-system deployments.apps/kubevela-cluster-gateway
  waitforit vela-system deployments.apps/kubevela-vela-core
  # Switch resource tracking method
  # this is to deal with vela generating resources
  kubectl patch configmap/argocd-cm \
    -n argo-cd \
    --type merge \
    -p '{"data":{"application.resourceTrackingMethod":"annotation"}}'

  echo RUNNING > /root/running
else
  for k in "${!waitlist[@]}"; do
    waitforit "${waitlist[$k]}" "$k"
  done
  waitforit vela-system deployments.apps/kubevela-cluster-gateway
  waitforit vela-system deployments.apps/kubevela-vela-core
fi

kubectl -n argo-cd port-forward --address='0.0.0.0' svc/argo-cd-argocd-server 8080:443 &
kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d


wait $DOCKERD

# az ad sp create-for-rbac --scopes "/subscriptions/f131e25d-895b-488e-8b0f-9445d5c63146" --role Owner > "creds.json"
# docker volume create myconfig
# docker create --name initcontainer -v myconfig:/data alpine:latest
# docker cp creds.json initcontainer:/data/
# docker rm initcontainer
# create kubenet --subnet  172.18.0.0/16 --gateway 172.18.0.1
# docker run -it --rm --privileged  --ip 172.18.0.10 --network kubenet --name mk8s -v myconfig:/data -p 8088:8080 -p 12376:12376 -p 5577:5577 --ulimit nofile=262144:262144 mytest:latest

