#PredictionIO Cluster Setup Guide

This is a guide to setting up PredictionIO and the Universal Recommender in a 3 node cluster. All services are setup with multi-masters in true clustered mode. To make  High Availability complete a secondary master would need to be setup for HDFS. Elasticsearch and HBase are already HA after using this setup howto.

You can also setup more servers and distribute the services mentioned here differently, but for the scope of this guide I won't explain how to do that, although you might use the references here to guide yourself into doing that.

The details of having any single machine reboot and rejoin all clusters is left to the reader and not covered here.

##Load Optimizations Rules

For specific types of load the following rules of thumb apply:

- For **heavy input event load** a separate cluster of HDFS + HBase + EventServer would be desirable. The EvnetServer is used at event input and during train and deploy so optimizing its execution speed can be done by separating it.
- For **training speed**, make sure the EventServer is fast in all load situations, then make sure Spark is fast. This may mean creating a separate Spark cluster. Different templated use Spark in different ways. For the Universal Recommender it is more important to have memory per executor and even more for the driver, than it is to have more executors. So for the UR you may want to limit executors so you can give each more memory.
- For **query load**, create more PredictionServers and for the Universal Recommender optimize Elasticsearch. This can be done by having a separate Elasticsearch cluster and the more memory you can give Elasticsearch the better the speed.


##Requirements

_Note: In this guide, all servers share all services, except PredictionIO, which runs only under the master server._

_If you want to distribute PIO, you need to setup a load balancer on top of each Eventserver and each PredictionServer (the product of `pio deploy`)_

- Hadoop 2.6.2 (Clustered)
- Spark 1.6.0 (Clustered)
- Elasticsearch 1.7.4 (Clustered, standby master)
- HBase 1.1.2 (Clustered, standby master)
- PredictionIO 0.9.6
- Universal Recommender Template Engine (Provided by ActionML)
- `Nix server, some commands are specific to Ubuntu, a Debian derivative


##1. Setup User and SSH on All Hosts:

1.1 Create user for PredictionIO `pio` in each server

    adduser pio # Give it some password

1.2 Give the `pio` user sudoers permissions

    usermod -a -G sudo pio

1.3 Setup passwordless ssh between all hosts of the cluster (a.k.a: Add pub key to authorized_keys) including all hosts to themselves. Setup the known_hosts too so no prompt will be generated when any host tries to connect via ssh to any other host. **Note:** The importance of this cannot be overstated! If ssh does not connect without requireing a password and without asking for confirmation to be added to `known_hosts` **nothing else in the howto will work!** This has been acomplished when all hosts can ssh to all other hosts including themselves without any prompt.

1.4 Modify `/etc/hosts` file and name each server
  - _Note: Avoid using "localhost" or "127.0.0.1"._

    ```
    # Use IPs for your hosts.
    10.0.0.1 some-master
    10.0.0.2 some-slave-1
    10.0.0.3 some-slave-2
    ```

##2. Download Services on **All** Hosts:

_Note: Download everything to a temp folder like `/tmp/downloads`, we will later move them to the final destinations._

2.1 Download [Hadoop 2.6.2](http://www.eu.apache.org/dist/hadoop/common/hadoop-2.6.2/hadoop-2.6.2.tar.gz)

2.2 Download [Spark 1.6.0](http://www.us.apache.org/dist/spark/spark-1.6.0/spark-1.6.0-bin-hadoop2.6.tgz)

2.3 Download [Elasticsearch 1.7.4](https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.4.tar.gz) **Note:** Don't use the Elasticsearch 2.x branch until PredictionIO supports it. The change will force and upgrade and pio will not be backwardly compatible with older versions of Elasticsearch.

2.4 Download HBase 1.1.2 (https://www.apache.org/dist/hbase/1.1.2/hbase-1.1.2-src.tar.gz) **Note:** due to a bug in pre 1.1.3 Hbase upgrade this asap to hbase 1.1.3

2.5 Clone PIO from its root repo into `~/pio`

    git clone https://github.com/actionml/PredictionIO.git pio

2.6 Clone Universal Recommender Template from its root repo into `~/universal`

    git clone https://github.com/actionml/template-scala-parallel-universal-recommendation.git universal


##3. Setup Java 1.7 or 1.8

3.1 Install Java JDK, if you prefer Oracle versions, that would be fine.

    sudo apt-get install openjdk-7-jdk

3.2 Check which versions of Java are installed and pick one, 1.7 or greater.

    sudo update-alternatives --config java

3.3 Set JAVA_HOME env var.
  - _Note: Don't include the `/bin` folder in the route._

    vim /etc/environment
    export JAVA_HOME=/path/to/open/jdk/jre

##4. Create Folders:

4.1 Create folders in `/opt`

	mkdir /opt/hadoop
	mkdir /opt/spark
	mkdir /opt/elasticsearch
	mkdir /opt/hbase
	chown pio:pio /opt/hadoop
	chown pio:pio /opt/spark
	chown pio:pio /opt/elasticsearch
	chown pio:pio /opt/hbase


##5. Extract Services

5.1 Inside the `/tmp/downloads` folder, extract all downloaded services.

5.2 Move extracted services to their folders

	sudo mv /tmp/downloads/hadoop-2.6.2 /opt/hadoop/
	sudo mv /tmp/downloads/spark-1.6.0 /opt/spark/
	sudo mv /tmp/downloads/elasticsearch-1.7.4 /opt/elasticsearch/
	sudo mv /tmp/downloads/hbase-1.1.2 /opt/hbase/

**Note:** Keep version numbers, if you upgrade or downgrade in the future just create new symlinks.

5.3 Symlink Folders

	sudo ln -s /opt/hadoop/hadoop-2.6.2 /usr/local/hadoop
	sudo ln -s /opt/spark/spark-1.6.0 /usr/local/sparl
	sudo ln -s /opt/elasticsearch/elasticsearch-1.7.4 /usr/local/elasticsearch
	sudo ln -s /opt/hbase/hbase-1.1.2 /usr/local/hbase
	sudo ln -s /home/pio/pio /usr/local/pio

##6. Setup Clustered services

### 6.1. Setup Hadoop Cluster
- Read: [this tutorial](http://www.tutorialspoint.com/hadoop/hadoop_multi_node_cluster.htm)
- Files config:
  - `etc/hadoop/core-site.xml`

    ```
	<configuration>
	    <property>
	        <name>fs.defaultFS</name>
	        <value>hdfs://some-master:9000</value>
	    </property>
	</configuration>
	```

  - `etc/hadoop/hadoop/hdfs-site.xml`

    ```
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

    ```
    <configuration>
       <property>
          <name>mapred.job.tracker</name>
          <value>some-master:9001</value>
       </property>
    </configuration>
    ```

  - `etc/hadoop/masters`

	```
	some-master`
	```

  - `etc/hadoop/slaves`

    ```
    some-slave-1
    some-slave-2
    ```

  - `etc/hadoop/hadoop-env.sh`

    ```
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

      bin/hadoop namenode -format

