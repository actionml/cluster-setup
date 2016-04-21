#PredictionIO Standalone Server Guide: The Driver Machine

This is a guide to setting up the PredictionIO EventServer and Universal Recommender PredictionServer in a standalone fashion so all constituent services run on a single machine. At the end of this guide we will spin up a Spark cluster and offload the majority of training work to the cluster, then take it offline so it costs nothing while idle.

## AWS

Create an instance on AWS (other services may work too, but this is tested on AWS) that has enough memory to run all of the PredictionIO services. This will be something like an m3.xlarge or m3.2xlarge. 

##Before You Start

Follow the [Small HA Cluster-setup instructions](small-ha-cluster-setup.md) except for the following differences:

 - First remember that we will be setting up only one machine so where you see references to more than one, ignore the other machines.
 - Use the Driver Machine's DNS name for setup but never "localhost". This is so it will be easier to scale later. 
 - Do not use `/etc/hosts` to add names for the Driver Machine, us the internal AWS DNS name in all config. 
 - For some not well understood reason you must use localhost to point HBase's Zookeeper to the Driver Machine when not in a cluster. So in `/usr/local/hbase/conf/hbase-site.xml` use the following: 

		<configuration>
		  <property>
		    <name>hbase.rootdir</name>
		    <value>hdfs://driver-machine:9000/hbase</value>
		  </property>
		
		  <property>
		    <name>hbase.cluster.distributed</name>
		    <value>true</value>
		  </property>
		
		  <property>
		    <name>hbase.zookeeper.property.dataDir</name>
		    <value>hdfs://driver-machine:9000/zookeeper</value>
		  </property>
		
		  <property>
		    <name>hbase.zookeeper.quorum</name>
		    <value>localhost</value>
		  </property>
		
		  <property>
		    <name>hbase.zookeeper.property.clientPort</name>
		    <value>2181</value>
		  </property>
		</configuration>
		
	Notice the `hbase.zookeeper.quorum` is localhost. Substituting 
	
 - Do not create the `/usr/local/hbase/conf/backupmasters` file
