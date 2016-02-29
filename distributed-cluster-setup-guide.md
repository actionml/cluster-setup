#Distributed Cluster Setup Guide

##Connecting to a Remote Spark Cluster

One of the first things needed to scale to indefinite dataset size is a distributed Spark cluster of the type supported by Amazon AWS-EMR. Or even a home-grown cluster using one of the big distros like Cloudera, MapR, or Horton Works. This requires the cluster to be setup and running with a master. 

###Standalone Spark (No Yarn)

A "driver" process runs on the machine where SparkSubmit is used or the `pio train` process is launched. This driver needs to know the remote "master" on one of several ways, the command line is the most obvious and takes precedence over other config. To specify the master issue the `pio train` command with the following form 

    pio train -- --master spark://some-spark-master-hostname

Notice the use of the `spark://` protocol identifier. Further each job will need to know how to connect to the "driver" machine. The easiest way to do this is using the `engine.json` `sparkConf` params. You will also need to connect from Spark execitors to Elasticsearch using both the TransportClient and the REST API. The driver, and Elasticsearch REST connection can be specified in the same place like this:

    Alexey, can you fill this in for Elasticsearch and driver?
