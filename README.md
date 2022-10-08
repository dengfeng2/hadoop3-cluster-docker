# hadoop3-cluster-docker

## 新增hive

容器启动后，需要检查hive和hadoop使用的guava包的版本是否一致，
例如hadoop使用的guava的版本高于hive使用的guava版本，那么 `rm ${HIVE_HOME}/lib/guava-*.jar && cp ${HADOOP_HOME}/share/hadoop/common/lib/guava-*.jar ${HIVE_HOME}/lib/`.

hive 启动

配置:
```
# ----- hive-site.xml -----
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://mysql:3306/yhy</value>
    <description>
      JDBC connect string for a JDBC metastore.
      To use SSL to encrypt/authenticate the connection, provide database-specific SSL flag in the connection URL.
      For example, jdbc:postgresql://myhost/db?ssl=true for postgres database.
    </description>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>com.mysql.cj.jdbc.Driver</value>
    <description>Driver class name for a JDBC metastore</description>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>yhy</value>
    <description>Username to use against metastore database</description>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>my-secret-pw</value>
    <description>password to use against metastore database</description>
  </property>


# 在vi中替换变量
:%s#${system:java.io.tmpdir}#/tmp/javaiotmp#
:%s#${system:user.name}#root#

----- hadoop core-site.xml -----
    <property>
        <name>hadoop.proxyuser.root.hosts</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.proxyuser.root.groups</name>
        <value>*</value>
    </property>
```

初始化元数据库：`schematool -initSchema -dbType mysql`


通过hiveserver2
需要将hive-site.xml文件中的hive.server2.thrift.bind.host属性配置为hadoop01
```Bash
$ hiveserver2                     # 启动hiveserver2服务
$ hive --service hiveserver2 &    # 后台启动hiveserver2服务

                                  # 连接hiveserver2
$ bin/beeline
beeline> !connect jdbc:hive2://hadoop01:10000
```

通过metastore
需要将hive-site.xml文件中的hive.metastore.uris属性配置为thrift://hadoop01:9083, 这里要注意的是，由于docker的网络名称中包含下划线，远程连接时会出现URI解析失败。不过本地连接通过/etc/hosts，URI会解析成功。
```Bash
$ hive --service metastore &      # 后台启动metastore服务

$ bin/hive                        # 连接metastore

```

---
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
