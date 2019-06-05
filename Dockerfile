FROM microsoft/azure-cli:2.0.32

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \ 
      chmod +x ./kubectl && \
      mv ./kubectl /usr/local/bin/kubectl && \
      curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh && \
      chmod 700 get_helm.sh && \
      ./get_helm.sh

ADD . /app
RUN find /app -type f -name '*.sh' -exec chmod +x {} \;

WORKDIR /app

CMD ["/app/deploy.sh"]
