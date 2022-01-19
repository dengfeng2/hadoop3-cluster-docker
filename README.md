# hadoop2-cluster-docker


利用docker容器模拟hadoop集群的部署。

使用步骤：

1. 在项目根目录下放置hadoop3的部署包，一般情况下，官方包名为 hadoop-x.x.x.tar.gz, 其中xxx为版本号
2. 使用脚本`build.sh`构建镜像，脚本内部的命令`docker build -t hadoop-base --build-arg HADOOP_PACKAGE=hadoop-x.x.x .` 构建一个名为hadoop3的镜像，此处记得将版本号换成自己所用的hadoop版本号；
3. 修改etc-hadoop文件夹下的配置文件;
4. 使用`docker-compose up` 启动hadoop容器集群；

关于hadoop容器集群的规划在文件docker-compose.yml中:
- hadoop01: NameNode, DataNode, NodeManager, ResourceManager, JobHistoryServer
- hadoop02: SecondaryNameNode, DataNode, NodeManager
- hadoop03: DataNode, NodeManager

按照如上规划，接下来应该：
1. 在hadoop01上执行`hdfs namenode -format`；
2. 在hadoop01的${HADOOP_HOME}/sbin/目录下，执行`./start-dfs.sh`；
3. 在hadoop01的${HADOOP_HOME}/sbin/目录下，执行`./start-yarn.sh`；
4. 在hadoop01的${HADOOP_HOME}/sbin/目录下，执行`./mr-jobhistory-daemon.sh start historyserver`；

接下来开始愉快的hadoop之旅吧！😏
