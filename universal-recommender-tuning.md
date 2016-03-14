#Universal Recommender Tuning
The default settings of the UR are good for many purposes but getting optimum results may require tuning and at very least many users will wish to know the meaning of the various tuning params.

##UR Parameters
Let's start with the full parameter set for the training and query. Together they have all the accessible tuning parameters.

###Complete Parameter Set

A full list of tuning and config parameters is below. See the field description for specific meaning. Some of the parameters work as defaults values for every query and can be overridden or added to in the query. 

**Note:** It is strongly advised that you try the default/simple settings first before changing them. The exception is that at least one event name must be put in the  `eventNames` array and the path to the Elasticsearch index must be specified in `indexName`, and `typeName`. 

    {
      "id": "default",
      "description": "Default settings",
      "comment": "replace this with your JVM package prefix, like org.apache",
      "engineFactory": "org.template.RecommendationEngine",
      "datasource": {
        "params" : {
          "name": "some-data",
          "appName": "URApp1",
          "eventNames": ["buy", "view"]
        }
      },
      “comment”: “This is for Mahout and Elasticsearch, the values are minimums and should not be removed”,
      "sparkConf": {
        "spark.serializer": "org.apache.spark.serializer.KryoSerializer",
        "spark.kryo.registrator": "org.apache.mahout.sparkbindings.io.MahoutKryoRegistrator",
        "spark.kryo.referenceTracking": "false",
        "spark.kryoserializer.buffer.mb": "200",
        "spark.executor.memory": "4g",
        "es.index.auto.create": "true"
      },
      "algorithms": [
        {
          "name": "ur",
          "params": {
            "appName": "URApp1",
            "indexName": "urindex",
            "typeName": "items",
            "eventNames": ["buy", "view"]
            "blacklistEvents": ["buy", "view"],
            "maxEventsPerEventType": 500,
            "maxCorrelatorsPerEventType": 50,
            "maxQueryEvents": 100,
            "num": 20,
            "seed": 3,
            "recsModel": "all",
			"backfillField": {
				"name": "popRank"
  				"backfillType": "popular",
  				"eventNames": ["buy", "view"],
  				"duration": 259200,
  				"endDate": "ISO8601-date" //most recent date to end the duration
  			},
            "expireDateName": "expireDateFieldName",
            "availableDateName": "availableDateFieldName",
            "dateName": "dateFieldName",
            "userbias": -maxFloat..maxFloat,
            "itembias": -maxFloat..maxFloat,
            "returnSelf": true | false,
            “fields”: [
              {
                “name”: ”fieldname”,
                “values”: [“fieldValue1”, ...],
                “bias”: -maxFloat..maxFloat,
              },...
            ]
          }
        }
      ]
    }

###Complete Query Parameters

	{
	  “user”: “xyz”, 
	  “userBias”: -maxFloat..maxFloat,
	  “item”: “53454543513”, 
	  “itemBias”: -maxFloat..maxFloat,  
	  “num”: 4,
	  "fields”: [
	    {
	      “name”: ”fieldname”
	      “values”: [“fieldValue1”, ...],
	      “bias”: -maxFloat..maxFloat 
	    },...
	  ]
	  "dateRange": {
	    "name": "dateFieldname",
	    "beforeDate": "2015-09-15T11:28:45.114-07:00",
	    "afterDate": "2015-08-15T11:28:45.114-07:00"
	  },
	  "currentDate": "2015-08-15T11:28:45.114-07:00",
	  “blacklistItems”: [“itemId1”, “itemId2”, ...]
	  "returnSelf": true | false,
	}

##Tuning For Recency of User Intent

For cases with lots of usage data, so > 10 primary event per user, if may be beneficial to use only then most recent events for returning recommendations. The thinking behind this is that the most recent history is a better indicator of what is on the user's mind, what they are currently interested in. To do this change `maxQueryEvents` to a smaller number than the average for the entire data set. So if the average for all users is 20 primary events/user you may want to try `""maxQueryEvents": 10". This will use the 10 most recent events to return recommendations. It is still desirable to have  the full dataset used in training to model and this param doe not affect training. 

