PredictionIO Setup Guide
--

This is a pretty much self-noted guide to setting up PredictionIO in a cluster of 3 servers (for this guide in particular).

You can also setup more servers and distribute the services mentioned here differently, but for the scope of this guide I won't explain how to do that, although you might use the references here to guide yourself into doing that.


0. Requirements:
--

_Note: In this guide, all servers share all services, except PredictionIO, which runs only under the master server._

_If you wanna distribute PIO, you need to setup a load balancer on top of each Eventserver._

- Hadoop 2.6.2 (Pseudo-distributed mode)
- Spark 1.5.2
- Elasticsearch 1.7.4 (Clustered)
- HBase 1.1.2 (Multi node cluster)
- PredictionIO 0.9.6
- Universal Recommender Template Engine (Provided by ActionML)


1. Setup User:
--

1.1 Create user for PredictionIO `pio` in each server

    adduser pio # Give it some password

1.2 Give the `pio` user sudoers permissions

    usermod -a -G sudo pio

1.3 Setup paswordless ssh between all servers of the cluster (a.k.a: Add pub key to authorized_keys)

1.4 Modify `/etc/hosts` file and name each server
  - _Note: Avoid using "localhost" or "127.0.0.1"._

    ```bash
    # Change IPs where it corresponds.
    10.0.0.1 master
    10.0.0.2 slave-1
    10.0.0.3 slave-2
    ```


2. Download services in **all** servers:
--
_Note: Download everything to a temp folder like `/tmp/downloads`, we will later move them to the final destinations._