- Start dfs servers only. 

      sbin/start-dfs.sh

**Note:** do not use `sbin/start-all.sh` because it will needlessly start mapreduce and yarn. These can work together but for the pursposes of this serup they are not needed.

- Create `/hbase` and `/zookeper` folders under HDFS

      bin/hdfs dfs -mkdir /hbase /zookeeper

#### 6.2. Setup Spark Cluster.
- Read and follow [this tutorial](http://spark.apache.org/docs/latest/spark-standalone.html)
- Start all nodes in the cluster

    `sbin/start-all.sh`


#### 6.3. Setup Elasticsearch Cluster

- Change the `conf/elasticsearch.yml` file to reflect this:

```
cluster.name: elasticsearch-pio-poc
node.name: "some-master" # Change to the name of the slave if the server is a slave.
node.master: true # set to true on masters, others are false
node.data: true # any node can be a data node
discovery.zen.ping.multicast.enabled: false # most cloud services don't allow multicast
discovery.zen.ping.unicast.hosts: ["some-master", "some-slave-1", "some-slave-2"] # add all hosts, masters and/or data nodes
```

- copy Elasticsearch and config to all hosts. 

#### 6.4. Setup HBase Cluster (abandon hope all ye who enter here)

This [tutorial](https://hbase.apache.org/book.html#quickstart_fully_distributed) is the **best guide**, many others produce incorrect results . The primary thing to remember is to install and configure on single machine then adding all desired hostnames to `backupmasters`, `regionservers`, and to the `hbase.zookeeper.quorum` config param, then copy **all code and config** to all other machines with something like `scp -r ...` Every machine will then be identical. 

6.4.1 Files config:
  - `conf/hbase-site.xml`

        <configuration>
	        <property>
	          <name>hbase.rootdir</name>
	          <value>hdfs://some-master:9000/hbase</value>
	        </property>
	
	         <property>
	          <name>hbase.cluster.distributed</name>
	          <value>true</value>
	        </property>
	
	        <property>
	          <name>hbase.zookeeper.property.dataDir</name>
	          <value>hdfs://some-master:9000/zookeeper</value>
	        </property>
	
	        <property>
	          <name>hbase.zookeeper.quorum</name>
	          <value>some-master,some-slave-1,some-slave-2</value>
	        </property>
	
	        <property>
	          <name>hbase.zookeeper.property.clientPort</name>
	          <value>2181</value>
	        </property>
        </configuration>

  - `conf/regionservers`

		some-master
		some-slave-1
		some-slave-2

  - `conf/backupmasters`

        some-slave-1

  - `conf/hbase-env.sh`

		export JAVA_HOME=${JAVA_HOME}
		export HBASE_OPTS="-XX:+UseConcMarkSweepGC"
		export HBASE_MASTER_OPTS="$HBASE_MASTER_OPTS -XX:PermSize=128m -XX:MaxPermSize=128m"
		export HBASE_REGIONSERVER_OPTS="$HBASE_REGIONSERVER_OPTS -XX:PermSize=128m -XX:MaxPermSize=128m"
		export HBASE_PID_DIR=/var/hbase/pids
		export HBASE_MANAGES_ZK=true

6.4.2 Start HBase

    `bin/start-hbase.sh`

At this point you should see several different processes start on the master and slaves including regionservers and zookeeper servers. If there is an error check the logfiles referenced in the error message. These logfiles may reside on a different host as indicated in the file's name.

**Note:** It is strongly recommend to setup these files in the master `/usr/local/hbase/conf` folder and then copy **all** code and sub-folders or the to the slaves.


##7. Setup PredictionIO

Setup PIO on the master or on all servers (if you plan to use a load balancer). The Setup **must not** use the install.sh since you are using clustered services and that script only supports a standalone machine. 

7.1 Build PredictionIO

We put PredictionIO in `/home/pio/pio` Change to that location and run 

    ./make-distribution
    
This will create an artifact for PredictionIO

7.2 Setup Path for PIO commands

Add PIO to the path










