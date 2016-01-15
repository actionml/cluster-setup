#PredictionIO Cluster Setup Guide

This is a guide to setting up PredictionIO and the Universal Recommender in a 3 node cluster. All services are setup with multi-masters in true clustered mode. To make  High Availability complete a secondary master would need to be setup for HDFS. Elasticsearch and HBase are already HA after using this guide.

You can also setup more servers and distribute the services mentioned here differently, but for the scope of this guide I won't explain how to do that, although you might use the references here to guide yourself.

The details of having any single machine reboot and rejoin all clusters is left to the reader and not covered here.

##Load Optimizations Rules

For specific types of load the following rules of thumb apply:

- For **heavy input event load** a separate cluster of HDFS + HBase would be desirable. The EvnetServer is used at all phases, at event input, during train, and is queried in real-time by the deployed PredictionServer/Engine. The EventSever is built on top of HBase so optimizing its execution speed can effect all aspects of performance.
- For **training speed**, make sure the EventServer is fast, then make sure Spark is fast. This may mean creating a separate Spark cluster. Different templates use Spark in different ways. For the Universal Recommender it is most important to have memory per executor/driver than it is to have more executors. You may even want to limit executors so you can give each more memory. Another way to say this is that CPU load tends to be small so IO is usually the bottleneck. 
- For **query load**, make sure the EventServer is fast, then create more PredictionServers and for the Universal Recommender optimize Elasticsearch. This can be done by having a separate Elasticsearch cluster and the more memory you can give Elasticsearch the better the speed.

PredictionIO save no state itself but uses clustered services so scaling the services scales PredictionIO. The upshot of this design means that PedictionIO doesn not need to know about other instances of the EventServer of any PredictionServers. They do not cooperate outside of the well documented clustered services it uses. However this means there is no load balancing built into PredictionIO. 

If you were to launch the PIO EventServer or PreditionServer on 10 machines and 2 go down, the rest of the servers will continue to respond as long as the clusters operate. To spread load can be acomplished using a load-balancer. This will account for machines going down and to make sure no server is overloaded.

##Requirements

In this guide, all servers share all services, except PredictionIO, which runs only on the master server. Setup of multiple EventServers and PredictionServers is done with load-balancers and is out of the scope of this guide.

