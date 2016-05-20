#PredictionIO Standalone Server Guide: The Driver Machine

This is a guide to setting up the PredictionIO EventServer and Universal Recommender PredictionServer in a standalone fashion so all constituent services run on a single machine. At the end of this guide we will spin up a Spark cluster and offload the majority of training work to the cluster, then take it offline so it costs nothing while idle.

## AWS

Create an instance on AWS (other services may work too, but this is tested on AWS) that has enough memory to run all of the PredictionIO services. This will be something like an m3.xlarge or m3.2xlarge. 

##Before You Start

Follow the [Small HA Cluster-setup instructions](small-ha-cluster-setup.md) except for the following differences:

 - First remember that we will be setting up only one machine so where you see references to more than one, ignore the other machines.
 - Use the Driver Machine's DNS name for setup but never "localhost". This is so it will be easier to scale later. 
 - Do not use `/etc/hosts` to add names for the Driver Machine, use the internal AWS DNS name in all configs. 
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
 
 - Do not use HDFS for the PredictionIO "models" storage so set these value in `/usr/local/pio/conf/pio-env.sh`
 
 		PIO_STORAGE_REPOSITORIES_MODELDATA_NAME=pio_model
		PIO_STORAGE_REPOSITORIES_MODELDATA_SOURCE=LOCALFS
		
		PIO_STORAGE_SOURCES_LOCALFS_TYPE=localfs
		PIO_STORAGE_SOURCES_LOCALFS_HOSTS=$PIO_FS_BASEDIR/models
		
 - start platform services
 
               $ /usr/local/hadoop/sbin/start-dfs.sh
                $ /usr/local/spark/start-all.sh # if using the local host to run Spark

 - start the pio services and teh EventServer

                $ pio-start-all

 - to restart pio serives

                $ pio-stop-all
                $ jps -lm 
                $ # check for orphaned HMaster or HReagionServer or 
                $ # non-eventserver Console and kill separately to get a clean state
                $ kill some-pid

 - install pip to import data to the EventServe

		$ sudo apt-get install python-pip
		$ sudo pip install predictionio
		$ sudo pip install datetime
		
 - get the Universal Recommender

                $ git clone https://github.com/actionml/template-scala-parallel-universal-recommendation/tree/v0.3.0 universal
                $ cd universal
                $ pio app list # to see datasets in teh EventServer
                $ pio app new handmade # if the app is not there
                $ python examples/import_handmade.py --access_key key-from-app-list

 - to retrain after any change to data or engin.json
 - 
                $ pio build # do this before every train
                $ pio train -- --master spark://some-master:7077 --driver-memory 3g

 - to retrain after a pio config change first restart pio as above, them retrain, no need to reimport unless you have rebuild HBase, in which case start from "start platform services" above.

