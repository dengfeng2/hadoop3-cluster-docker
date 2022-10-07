# hadoop3-cluster-docker


利用docker容器模拟hadoop集群的部署。

使用步骤：

1. 在项目根目录下放置hadoop3的部署包，一般情况下，官方包名为 hadoop-x.x.x.tar.gz, 其中xxx为版本号
2. 使用脚本`build.sh`构建镜像，脚本内部的命令`docker build -t hadoop-base --build-arg HADOOP_PACKAGE=hadoop-x.x.x .` 构建一个名为hadoop3的镜像，此处记得将版本号换成自己所用的hadoop版本号；
3. 修改etc-hadoop文件夹下的配置文件;
4. 使用`docker-compose up` 启动hadoop容器集群；

## 当前配置
```Bash
# ----- core-site.xml -----
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://hadoop01:9820</value>
    </property>
    <property>
        <name>hadoop.http.staticuser.user</name>
        <value>root</value>
    </property>
</configuration>

# ----- hdfs-site.xml -----
<configuration>
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>hdfs://hadoop02:9868</value>
    </property>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
    <property>
        <name>dfs.namenode.http-address</name>
        <value>hadoop01:9870</value>
    </property>
</configuration>

# ----- yarn-site.xml -----
<configuration>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>hadoop01</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.scheduler.minimum-allocation-mb</name>
        <value>512</value>
    </property>
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>2048</value>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-pmem-ratio</name>
        <value>4</value>
    </property>
</configuration>

# ----- mapred-site.xml -----
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>
    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>
    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>
</configuration>
# ----- hadoop-env.sh -----
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

export HDFS_NAMENODE_USER=root
export HDFS_DATANODE_USER=root
export HDFS_SECONDARYNAMENODE_USER=root
export YARN_RESOURCEMANAGER_USER=root
export YARN_NODEMANAGER_USER=root


# ----- workers ----
hadoop01
hadoop02
hadoop03


```

关于hadoop容器集群的规划在文件docker-compose.yml中:
- hadoop01: NameNode, DataNode, NodeManager, ResourceManager, JobHistoryServer
- hadoop02: SecondaryNameNode, DataNode, NodeManager
- hadoop03: DataNode, NodeManager

按照如上规划，接下来应该：
1. 在hadoop01上执行`hdfs namenode -format`；
2. 在hadoop01的${HADOOP_HOME}/sbin/目录下，执行`./start-dfs.sh`；
3. 在hadoop01的${HADOOP_HOME}/sbin/目录下，执行`./start-yarn.sh`；
4. 在hadoop01的${HADOOP_HOME}/sbin/目录下，执行`mapred --daemon start historyserver`；

接下来开始愉快的hadoop之旅吧！😏

----- 集群启动停止 -----
```
start-dfs.sh     # 启动HDFS所有进程(NameNode, SecondaryNameNode, DataNode)
stop-dfs.sh      # 停止HDFS所有进程(NameNode, SecondaryNameNode, DataNode)

hdfs --daemon start namenode           # 只启动NameNode
hdfs --daemon start secondarynamenode  # 只启动SecondaryNameNode
hdfs --daemon start datanode           # 只启动DataNode
# hdfs --daemon stop xxx               # 只停止xxx

hdfs --workers --daemon start datanode   # 启动所有节点上的DataNode
hdfs --workers --daemon stop datanode    # 停止所有节点上的DataNode

```
