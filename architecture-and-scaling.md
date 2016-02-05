# Architecture and Scaling

This doc has described setting up pio + the Universal Recommender on 3 machines, where all clustered services are run alike on all machines.

For most higher load production installations you will need to separate clustered services to avoid contention for resources like cores and memory. This is the case where you will use some machines to run PredictonIO EventServers and the Universal Recommender PredictionServers. You will also likely want to create a separate Elasticsearch cluster, HBase+HDFS cluster, and a Spark cluster.

Not all of these must be separate, obviously but there are a couple bottleneck that should be noted. 

##Load Optimizations Rules

For specific types of load the following rules of thumb apply:

- **Heavy Input Loads** a separate cluster of HDFS + HBase would be desirable. The EventServer is used at all phases, at event input, during train, and is queried in real-time by the deployed Universal Recommender PredictionServer. The EventSever is built on top of HBase so optimizing its execution speed can effect all aspects of performance.
- **Training Speed**, make sure the EventServer is fast, then make sure Spark is fast. This may mean creating a separate Spark cluster. Different templates use Spark in different ways. For the Universal Recommender it is most important to have memory per executor/driver than it is to have more executors. You may even want to limit executors so you can give each more memory. Another way to say this is that CPU load tends to be small so IO is usually the bottleneck.
- **High Query Load**, make sure the EventServer is fast, then create more PredictionServers and for the Universal Recommender optimize Elasticsearch. This can be done by having a separate Elasticsearch cluster and the more memory you can give Elasticsearch the better the speed.
- **Scaling Services Separately** For very high demand applications or suites of applications we would make all clustered services scale independently. This means creating separate HBase, HDFS, Elasticsearch, and Spark clusters. Amazon and Rackspace have elastic HBase+HDFS+Spark clusters that can be dynamically expanded or collapsed. Unfortunately the version of Hbase on AWS EMR is ancient (0.94.x) which is not supported by PredictionIO so feel free to call Amazon and remind them that time has moved on and they are left behind :-) In any case there are some people who can afford internal Cloudera, Horton, of MapR clusters with a newer compatible stack of services. We will describe how to setup PredictionServers and EventServers separate of the other clustered services.

First note that PredictionIO saves no state itself (it is "stateless" in engineer-speak) but uses clustered services&mdash;simply put, scaling the services scales PredictionIO. This design means that EventServers and PredictionServers are completely independent. They do not cooperate outside of the well documented clustered services in the tech stack. However this independence means there is no load balancing built into PredictionIO. 

If you were to launch the PIO EventServer or PredictionServer on 10 machines and 2 go down, the rest of the servers will continue to respond as long as the clustered services operate. To spread load into the system we use a load-balancer. This will account for machines going down and will make sure no server is overloaded.

##Logical Architecture and Data Flow

The internal architecture of PredictionIO and the data flow for **all** use modes is shown below.

![image](https://docs.google.com/drawings/d/1Uz2STgGUiBh_7Lv9iWB2EtEyiQta4ySegCevbbr-xR0/pub?w=960&h=720)

To Illustrate how this flow changes we'll look at each stage separately, they are:

- Event input to the EventServer
- Training a model
- Queries to a PredictionServer
- Bootstrap importing batch data and exporting backups

###Live Event Input

This is the typical input mode of the system where clients or web app backends are feeding new data to the running system. This data is used by the Universal Recommender in realtime though it requires a `pio train` to reflect new items or property changes. For the case where new users are sending new events, the UR will make recommendations in realtime that use the new user data.

![image](https://docs.google.com/drawings/d/1wjv1ouKzQwTHXyz_j1iWez6Jm_AQJf5QZE9NwLLjatk/pub?w=960&h=720)

###Training a Model

In Data-Science jargon the Universal Recommender creates a new model from the EventServer's data taken as a whole every time `pio train` is called. As a rule of thumb it's best to re-train when new items are added to the data. It's not as important to do so with new user data, even adding new users. The recommender cannot recommend items that is hasn't seem in training data.

In this mode a background batch operation is performed and, when it's done, the new model is hot-swapped into any running PredictionServers. So no re-deployment is necessary to update a running UR.

![image](https://docs.google.com/drawings/d/1Xmr7xZO485md6LuLWmRpSrtATdDlzaIEjPLeBS9FK5M/pub?w=960&h=720)

###Queries

Once we have trained the UR and stored a model in Elasticsearch queries will produce results. Each query from the client application results in 2 internal queries one to the EventServer to get user history events, and one to Elasticsearch that is created (partially) from the user history and partly from the client app query. So if a query only passes in a user-id, the user history is retrieved from the EventServer and this forms most of Elasticsearch query. Only one query is made to Elasticsearch with all params needed. Once Elasticsearch returns items they are passed back to the client application.

![image](https://docs.google.com/drawings/d/14NpiG0Tz8AXOrNLSHAfxvQRHKXz2Wzdtpoep1jAQcfc/pub?w=960&h=720)

###Bootstrapping Batch Import

On-boarding new data can be accomplished by creating json event files. These are a slightly illegal form of json that is directly supported by Spark. Each event is encoded in a json object&mdash;one per line. Normally json would require this to be in an array but Spark requires that each line contain the object so lines can be read in parallel by all Spark executors. The json can be created of the same form that is exported from the EventServer as a backup. So it you have used one of the Universal Recommender integration tests like `examples/integration-test` you will have example data in the EventServer. Issue a `pio export ...` command to see the format. You don't have to create the event id or `creationDate` but you should create the `eventDate` if possible.

Alternatively you can use an SDK or the REST API to send events to the running EventServer, just as you would with the live event stream. In this case the Events do not come from files.

![image](https://docs.google.com/drawings/d/1yFBmuPFSgivTYzFwReyrurxPbVIkTyv68rGnRrSLCFk/pub?w=960&h=720)

##Special Scaling Rules

The Universal Recommender we need enough memory for all user and item ids to be stored in memory in the form a bi-directional hashmap. This will be proportional to the collection of all id strings but given the overhead of JVM strings, and BiMaps it will actually need something on the order of 4X the size of all strings. This is the first scaling need you are likely to run into.