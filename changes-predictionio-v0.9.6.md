# THESE DOCS ARE DEPRECATED SEE [ActionML.com/docs](actionml.com/docs)

The Guides are moved

The markdown templates are now in https://github.com/actionml/docs.actionml.com. Changes there are automatically published to the live site: actionml.com/docs. Please make any PRs to that new repos.

# ActionML's Version of PredictionIO v0.9.6

ActionML maintains a forked version of PredictionIO starting with v0.9.6. The key changes from v0.9.5 are:

## SelfCleaningDataSource

The most important new feature in ActionML's version of PredictionIO v0.9.6 is the `SelfCleaningDataSource`. This allows any template to specify an age for events. When events get too old they are removed permanently from the EventServer. It also allows a template to de-duplicate events, and to compact $set/$unset property change events.

The `SelfCleaningDataSource` has been added to the Universal Recommender template [here](https://github.com/actionml/template-scala-parallel-universal-recommendation). To add this feature to any template simple inherit `SelfCleaningDataSource` from your DataSource as is done in the UR [here](https://github.com/actionml/template-scala-parallel-universal-recommendation/blob/v0.3.0/src/main/scala/DataSource.scala#L49).

### Template Code Change

Find the DataSource class in your template code and add the `with` clause like this:

	class DataSource(val dsp: DataSourceParams)
	  extends PDataSource[TrainingData, EmptyEvaluationInfo, Query, EmptyActualResult] 
	  with SelfCleaningDataSource {
	
	  @transient override lazy val logger = Logger[this.type]
	
	  override def appName = dsp.appName
	  override def eventWindow = dsp.eventWindow
	  
	  ...
	}
  
the `appName` and `eventWindow` are defined and used in the `SelfCleaningDataSource`

### Parameters

Then configure the DataSource operation in engine.json as follows:

	  "datasource": {
	    "params" : {
	      "name": "sample-handmade-data.txt",
	      "appName": "handmade",
	      "eventNames": ["purchase", "view"]
	    }
	  }

 - **eventWindow**: This is optional and controls how much of the data in the EventServer to keep and how to compress events. The default it to not have a time window and do no compression. This will compact and drop old events from the EventServer permanently in the persisted data&mdash;so make sure to have some other archive of events it you are playing with the `timeWindow: duration:`.
	 - **duration**: This is parsed for "days", "hours", "minutes", or smaller periods and becomes a Scala `Duration` object defining the time from now backward to the point where older events will be dropped. $set property change events are never dropped.
	 - **removeDuplicates** a boolean telling the DataSource to de-duplicate events, defaults to `false`.
	 - **compressProperties**: a boolean telling the Datasource to compress property change events into one event expressing the current state of all properties, defaults to `false`.
