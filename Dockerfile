FROM docker:dind

RUN apk add curl bash coreutils && \
    wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.4.6 sh && \
    wget -O /usr/local/bin/kubectl https://dl.k8s.io/release/v1.24.4/bin/linux/amd64/kubectl && \
    chmod a+rx /usr/local/bin/kubectl && \
    wget -qO - https://get.helm.sh/helm-v3.10.2-linux-amd64.tar.gz | tar zxf - linux-amd64/helm --strip-components 1 -C /usr/local/bin && \
    curl -fsSl https://kubevela.io/script/install.sh | bash && \
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && \
    install -m 555 argocd-linux-amd64 /usr/local/bin/argocd && \
    rm argocd-linux-amd64


COPY setup.sh /
COPY charts /charts

EXPOSE 8088:8080

ENTRYPOINT ["docker-init","--",  "/setup.sh"]