##Better Model at the Expense of Training/Query Time

At the core of the Universal Recommender is the "Correlated Cross-Occurrence" algorithm, which creates the model used in making recommendations. The more data you include, the better the model will work but this is true with rapidly diminishing returns. One study of this effect was done by one of the CCO creators [here](https://ssc.io/pdf/rec11-schelter.pdf). This leads us to limit the actual data used to calculate the CCO model by downsampling. This will produce slightly worse results but keep the training time O(n) where n is the number of downsampled interactions used. 

Tom effectively disable downsampling change `"maxEventsPerEventType": 500` to some very large integer to get all data into the model calculation and `"maxCorrelatorsPerEventType": 50,` to a likewise large number to increase the number stored in the model. Increasing `"maxEventsPerEventType"` will make training slower and increasing `"maxCorrelatorsPerEventType"` will make search engine indexing and queries slower.

If training and query times are not a factor these can safely be increased with little chance of other bad side effects.

##Blacklist

The default `"blacklistEvents"` in the **engine parameters** is the single primary event. This means that if the user took the primary event on an item it will not be returned in recommendations. This is often the right thing to do but there are exceptions.

In some cases an item may be consumed periodically like Clothing, or Food so reminding a user that they like an item may be good. To disable the blacklist set the following `"blacklistEvents": []`, which means to return all recommendations without restriction. 

It is possible with this setting to get only things the user is already familiar with. Disabling the blacklist may not be the best way to handle this. For instance lets say you have 10 recommendations to show; it might be better to get 9 recommendations (with the blacklist) and put in one item you already know the user prefers from your own data. Any mixing of items the user is familiar with and recommendations can be done as part of the application logic, not implemented by the recommender.

In other cases you may want to be more restrictive and use more than the primary event  to filter out items from recs. Setting to `"blacklistEvents": ["buy", "view"]` is a good example, where anything the use bought or any item detail page the user viewed will not be returned as recommendations.

##Anti Flood

Another case for removing items fro recommendations can be seen from looking at a web page with lots of recommendations in different categories. Think of the Netflix Web UI. If we were to show "your recommendations", and "recommended for you in SciFi", and so on, there is a chance that we will show the same items over and over, effectively waisting screen real-estate. In this case it may be better to avoid repeating recommendations, which would "flood" the page with duplicates. To do this, a list of blacklisted items can be passed in to the query and works only for that query.

For example you might get "your recommendations", then when you ask for "recommended for you in SciFi" you might pass in a blacklist if each item returned in "your recommendations" so as to avoid any duplicates. The **query** parameter to add is `"blacklistItems": ["array", "of", "item-ids"]`

##Mixing Item-similarity and User Recommendations

When showing an item, such as when you are on a detail page of an e-com site, it is common to show "similar items" otherwise know as "people who bought this also bought these". This works for completely anonymous users with no history. But in cases where you do know user history you might want to show personalized recommendations. In fact you might want to show personalized except when you have no user history. It is possible to mix items from both recommendation types by simply passing in a user-id and an item-id to the query. To favor user-based personal recommendations set the **query** param `“itemBias”` to something between 1 and 0, which will disfavor item recommendations. If there are no user recommendations because you have no history for the user then item-similarity based recs will be returned as fallback, and if neither is available popular items will be returned. Likewise if you want to favor item recommendations set `“itemBias”` to something larger than 1. This will boost items-similarity recommendations higher than user-based ones.

##Randomization
Although this is not yet implemented in the UR it is always a good idea to randomize the ranking of recommendations to some small extent. This can be done by returning 40 recs and adding normally distributed random noise to the ranking number then re-ranking by the result. This will make the 40th recommendation sometimes become the 19th (for example) and if you are showing 20 it means that they 40th recommendation will sometimes get a chance at being recommended. If the user picks it, this will be fed back into the next training session and will improve the trained model. If the user doesn't pick it the ranking will not be increased. This technique turns a recommender in to a giant array of "multi-armed-bandits" that show somewhat randomly sampled items and learn which to favor. This is a very important technique for improving recommendations over time and should not be discounted as a fringe method. This should  always be done for all recommender implementations and will be incorporated into the UR in the Universal Recommender v0.4.0 release.

##Controlling The Popularity Model

The UR allows all items to be ranked by one of several popularity metrics. The need to rank all items is so popularity will work for all forms of property based boosts and filters. This makes the calculation a fairly heavy weight thing that must be done at training time, not at query time. In other words the popularity ranking is pre-calculated by the time the query is made. It is possible to train on all data at one rate (daily, weekly?) and re-train the popularity model alone on a much more frequent rate (hourly?) if needed. This is to account for rapid recent changes in popularity.

**The Popularity Algorithm Parameters**  

    "recsModel": "all",
    "backfillField": {
        "name": "popRank" // field name for the property to attache to items
        "backfillType": "popular", // type of metric
        "eventNames": ["buy", "view"], // events to count
        "duration": 259200, // last number of seconds of data to use in calculation
        "endDate": "ISO8601-date" //most recent date to end the duration
    },
    
**Long Term Popularity**

The `"recsModel"` defaults to `"all"` which means both CCO based recommendations and the type of popularity defined in `"backfillField"`. The `"backfillField"` defaults to ranking all items by the count of primary indicators/event for all time in the training data. This calculates popularity over the long term.

**Update the Popularity Model only**

If you need to update the popularity model only rather than all CCO model data, set `"recsModel"` to `"backfill"`. This means that only the `"backfillField"` will be updated in the currently deployed model. To calculate the normal combined model daily and the `"backfillField"` hourly  you would have one engine.json for daily use and one set for `"recsModel": "backfill"` for hourly training. This type of training is much faster than full model calculation and so better suite to quicker updates.

**Short Term Popularity**

May applications call for items that were popular in the last period, in this case if the period is an hour set the `"duration": 3600` which is the number of seconds in an hour.

**Finding Trending Items**

The `"backfillType": "popular"` means to simply count events for all items from "now" to the `"duration"` number of seconds into the past. A more sophisticated metric might be how quickly the rate of new events is increasing. This is the change in event count/change in time, which can be thought of as the velocity of events for all times. If some items has a rapidly increasing number of events over the last period of time it is said to be "trending". To calculate a **trending** popularity model change to `"backfillType": "trending"`. This will divide the `"duration"` in 2 and calculate the rate of event increase in event for all items.

**Finding Hot Items**

Taking the trending idea one step further the UR also supports `"backfillType": "hot"`, which calculates how quickly trending items are moving up the list. Think of **hot** and being a measure of acceleration. It catches items that may not be globally popular yet but that are quickly moving up, as then items are said to "go viral".

 
#Picking the Best Tuning Parameters
Several of the methods mentioned above can be tested with cross-validation tests but others cannot. For instance increasing data used in training or queries will almost always increase cross-validation test results but randomizations will almost always decrease scores. tuning for recency will also decrease cross-validation results. Unfortunately some of these results are known to be contrary to real-world results from something that trumps offline cross-validation tests&mdash;A/B tests. 

##Finding the Strongest User Indicators

A great many different things known about the user may reflect on their taste. We have discussed the e-com "buy" and "view" indicators for example. But we don't have to stop there, maybe we know the manufacturer of a purchase, the category of purchase, the search terms the user entered, their gender or location. Intuitively these seem to be possible preference indicators but they also are not likely to be as strong as "buy". 

There may even be cases where we know things that could be considered candidates for the primary indicator/event&mdash;for instance in video recommenders is it better to use the fact that the user started a video, watched 20% of a video or 90%? In point of fact we have seen cases where for a given dataset each of these was strongest and by a significant margin. This is a great case where we use cross-validation testing.

##MAP@k
To determine this we start with a tool for measuring the relative predictive strength of a given indicator type. This, relies on cross-validation tests. Some of the tuning examples above can also be tested this way but others cannot. For instance Randomization will always give lower MAP@k results but is also universally good when measuring using with A/B testing. That said MAP@k is a good way to test predictive strength of indicator types. See MAP@k testing for a discussion of this testing technique.








