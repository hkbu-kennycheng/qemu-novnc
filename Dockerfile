FROM alpine

RUN apk update && apk add --no-cache curl wget unzip git bash python3 py3-pip py3-numpy \
    qemu-img qemu-system-x86_64 ovmf qemu-modules swtpm

RUN mkdir /images && cd /images && \
    wget https://github.com/kholia/OSX-KVM/raw/master/OVMF_CODE.fd && \
    wget https://github.com/kholia/OSX-KVM/raw/master/OVMF_VARS.fd

RUN qemu-img create -f qcow2 /images/disk1.qcow2 100G

RUN git clone --depth=1 --recursive https://github.com/novnc/noVNC /novnc
RUN echo '<!doctype html><html><head><title>novnc</title><meta http-equiv="refresh" content="0; URL=vnc.html" /></head>' > /novnc/index.html

EXPOSE 6080
EXPOSE 2375

ADD run.sh /run.sh

CMD ["/run.sh"]
