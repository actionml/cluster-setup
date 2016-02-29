#Distributed Cluster Setup Guide

###Spark Standalone Cluster (No Yarn)

One of the first things needed to scale to indefinite dataset size is a distributed Spark cluster of the type supported by Amazon AWS-EMR. Or even a home-grown cluster using one of the big distros like Cloudera, MapR, or Horton Works. This requires the cluster to be setup and running with a master. 

In order to run the UR and pio with a remote spark cluster some conditions should be met:

0. All machines should know the hostnames of each other since hostnames are used in configuration. Names can be assigned by LAN/VPN DNS or by adding names to `/etc/hosts` for **all** machines.

1. The pio machine(s) should be visible to spark workers and should have spark driver ports accessible if they are running a driver like `pio train` (see [Spark security page](http://spark.apache.org/docs/latest/security.html#configuring-ports-for-network-security) for details), so `spark.driver.port`, `spark.fileserver.port`, `spark.broadcast.port`, `spark.replClassServer.port` and `spark.blockManager.port` should be accessible for connection from the Spark workers. All these ports may be fixed and specified in `$SPARK_HOME/conf/spark-defaults.conf` (all spark machines and driver)

2. Remote spark workers should also be able to access HBase (see [Hbase service ports](https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_HDP_Reference_Guide/content/hbase-ports.html)) and in some cases Elasticsearch cluster hosts (9200, 9300)

3. Remote Spark workers must have access to HDFS (if training data are in hdfs) should be also available to workers  

4. in addition correct Elasticsearch nodes should be specified in `engine.json`

A "driver" process runs on the machine where SparkSubmit is used or the `pio train` process is launched. This driver needs to know the remote "master" on one of several ways, the command line is the most obvious and takes precedence over other config. To specify the master issue the `pio train` command with the following form 

    pio train -- --master spark://some-spark-master-hostname

Notice the use of the `spark://` protocol identifier. Further each job will need to know how to connect to the "driver" machine. The easiest way to do this is using the `engine.json` `sparkConf` params. You will also need to connect from Spark execitors to Elasticsearch using both the TransportClient and the REST API. The driver, and Elasticsearch REST connection can be specified in the same place like this:

```
"sparkConf": {
    ...
    "es.nodes": "<es-node-1>,<es-node-2>,<es-node-3>",
    "spark.driver.host": "<pio-machine-address>"

  },
```




