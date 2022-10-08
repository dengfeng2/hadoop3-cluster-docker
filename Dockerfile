FROM ubuntu:20.04

WORKDIR /

COPY tsinghua.list /etc/apt/sources.list.d/
RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak
RUN apt update && \
    apt install -y openjdk-8-jdk && \
    apt install -y openssh-server && \
    apt install -y openssh-client

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$PATH:${JAVA_HOME}/bin

RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -y -P '' && \
    ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -y -P '' && \
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -y -P '' && \
    ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

COPY ssh_config /etc/ssh/ssh_config.d/hadoop.conf
RUN chmod 600 /etc/ssh/ssh_config.d/hadoop.conf
RUN mkdir -p /run/sshd

ARG HADOOP_PACKAGE
ADD ${HADOOP_PACKAGE}.tar.gz /
RUN ln -s /${HADOOP_PACKAGE} /hadoop

ENV HADOOP_HOME=/hadoop
ENV PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin

ARG HIVE_PACKAGE
ADD ${HIVE_PACKAGE}.tar.gz /
RUN ln -s /${HIVE_PACKAGE} /hive

ENV HIVE_HOME=/hive
ENV PATH=$PATH:${HIVE_HOME}/bin

COPY mysql-connector-java-8.0.28.jar ${HIVE_HOME}/lib/

CMD ["sh", "-c", "/usr/sbin/sshd; bash"]