- Hadoop 2.6.2 (Clustered)
- Spark 1.5.2 (Clustered)
- Elasticsearch 1.7.4 (Clustered, standby master)
- HBase 1.1.2 (Clustered, standby master), due to a bug in 1.1.2 it is advised you move to 1.1.3 as quickly as it is available (as of this writing it is in rc1)
- PredictionIO 0.9.6 (as of this writing a work in progress so must be built from source)
- Universal Recommender Template Engine (Provided by ActionML)
- `Nix server, some instructions below are specific to Ubuntu, a Debian derivative


##1. Setup User, SSH, and host naming on All Hosts:

1.1 Create user for PredictionIO `pio` in each server

    adduser pio # Give it some password

1.2 Give the `pio` user sudoers permissions

    usermod -a -G sudo pio

1.3 Setup passwordless ssh between all hosts of the cluster. This is a combination of adding all public keys to `authorized_keys` and making sure that `known_hosts` includes all cluster hosts, including any host to itself. There must be no prompt generated when any host tries to connect via ssh to any other host. **Note:** The importance of this cannot be overstated! If ssh does not connect without requiring a password and without asking for confirmation **nothing else in the guide will work!** 

1.4 Modify `/etc/hosts` file and name each server

  - _Note: Don't use "localhost" or "127.0.0.1"._

    ```
    # Use IPs for your hosts.
    10.0.0.1 some-master
    10.0.0.2 some-slave-1
    10.0.0.3 some-slave-2
    ```

##2. Download Services on all Hosts:

Download everything to a temp folder like `/tmp/downloads`, we will later move them to the final destinations.

2.1 Download [Hadoop 2.6.2](http://www.eu.apache.org/dist/hadoop/common/hadoop-2.6.2/hadoop-2.6.2.tar.gz)

2.2 Download [Spark 1.5.2](http://www.us.apache.org/dist/spark/spark-1.5.2/spark-1.5.2-bin-hadoop2.6.tgz)

2.3 Download [Elasticsearch 1.7.4](https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.4.tar.gz) **Note:** Don't use the Elasticsearch 2.x branch until PredictionIO supports it. The change will force and upgrade and pio will not be backwardly compatible with older versions of Elasticsearch.

2.4 Download HBase 1.1.2 (https://www.apache.org/dist/hbase/1.1.2/hbase-1.1.2-src.tar.gz) **Note:** due to a bug in pre 1.1.3 Hbase upgrade this asap to hbase 1.1.3

2.5 Clone PIO from its root repo into `~/pio`

    git clone https://github.com/actionml/PredictionIO.git pio
    cd ~/pio
    git checkout v0.9.6 #get the latest branch

2.6 Clone Universal Recommender Template from its root repo into `~/universal`

    git clone https://github.com/actionml/template-scala-parallel-universal-recommendation.git universal
	cd ~/universal
	git checkout v0.3.0 # or get the latest branch

##3. Setup Java 1.7 or 1.8

3.1 Install Java OpenJDK or Oracle JDK for Java 7 or 8, the JRE version is not sufficient.

    sudo apt-get install openjdk-7-jdk

3.2 Check which versions of Java are installed and pick a 1.7 or greater.

    sudo update-alternatives --config java

3.3 Set JAVA_HOME env var.

Don't include the `/bin` folder in the path. This can be problematic so if you get complaints about JAVA_HOME you may need to change xxx-env.sh depending on which service complains. For instance `hbase-env.sh` has a JAVA_HOME setting if HBase complains when starting.

    vim /etc/environment
    # add the following
    export JAVA_HOME=/path/to/open/jdk/jre
    # some would rather add JAVA_HOME to /home/pio/.bashrc

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

5.2 Move extracted services to their folders. This can be done on the master and then copied to all hosts using `scp` as long as all hosts allow passwordless key based ssh and the ownership has been set correctly on all hosts to `pio:pio`

	sudo mv /tmp/downloads/hadoop-2.6.2 /opt/hadoop/
	sudo mv /tmp/downloads/spark-1.5.2 /opt/spark/
	sudo mv /tmp/downloads/elasticsearch-1.7.4 /opt/elasticsearch/
	sudo mv /tmp/downloads/hbase-1.1.2 /opt/hbase/

**Note:** Keep version numbers, if you upgrade or downgrade in the future just create new symlinks.

5.3 Symlink Folders

	sudo ln -s /opt/hadoop/hadoop-2.6.2 /usr/local/hadoop
	sudo ln -s /opt/spark/spark-1.5.2 /usr/local/sparl
	sudo ln -s /opt/elasticsearch/elasticsearch-1.7.4 /usr/local/elasticsearch
	sudo ln -s /opt/hbase/hbase-1.1.2 /usr/local/hbase
	sudo ln -s /home/pio/pio /usr/local/pio

##6. Setup Clustered services

### 6.1. Setup Hadoop Cluster

Read [this tutorial](http://www.tutorialspoint.com/hadoop/hadoop_multi_node_cluster.htm)

- Files config: this  defines the defines where th root of HDFS will be. To write to HDFS you can reference this location, for instance in place of a local path like `file:///home/pio/file` you could read or write `hdfs://some-master:9000/user/pio/file`

  - `etc/hadoop/core-site.xml`

    ```
	<configuration>
	    <property>
	        <name>fs.defaultFS</name>
	        <value>hdfs://some-master:9000</value>
	    </property>
	</configuration>
	```

  - `etc/hadoop/hadoop/hdfs-site.xml` This sets the actual filesystem location that hadoop will use to save data and how many copies of the data to be kept. In case of storage corruption, hadoop will restore from a replica and eventually restore replicas. If a server goes down, all data on that server will be re-created if you have at a `dfs.replication` of least 2. 

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
	      <value>2</value>
	   </property>
	</configuration>
    ```

  - `etc/hadoop/masters` One master for this config.

	```
	some-master
	```

  - `etc/hadoop/slaves` Slaves for HDFS means they have datanodes so the master may also host data with this config

    ```
    some-master
    some-slave-1
    some-slave-2
    ```

  - `etc/hadoop/hadoop-env.sh` make sure the following values are set

    ```
    export JAVA_HOME=${JAVA_HOME}
    # this has been set for hadoop historically but not sure it is needed anymore
    export HADOOP_OPTS=-Djava.net.preferIPv4Stack=true 
    export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-"/etc/hadoop"}
    ```

- Format Namenode

      bin/hadoop namenode -format
      
    This will result actions logged to the terminal, make sure there are no errors

- Start dfs servers only. 

      sbin/start-dfs.sh

    Do not use `sbin/start-all.sh` because it will needlessly start mapreduce and yarn. These can work together with PreditionIO but for the pursposes of this guide they are not needed.

- Create `/hbase` and `/zookeper` folders under HDFS

      bin/hdfs dfs -mkdir /hbase /zookeeper

#### 6.2. Setup Spark Cluster.
- Read and follow [this tutorial](http://spark.apache.org/docs/latest/spark-standalone.html) The primary thing that must be setup is the masters and slaves, which for our purposes will be the same as for hadoop
-  `conf/masters` One master for this config.

	```
	some-master
	```

  - `conf/slaves` Slaves for Spark means they are workers so the master be included

    ```
    some-master
    some-slave-1
    some-slave-2
    ```

- Start all nodes in the cluster

    `sbin/start-all.sh`


#### 6.3. Setup Elasticsearch Cluster

- Change the `/usr/local/elasticsearch/config/elasticsearch.yml` file as shown below. This is minimal and allows all hosts to act as backup masters in case the acting master goes down. Also all hosts are data/index nodes so can respond to queries and host shards of the index. 

  ```
