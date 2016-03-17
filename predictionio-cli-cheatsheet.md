#PredictionIO CLI Cheatsheet

PredictionIO can be seen as 2 types of servers, one takes in and stores events&mdash;the EvnetServer&mdash;and the other serves prediction&mdash;the PredictionServer. The general non-template specific commands can be run from anywhere, in any directory but the template specific commands must be run in the directory of the specific engine-instance being used, this is because some commands rely on files (like engine.json) to be available.

#General Commands
At any point you can run `pio help <some-command> to get a help screen printed with all supported options for a command.

##Start/stop

 - `pio-start-all` this can only be used reliably on a single server setup with all services on a single machine.
 - `pio-stop-all` likewise this is only for a single machine setup.
 - `pio eventserver` this starts an EventServer on port 7070 of localhost
 - `nohup pio eventserver &` this creates an EventServer as a daemon, other daemon creation commands work too, like `screen`.
 
##Status and Information

 - `pio status` this checks the config of PredictionIO and connects to the databased used, it does not connect to Spark or check the status of things like HDFS.
 - `pio app list` list information about apps the systems knows about, this is used primarily to see which collections of data are registered with the EventServer.
 - `pio app new <appname>` this creates an empty collection and a key that can be used to send events to the EventServer.
 - `pio app delete <appname>` remove app and all data from the EventServer
 - `pio app datadelete <appname>

#Workflow Commands

For some pio commands you must `cd` to an engine-instance directory. This is because the `engine.json` and/or `manifest.json` are either needed or are modified. These commands implement the workflow for creating a "model" from events and launching the PreditionServer to serve queries.

##Standard Workflow
These commands must be run in this order, but can be repeated once previous commands are run. So many trains are expected after a build and many deploys of the same model are allowed.

 - `pio build` this registers the `engine.json` params with the meta-store as defined in the `pio-env.sh`, it also uses sbt to compile and create jars from the engine code. Any change to `engine.json` will only take effect after `pio build` even if the code has not changed.
 - `pio train` pulls data from the event store and creates a model
 - `pio deploy` creates a PredictionServer instance to serve query results based on the last trained model
 - `nohup pio deploy &` creates a daemon of the PredictionServer for the current engine-instance
 
##Multi-tenant Workflow

This workflow is intended for Users of the Universal Recommender only or Templates that do not require a Spark context to run (like the UR). This is currently only implemented in the Enterprise version of PredictionIO. Email support@actionml.com for details.

This workflow allows for deployment of code to PredictionServers without running `pio build`, it also allows many models to be served from a single server by using dynamic REST resource routing to address the correct tenant.

 - `pio build` if you wish to create your own jars this will do it.
 - `cp target/scala_2.10/temp* /path/to/pio/plugins/` you may have to create the plugins directory first inside the primary PredictionIO directory.

At this point you can create an app, train, and deploy in any order, there is no need to build again but you must deploy to get any changes to `engine.json` into the global meta-store.

 - `pio deploy --resource-id <some-resource-id>` this will launch a PredictionServer if one is not already running, it will insert the engine-instance classes to respond to queries. The last deployed model is available at `GET http://<some-prediction-server>:8000/queries.json` where the payload is a template query. A query after deploy may return nothing if there is no model but will not return an error.
 - `pio train` this will work much as in the standard workflow but may be before or after `pio deploy`
 

 

 