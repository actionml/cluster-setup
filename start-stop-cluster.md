#Start and Stop a PredictionIO Cluster

There are several Services that together are needed to run PredictionIO and the Universal Recommender. It is important that these be started and stopped in the right order. If you used the action(ML) cluster setup guide then the instructions below will apply verbatim, if you setup you own clustered environment you may need to substitute the right paths but the order of commands will be the same.

##Startup
Assume all servers are rebooted and running linux with no additional processes running. Assume the entire cluster is being restarted. This does not describe how to restart a single node so that it rejoins the cluster without disruption, which is beyond the scope of this doc. Each of the services is capable of doing this but uses a different mechanism. Elasticsearch, for instance, can just be restarted on each node and will automatically recontact the other cluster members and rejoin them. Hadoop and Spark on the other hand are often started or stopped from the master, though the slaves can also be started separately.

To start PIO and the Universal Recommender it is assumed you installed all services to be owned by the user `pio`

 1. Login to the master server as pio with something like ssh.
 1. Start Hadoop, this will start hadoop on the entire cluster

	    $ /usr/local/hadoop/sbin/start-dfs.sh
 
 1. Start Spark, this will restart the entire cluster

	    $ /usr/local/spark/.../sbin/start-all.sh
 
 1. Start HBase, this restarts the entire cluster
 
	    $ /usr/local/hbase/bin/start-hbase.sh
 
 1. The following step is repeated on every Elasticsearch node. All Elasticsearch servers need to be started to restore index replication, and cluster operations before pio commands can be executed.

	    $ /usr/local/elasticsearch/bin/elasticsearch -d &

 1. Start PIO EventServer, which depends on Hadoop HDFS and Elasticsearch, this should be started on every cluster machine that will be load balanced for incoming events to the EventServer

	    $ pio eventserver
 1. To check that all is well with PredictionIO and the EventServer perform this check.
 
 		$ pio status 
 
 1. Build, train, deploy the Universal Recommender. Repeat only “pio deploy” on all server that will have load balanced query servers 

	    $ cd /home/pio/universal # or wherever the correct engine.json is
	    $ pio build # only if new config or code version needs to be updated
	    $ pio train # only if the model is to be updated
	    
	Deploy should be run as a daemon using nohup or similar tool but can also be run interactively in a tool like screen or a separate shell
	    
	    $ pio deploy
	
	Or to use nohup for `pio deploy` do something like:

	    $ nohup pio deploy > /path/to/deploy/log &
    
##Shutdown

Shutdown is in the opposite order of startup but if the startup is automated then a reboot should be safe. To shutdown by hand so that all services can be restarted perform the following:

 1. Login as the pio user
 1. Find the “pio deploy” process with 

	    $ ps -aux | grep deploy
	    $ kill <deploy-pid>

 1. Find the EventServer process with 

	    $ ps -aux | grep eventserver
	    $ kill <eventserver-pid>
    
 1. **Note:** This needs to be done on all machines that run Elasticsearch. Find Elasticsearch server process with:
 
	    $ ps -aux | grep lasticsearch
	    $ kill <elasticsearch-pid>

 1. Shutdown HBase

	    $ /usr/local/hbase/bin/stop-hbase.sh

 1. Shutdown Spark

	    $ /usr/local/sbin/stop-all.sh

 1. Shutdown Hadoop HDFS

	    $ /usr/local/hadoop/sbin/stop-dfs.sh

##Reboot

To be added...


