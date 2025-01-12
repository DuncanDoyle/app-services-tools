FROM registry.access.redhat.com/ubi8/ubi as builder

RUN yum install git -y
RUN yum install gcc -y
RUN yum install gcc-c++ -y 
RUN yum install python3 -y 
RUN yum install cyrus-sasl-devel -y
RUN yum install make -y
RUN yum install cmake -y
RUN yum install diffutils -y
RUN yum install curl-devel -y

#Using version 1.6 of Kafkacat. Build from master has an issue where it doesn't accept input in producer mode until you hit Ctrl-D.
RUN git clone --depth 1 --branch 1.6.0 https://github.com/edenhill/kafkacat /opt/kafkacat    
RUN pushd /opt/kafkacat && ./bootstrap.sh

# ---------------------------------------------------------------------------- #

FROM registry.access.redhat.com/ubi8/ubi-minimal
LABEL maintainer="ddoyle@redhat.com"

ENV RHOAS_CLI_PATH="/usr/local/bin/rhoas"
ENV OC_CLI_PATH="/usr/local/bin/oc"

# Install required packages
RUN microdnf install shadow-utils
RUN microdnf install yum

# Create the RHOAS user
RUN useradd -ms /bin/bash rhoas
USER rhoas

COPY contrib/rhoas /usr/local/bin/rhoas
COPY contrib/oc /usr/local/bin/oc
COPY contrib/odo /usr/local/bin/odo

USER root
RUN mkdir -p /.config/rhoas && chmod 777 -R /.config/rhoas && echo "{}" > /.config/rhoas/config.json && chmod 777 /.config/rhoas/config.json
RUN mkdir /.kube && chmod 777 /.kube
USER rhoas

COPY --from=builder --chown=root:root /opt/kafkacat/kafkacat /usr/local/bin/kafkacat

ENTRYPOINT ["tail", "-f", "/dev/null"]