2.1 Download Hadoop 2.6.2 (http://www.eu.apache.org/dist/hadoop/common/hadoop-2.6.2/hadoop-2.6.2.tar.gz)

2.2 Download Spark 1.5.2 (http://www.us.apache.org/dist/spark/spark-1.5.2/spark-1.5.2-bin-hadoop2.6.tgz)

2.3 Download Elasticsearch 1.7.4 (https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.4.tar.gz)
  - **DON'T USE 2.0 UNTIL PIO WORKS WITH IT. (Pat said there were some issues).**

2.4 Download HBase 1.1.2 (https://www.apache.org/dist/hbase/1.1.2/hbase-1.1.2-src.tar.gz)

2.5 Clone PIO Enterprise (TODO)

2.6 Clone Universal Recommender Template (TODO)


3. Setup Java 1.7 or 1.8 (OpenJDK):
--

3.1 Install Java.

    sudo apt-get install openjdk-7-jdk

3.2 Check which versions of Java are installed and pick one (Ideally OpenJDK, PIO has issues with Oracle Java.)

    sudo update-alternatives --config java

3.3 Set JAVA_HOME env var.
  - _Note: Don't include the `/bin` folder in the route._

    ```bash
    vim /etc/environment
    export JAVA_HOME=/path/to/open/jdk/jre
    ```


4. Create Folders:
--

4.1 Create folders in `/opt`

  ```bash
  mkdir /opt/hadoop
  mkdir /opt/spark
  mkdir /opt/elasticsearch
  mkdir /opt/hbase
  mkdir /opt/pio

  chown pio:pio /opt/hadoop
  chown pio:pio /opt/spark
  chown pio:pio /opt/elasticsearch
  chown pio:pio /opt/hbase
  chown pio:pio /opt/pio
  ```


5. Extract Services:
--

5.1 Inside the `/tmp/downloads` folder, extract all downloaded services.

5.2 Move extracted services to their folders

  ```bash
  sudo mv /tmp/downloads/hadoop-2.6.2 /opt/hadoop/
  sudo mv /tmp/downloads/spark-1.5.2 /opt/spark/
  sudo mv /tmp/downloads/elasticsearch-1.7.4 /opt/elasticsearch/
  sudo mv /tmp/downloads/hbase-1.1.2 /opt/hbase/
  sudo mv /tmp/downloads/predictionio /opt/pio/
  ```

5.3 NOTE: Keep version numbers, if we want to upgrade in the future without losing previous versions, we just need to re-symlink.

5.4 Symlink Folders

  ```bash
  sudo ln -s /opt/hadoop/hadoop-2.6.2 /usr/local/hadoop
  sudo ln -s /opt/spark/spark-1.5.2 /usr/local/sparl
  sudo ln -s /opt/elasticsearch/elasticsearch-1.7.4 /usr/local/elasticsearch
  sudo ln -s /opt/hbase/hbase-1.1.2 /usr/local/hbase
  sudo ln -s /opt/pio/predictionio /usr/local/pio
  ```


6. Setup clusterized services:
--

#### 6.1. Setup Hadoop in seudo-distributed mode (a.k.a Multi Node Cluster)
- Read: http://www.tutorialspoint.com/hadoop/hadoop_multi_node_cluster.htm
- Files config:
  - `etc/hadoop/core-site.xml`

      ```xml
      <configuration>
          <property>
              <name>fs.defaultFS</name>
              <value>hdfs://master:9000</value>
          </property>
      </configuration>
      ```

  - `etc/hadoop/hadoop/hdfs-site.xml`

      ```xml
      <configuration>
         <property>
            <name>dfs.data.dir</name>
            <value>file:///usr/local/hadoop/dfs/name/data</value>
            <final>true</final>
         </property>

         <property>
            <name>dfs.name.dir</name>
            <value>file:///usr/local/hadoop/dfs/name</value>
            <final>true</final>
         </property>

         <property>
            <name>dfs.replication</name>
            <value>1</value>
         </property>
      </configuration>
      ```

  - `etc/hadoop/mapred-site.xml`

      ```xml
      <configuration>
         <property>
            <name>mapred.job.tracker</name>
            <value>master:9001</value>
         </property>
      </configuration>
      ```

  - `etc/hadoop/masters`

      `master`

  - `etc/hadoop/slaves`

      ```
      slave-1
      slave-2
      ```

  - `etc/hadoop/hadoop-env.sh`

      ```bash
      export JAVA_HOME=${JAVA_HOME}
      export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-"/etc/hadoop"}
      for f in $HADOOP_HOME/contrib/capacity-scheduler/*.jar; do
        if [ "$HADOOP_CLASSPATH" ]; then
          export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$f
        else
          export HADOOP_CLASSPATH=$f
        fi
      done
      export HADOOP_OPTS="$HADOOP_OPTS -Djava.net.preferIPv4Stack=true"
      export HADOOP_NAMENODE_OPTS="-Dhadoop.security.logger=${HADOOP_SECURITY_LOGGER:-INFO,RFAS} -Dhdfs.audit.logger=${HDFS_AUDIT_LOGGER:-INFO,NullAppender} $HADOOP_NAMENODE_OPTS"
      export HADOOP_DATANODE_OPTS="-Dhadoop.security.logger=ERROR,RFAS $HADOOP_DATANODE_OPTS"
      export HADOOP_SECONDARYNAMENODE_OPTS="-Dhadoop.security.logger=${HADOOP_SECURITY_LOGGER:-INFO,RFAS} -Dhdfs.audit.logger=${HDFS_AUDIT_LOGGER:-INFO,NullAppender} $HADOOP_SECONDARYNAMENODE_OPTS"
      export HADOOP_NFS3_OPTS="$HADOOP_NFS3_OPTS"
      export HADOOP_PORTMAP_OPTS="-Xmx512m $HADOOP_PORTMAP_OPTS"
      export HADOOP_CLIENT_OPTS="-Xmx512m $HADOOP_CLIENT_OPTS"
      export HADOOP_SECURE_DN_USER=${HADOOP_SECURE_DN_USER}
      export HADOOP_SECURE_DN_LOG_DIR=${HADOOP_LOG_DIR}/${HADOOP_HDFS_USER}
      export HADOOP_PID_DIR=${HADOOP_PID_DIR}
      export HADOOP_SECURE_DN_PID_DIR=${HADOOP_PID_DIR}
      export HADOOP_IDENT_STRING=$USER
      ```

- Format Namenode

      `bin/hadoop namenode -format`

- Start just dfs servers.

      `sbin/start-dfs.sh`

- Create `/hbase` and `/zookeper` folders

    `bin/hdfs dfs -mkdir /hbase /zookeeper`

NOTES:
- Follow instructions in the guide and just set up master and slaves, then start only the hdfs ("hadoop distrubuted file system"), DO NOT DO `start-all.sh`

#### 6.2. Setup Spark in pseudo-distributed mode.
- Pretty straight forward: http://spark.apache.org/docs/latest/spark-standalone.html
- Start Master

    `sbin/start-master.sh`

- Start Slaves

    `sbin/start-slave.sh <master-spark-URL>`

#### 6.3. Setup Elasticsearch
- Change the `conf/elasticsearch.yml` file to reflect this:

    ```bash
    cluster.name: elasticsearch-pio-poc
    node.name: "master" # Change to the name of the slave if the server is a slave.
    node.master: true # SET TO TRUE ONLY IN MASTER, OTHERS IS FALSE
    node.data: true
    discovery.zen.ping.multicast.enabled: false
    discovery.zen.ping.unicast.hosts: ["master", "slave-1", "slave-2"] # ADD ALL THE SERVERS
    ```

#### 6.4. Setup HBase (Prepare for hell)

- THIS IS THE BEST GUIDE, TRUST NO OTHER (This is actually the official guide) https://hbase.apache.org/book.html#quickstart_fully_distributed
- Files config:
  - `conf/hbase-site.xml`

      ```xml
      <configuration>
        <property>
          <name>hbase.rootdir</name>
          <value>hdfs://master:9000/hbase</value>
        </property>

         <property>
          <name>hbase.cluster.distributed</name>
          <value>true</value>
        </property>

        <property>
          <name>hbase.zookeeper.property.dataDir</name>
          <value>hdfs://master:9000/zookeeper</value>
        </property>

        <property>
          <name>hbase.zookeeper.quorum</name>
          <value>master,slave-1,slave-2</value>
        </property>

        <property>
          <name>hbase.zookeeper.property.clientPort</name>
          <value>2181</value>
        </property>
      </configuration>
      ```

  - `conf/regionservers`

      ```
      master
      slave-1
      slave-2
      ```

  - `conf/backupmasters`

      `slave-1`

  - `conf/hbase-env.sh`

      ```bash
      export JAVA_HOME=${JAVA_HOME}
      export HBASE_OPTS="-XX:+UseConcMarkSweepGC"
      export HBASE_MASTER_OPTS="$HBASE_MASTER_OPTS -XX:PermSize=128m -XX:MaxPermSize=128m"
      export HBASE_REGIONSERVER_OPTS="$HBASE_REGIONSERVER_OPTS -XX:PermSize=128m -XX:MaxPermSize=128m"
      export HBASE_PID_DIR=/var/hbase/pids
      export HBASE_MANAGES_ZK=true
      ```

- Start HBase

    `bin/start-hbase.sh`

- NOTE: I strongly recommend setting all these files just in the master `conf` folder and just copying **the whole** `conf/*` folder to the slaves.


7. TODO: Setup PIO
--






