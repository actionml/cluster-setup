#PredictionIO Standalone Server Guide

This is a guide to setting up the PredictionIO EventServer and Universal Recommender PredictionServer in a standalone fashion. As of the time of writing this, instructions have been available that assumed either the single-host sandbox environment, or a distributed setup which still required installing all the software on all the hosts, even though it wouldn't run there (that is, the instructions assumed installing HBase, ElasticSearch and Spark on all nodes even though only the PIO software would be running).

##Pre-requisites

You should be familiar with the [basic cluster-setup instructions](readme.md).

##Build the Artifact

As per step 7 of the [basic cluster-setup instructions](readme.md), build
the PredictionIO artifact. This produces a gzipped tarball (PredictionIO-0.9.6.tar.gz modulo the version number). The installation will require this, as well as a few other files. While the all-in-one instructions build the artifact on the
same host as the target installation, this is not necessary.

##Common Installation

The EventServer and the PredictionServer run from the same artifact jar. There are common installation steps that are the same for both, and then additional installation steps required for the PredictionServer.

###Java

You'll need a JDK. It may be possible to just use a JRE, but that hasn't been
tested. The easiest thing to do is to obtain an rpm (or pkg, deb, etc, as appropriate for your linux distro) and install it.

These instructions were tested with Java 8 (jdk-8u65-linux-x64.rpm on CentOS).

###PredictionIO

1. Create a user named "pio".
1. In pio's home directory, create a directory named "pio".
1. untar the PredictionIO tarball into the pio directory, creating a PredictionIO-x.y.z directory.
1. Create a symbolic link to the PIO directory for convenience: ln -s PredictionIO PredictionIO-x.y.z
1. Inside the PredictionIO directory, create the directory path vendors/hbase-1.0.0/conf (use mkdir -p).
1. Place the following hbase-site.xml file in the hbase conf directory:
   > <configuration>
   >  <property>
   >    <name>hbase.zookeeper.quorum</name>
   >    <value>zk1,zk2,zk3</value> <!-- comma separated list of zookeeper hosts -->
   >  </property>
   >  <property>
   >    <name>hbase.zookeeper.property.clientPort</name>
   >    <value>2181</value>
   >  </property>
   > </configuration>
1. Modify PredictionIO/conf/pio-env.sh in the following way:
  1. Comment out SPARK_HOME
  1. Comment out POSTGRES_JDBC_DRIVER
  1. Comment out MYSQL_JDBC_DRIVER
  1. HBASE_CONF_DIR=$PIO_HOME/vendors/hbase-1.0.0/conf
  1. PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=ELASTICSEARCH
  1. PIO_STORAGE_REPOSITORIES_EVENTDATA_SOURCE=HBASE
  1. PIO_STORAGE_REPOSITORIES_MODELDATA_SOURCE=LOCALFS
  1. Comment out PIO_STORAGE_SOURCES_PGSQL_*
  1. PIO_STORAGE_SOURCES_ELASTICSEARCH_TYPE=elasticsearch
  1. PIO_STORAGE_SOURCES_ELASTICSEARCH_CLUSTERNAME=elasticsearch
  1. PIO_STORAGE_SOURCES_ELASTICSEARCH_HOSTS=es1,es2,es3 # comma-separated list of ElasticSearch hostnames
  1. PIO_STORAGE_SOURCES_ELASTICSEARCH_PORTS=9300
  1. PIO_STORAGE_SOURCES_LOCALFS_TYPE=localfs
  1. PIO_STORAGE_SOURCES_LOCALFS_PATH=$PIO_FS_BASEDIR/models
  1. PIO_STORAGE_SOURCES_HBASE_TYPE=hbase
  1. PIO_STORAGE_SOURCES_HBASE_HOSTS=hb1,hb2,hb3 # comma-separated list of ZooKeeper hosts that know where HBase is
  1. PIO_STORAGE_SOURCES_HBASE_PORTS=0,0,0 # unknown, but must be list of same size as _HBASE_HOSTS
1. Open port 7070 on this host; that's where events will get sent (that's the defalt port, but you can change it).
TODO


###Other Configuration

####.bash_profile

You'll need the following in your .bash_profile:
> # setup Java
> export JAVA_HOME=/usr/java/jdk1.8.0_65
>
> # setup specific to PIO
> export PIO_HOME=/home/pio/pio/PredictionIO
> export PATH=$PIO_HOME/bin:$PATH
> export JAVA_OPTS="-Xmx4g"
> export SPARK_HOME=/usr/local/spark # but there's nothing there

####pio-env.sh

##Other Host Setup

###Open Ports

In order for the PIO servers to communicate with them, the hosts running other services must have certain ports open. Sometimes there are additional requirements. This lists the other services, and the ports that must be open on those services' hosts in order to PIO to reach them.

* ElasticSearch
  Open port 9300

* HBase
TODO

##Automated Setup

TODO