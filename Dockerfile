FROM ubuntu:20.04
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update -y && apt-get -y install gnupg2 curl

# Install the NVIDIA CUDA drivers and Container Runtime
RUN apt-key del 7fa2af80
RUN curl -o cuda-keyring.deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb && dpkg -i cuda-keyring.deb
RUN apt-get update -y
RUN apt-get -y install cuda-drivers nvidia-container-runtime


# Import the binaries from the K3S version we just compiled
ADD k3s/build/out/data.tar /image

RUN cp -rR /image/bin/* /bin/

RUN mkdir -p /etc && \
    echo 'hosts: files dns' > /etc/nsswitch.conf
RUN chmod 1777 /tmp
# Provide custom containerd configuration to configure the nvidia-container-runtime
RUN mkdir -p /var/lib/rancher/k3s/agent/etc/containerd/
COPY config.toml.tmpl /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl
# Deploy the nvidia driver plugin on startup
RUN mkdir -p /var/lib/rancher/k3s/server/manifests
COPY gpu.yaml /var/lib/rancher/k3s/server/manifests/gpu.yaml
VOLUME /var/lib/kubelet
VOLUME /var/lib/rancher/k3s
VOLUME /var/lib/cni
VOLUME /var/log
ENV PATH="$PATH:/bin/aux"
ENTRYPOINT ["/bin/k3s"]
CMD ["agent"]
