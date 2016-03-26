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

**Important Note:** use standard **or** multi-tenant workflow, not both mixed! If you mix these things will get out of sync for the engine-instance. Reset things by deleting 'manifest.json' and sticking to one or the other. 

##Standard Workflow
These commands must be run in this order, but can be repeated once previous commands are run. So many trains are expected after a build and many deploys of the same model are allowed.

 - `pio build` this registers the `engine.json` params with the meta-store as defined in the `pio-env.sh`, it also uses sbt to compile and create jars from the engine code. Any change to `engine.json` will only take effect after `pio build` even if the code has not changed.
 - `pio train` pulls data from the event store and creates a model
 - `pio deploy` creates a PredictionServer instance to serve query results based on the last trained model
 - `nohup pio deploy &` creates a daemon of the PredictionServer for the current engine-instance
 
##Multi-tenant Workflow

This workflow is intended for Users of the Universal Recommender only or Templates that do not require a Spark context to run (like the UR). This is currently only implemented in the Enterprise version of PredictionIO. Email [support@actionml.com](mailto:support@actionml.com) for details.

This workflow allows for deployment of code to PredictionServers without running `pio build`, it also allows many models to be served from a single server by using dynamic REST resource routing to address the correct tenant.

 - `pio build` if you wish to create your own jars this will do it. This is not necessary since the jar is published and should **never** be done for an engine-instance that you with to use for data. Do this only once and only to create jars.
 - `cp target/scala_2.10/temp* /path/to/pio/plugins/` you may have to create the plugins directory first inside the primary PredictionIO directory.n This must be done on all PredictionSever machines.

At this point you can create an app, engine-instance, deploy, and train **in that order**, there is no need to build again but you must deploy to get any changes to `engine.json` into the global meta-store.

 - `pio deploy --resource-id <some-resource-id>` this will launch a PredictionServer if one is not already running, it will insert the engine-instance classes to respond to queries. This must be done on all PredictionServers.
 - `pio train` (re)trains and attaches the model to any deployed instances--this is done on one machine.

##Multi-tenant Query

Once the multi-tenant version of pio is installed, you can follow the old workflow, but the resource-id for queries is auto-generated and put in `manifest.json` as the `"id":`. Or you can follow the new workflow with deploy before train, where you supply a resource-id on the CLI. In either case use a query with the resource-id just after the PredictionServer address, for example:

	curl -H "Content-Type: application/json" -d '
	{
	    "user": "some-user-id"
	}' http://some-prediction-server:8000/tenant-1/queries.json
	
This assumes the following had been done:

	cd path/to/engine
	# just to be safe, an auto-generated manifest is bad here
	rm manifest.json 
	# this creates a manifest.json and deploys the PredictionServer
	pio deploy --resource-id tenant-1 
	# this will connect the newly created model with the deployed PredictionServer
	pio train 

 

 