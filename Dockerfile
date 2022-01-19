FROM centos:centos8

WORKDIR /root

RUN yum makecache \
    && yum install -y openssh-server \
    && yum install -y openssh-clients \
    && yum install -y java-1.8.0-openjdk-devel \
    && yum install -y vim

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
ENV PATH=$PATH:${JAVA_HOME}/bin

RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -P '' && \
    ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -P '' && \
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -P '' && \
    ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

COPY ssh_config /etc/ssh/ssh_config.d/hadoop.conf
RUN chmod 600 /etc/ssh/ssh_config.d/hadoop.conf

ARG HADOOP_PACKAGE
ADD ${HADOOP_PACKAGE}.tar.gz /
RUN ln -s /${HADOOP_PACKAGE} /hadoop && mkdir /etc-hadoop

ENV HADOOP_HOME=/hadoop
ENV HADOOP_CONF_DIR=/etc-hadoop
ENV PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin

CMD ["sh", "-c", "/usr/sbin/sshd; bash"]
