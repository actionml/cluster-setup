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

   This will get used by the HBase client code to find HBase. Ideally the code will be fixed someday not to require this, but to instead get these values from PIO variables and [specify them directly to the client](http://stackoverflow.com/questions/17347841/hbase-zookeeper-tells-remote-client-to-connect-to-localhost).
1. Modify PredictionIO/conf/pio-env.sh in the following way:
  * Comment out SPARK_HOME
  * Comment out POSTGRES_JDBC_DRIVER
  * Comment out MYSQL_JDBC_DRIVER
  * HBASE_CONF_DIR=$PIO_HOME/vendors/hbase-1.0.0/conf
  * PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=ELASTICSEARCH
  * PIO_STORAGE_REPOSITORIES_EVENTDATA_SOURCE=HBASE
  * PIO_STORAGE_REPOSITORIES_MODELDATA_SOURCE=LOCALFS
  * Comment out PIO_STORAGE_SOURCES_PGSQL_*
  * PIO_STORAGE_SOURCES_ELASTICSEARCH_TYPE=elasticsearch
  * PIO_STORAGE_SOURCES_ELASTICSEARCH_CLUSTERNAME=elasticsearch
  * PIO_STORAGE_SOURCES_ELASTICSEARCH_HOSTS=es1,es2,es3 # comma-separated list of ElasticSearch hostnames
  * PIO_STORAGE_SOURCES_ELASTICSEARCH_PORTS=9300
  * PIO_STORAGE_SOURCES_LOCALFS_TYPE=localfs
  * PIO_STORAGE_SOURCES_LOCALFS_PATH=$PIO_FS_BASEDIR/models
  * PIO_STORAGE_SOURCES_HBASE_TYPE=hbase
  * PIO_STORAGE_SOURCES_HBASE_HOSTS=hb1,hb2,hb3 # comma-separated list of ZooKeeper hosts that know where HBase is
  * PIO_STORAGE_SOURCES_HBASE_PORTS=0,0,0 # unknown, but must be list of same size as _HBASE_HOSTS
1. Open port 7070 on this host; that's where events will get sent (that's the defalt port, but you can change it when launching the EventServer, in which case open the desired port here instead).

###Other Configuration

####.bash_profile

You'll need the following in your .bash_profile:

    # setup Java
    export JAVA_HOME=/usr/java/jdk1.8.0_65

    # setup specific to PIO
    export PIO_HOME=/home/pio/pio/PredictionIO
    export PATH=$PIO_HOME/bin:$PATH
    export JAVA_OPTS="-Xmx4g"
    export SPARK_HOME=/usr/local/spark # but there's nothing there

####Open Ports

In order for the PIO servers to communicate with them, the hosts running other services must have certain ports open. Sometimes there are additional requirements. This lists the other services, and the ports that must be open on those services' hosts in order to PIO to reach them.

* ElasticSearch Hosts
  Open port 9300

* HBase Hosts
  [HBase uses four ports](https://ambari.apache.org/1.2.3/installing-hadoop-using-ambari/content/reference_chap2_4.html) that its clients need access to at various times. These defaults seem to vary on different distributions, so the safest thing to do is to specify them explicitly in the HBase installation (in hbase-site.xml), and then open those ports (60000, 60010, 60020, 60030) on the HBase hosts.

  Beware that [HBase is fussy over host ip resolution](http://stackoverflow.com/questions/7791788/hbase-client-do-not-able-to-connect-with-remote-hbase-server). Setting up /etc/hosts or DNS may require extra care.

  Note that if you're trying to run against a [standalone installation of HBase](http://hbase.apache.org/0.94/book/standalone_dist.html), this won't work; in that mode, HBase seems to assign random ports each time it is started, and relies on its client to query for the ports via Zookeeper; this stymies attempts to use it from off the standalone host because you won't know which ports to open in advance; the settings in hbase-site.xml seem to be ignored for this mode.

##Automated Setup

These procedural setup instructions could be used to construct a docker container that could be used to run instances of the EventServer. Alternatively, the required bash, HBase, and pio-env.sh changes could be packaged up along with the original tarball contents into a new package that could be installed in an automated fashion.

##Starting the EventServer

Start the EventServer with

    pio eventserver

Note that this requires already having created your engine-model as per the all-in-one single host instructions. A server started in this way can be tested in the same way as described elsewhere; for example, this one was tested for a [Universal Recommender](http://templates.prediction.io/PredictionIO/template-scala-parallel-universal-recommendation), and was tested using the same examples/import_handmade.py script (see "Import Sample Data" on that page), with the addition of the --url parameter to specify this standalone eventserver's host.

The EventServer is multi-tenant, and multiple instances can be run as a scalable tier by using this installation procedure.

##Installing the PredictionServer

The PredictionServer requires the following additional setup on top of the
common piece described above for the EventServer.

TODO
