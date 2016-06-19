# THESE DOCS ARE DEPRECATED SEE [ActionML.com/docs](actionml.com/docs)

The Guides are moved

The markdown templates are now in https://github.com/actionml/docs.actionml.com. Changes there are automatically published to the live site: actionml.com/docs. Please make any PRs to that new repos.


# Depredated ActionML Documentation
 
ActionML maintains a fork of PredictionIO beginning with v0.9.6. We also invented and maintain several templates including the Universal Recommender. This is the github version of our documentation also found on [ActionML.com](http://actionml.com/docs).

## Some Setup How-tos:

 - [Setup, installing services on 1 standalone machine](https://github.com/actionml/cluster-setup/blob/master/single-driver-machine.md) Not recommended except for very small datasets on a development machine or as a first step towards a distributed Spark setup.
 - [Setup, installing services on 3 clustered machines](https://github.com/actionml/cluster-setup/blob/master/minimum-cluster-setup.md) Good for a dev/experimental setup with small-ish datasets.
 - [Setup for a fully distributed cluster](https://github.com/actionml/cluster-setup/blob/master/distributed-cluster-setup-guide.md) The ultimate in scalability with all services split out in their own clusters for independent scaling and maintenance. For very high load and large datasets or for multi-tenancy. 
 - [Scaling beyond the 3-machine setup](https://github.com/actionml/cluster-setup/blob/master/architecture-and-scaling.md) Issues around horizontal scaling of PIO.
 - [Distributed Services Setup](https://github.com/actionml/cluster-setup/blob/master/distributed-cluster-setup-guide.md) The minimum needed to split EventServers from PredictionServers and run with completely separate component services like Spark and Elasticsearch.
 
## Install and Run PredictionIO
 
 - [Installing ActionML's PredictionIO v0.9.6](https://github.com/actionml/cluster-setup/blob/master/install.md) This is required for ActionML templates including the Universal Recommender
 - [Starting and stopping a cluster](https://github.com/actionml/cluster-setup/blob/master/start-stop-cluster.md) What you need to do to manually start and stop a fully distributed cluster
 - [PIO Command Line Interface Cheatsheet](https://github.com/actionml/cluster-setup/blob/master/predictionio-cli-cheatsheet.md)

## The Universal Recommender

 - [The Universal Recommender](https://github.com/actionml/template-scala-parallel-universal-recommendation)
 - [Tuning the Universal Recommender](https://github.com/actionml/cluster-setup/blob/master/universal-recommender-tuning.md)