cluster.name: your-app-name
discovery.zen.ping.multicast.enabled: false # most cloud services don't allow multicast
discovery.zen.ping.unicast.hosts: ["some-master", "some-slave-1", "some-slave-2"] # add all hosts, masters and/or data nodes
	```

- copy Elasticsearch and config to all hosts using `scp -r /opt/elasticsearch/... pio@some-host://opt/elasticsearch`. Like HBase, all hosts are identical.

#### 6.4. Setup HBase Cluster (abandon hope all ye who enter here)

This [tutorial](https://hbase.apache.org/book.html#quickstart_fully_distributed) is the **best guide**, many others produce incorrect results . The primary thing to remember is to install and configure on a single machine, adding all desired hostnames to `backupmasters`, `regionservers`, and to the `hbase.zookeeper.quorum` config param, then copy **all code and config** to all other machines with something like `scp -r ...` Every machine will then be identical. 

6.4.1 Configure with these changes to `/usr/local/hbase/conf`
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
		export HBASE_MANAGES_ZK=true

6.4.2 Start HBase

    `bin/start-hbase.sh`

At this point you should see several different processes start on the master and slaves including regionservers and zookeeper servers. If there is an error check the logfiles referenced in the error message. These logfiles may reside on a different host as indicated in the file's name.

**Note:** It is strongly recommend to setup these files in the master `/usr/local/hbase` folder and then copy **all** code and sub-folders or the to the slaves. All members of the cluster must have the same code and config


##7. Setup PredictionIO

Setup PIO on the master or on all servers (if you plan to use a load balancer). The Setup **must not** use the install.sh since you are using clustered services and that script only supports a standalone machine. 

7.1 Build PredictionIO

We put PredictionIO in `/home/pio/pio` Change to that location and run 

    ./make-distribution
    
This will create an artifact for PredictionIO

7.2 Setup Path for PIO commands

Add PIO to the path by editing your `~/.bashrc` on the master. Here is an example of the important values I have in the file. After changing it remember for execute `source ~/.bashrc` to get the changes into the running shell.

**Note:** Some of these are duplicated in service specific env files


    # Java
	export JAVA_HOME=/usr # this may not work of everyone
	export PATH=$PATH:/usr/local/pio/bin:/usr/local/hadoop/sbin:/usr/local/hadoop/bin:/usr/local/spark/sbin
	export JAVA_OPTS="-Xmx8g" # The Universal recommender driver likes memory so I set it here
	# it could also be passed in to the launcher every time - this is a shorcut
	
	# Hadoop 
	export HADOOP_INSTALL=/usr/local/hadoop
	export HADOOP_PREFIX=/usr/local/hadoop
	export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_INSTALL/lib/native
	export HADOOP_COMMON_HOME=$HADOOP_INSTALL
	export HADOOP_CONF_DIR=$HADOOP_INSTALL/etc/hadoop
	export HADOOP_HDFS_HOME=$HADOOP_INSTALL
	export YARN_HOME=$HADOOP_INSTALL
	export HADOOP_MAPRED_HOME=$HADOOP_INSTALL
	export PATH=$PATH:/usr/local/hadoop/bin:/usr/local/hadoop/sbin
	
	# a convenient hadoop alias
	unalias fs &> /dev/null
	alias fs="$HADOOP_INSTALL/bin/hdfs dfs"
	
	# hbase
	export HBASE_HOME=/usr/local/hbase
	export PATH=$HBASE_HOME/bin:$PATH
	
	#pio
	PATH=$PATH:/usr/local/pio
	
	#Spark
	MASTER=spark://pio-poc4:7077
	export SPARK_HOME=/usr/local/spark
	
Run `source ~/.bashrc` to get changes applied. Then you should be able to run

    pio-start-all
    pio status

The status of all services will be printed but no check is made of the HDFS or Spark services so check them separately by looking at their GUI status pages. They are here:

 - HDFS: http://some-master:50070
 - Spark: http://some-master:8080

##8. Setup the Universal Recommender

The Universal Recommender is a PredcitionIO Template. Refer to the [UR README.md](https://github.com/actionml/template-scala-parallel-universal-recommendation) for configuration. 

To run the integration test start by getting the source code.

    cd ~
    git clone https://github.com/actionml/template-scala-parallel-universal-recommendation.git universal
    cd universal
    pio app new handmade
    ./examples/integration-test
    
This will take a little time to complete. It will insert app data into the EventServer started with `pio-start-all`, will train a model, and will run several sample queries. It will then print a diff of the actual results with the expected results. It is common to have one line that is different, this is due to JVM differences and it can be safely ignored (as we try to find a way to avoid it).







