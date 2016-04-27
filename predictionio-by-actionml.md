# PredictionIO by ActionML

For various reasons ActionML has forked the PredictionIO project and maintains it's own repo. Unfortunately we released v0.9.6 of the project 3 weeks before Salesforce also released the same version. We are working to resolve this split and in the near future will at least rename out releases so they won't have colliding artifact names.

For ActionML's PredictionIO v0.9.6 please follow [these instructions](https://github.com/actionml/cluster-setup/blob/master/install.md) to install or upgrade. 

## ActionML's PredictionIO v0.9.6

 - Implements the `SelfCleaningDataSource` for the EventStore. This allows any template to specify a moving window of events in time, enable de-duplication of events, and compact $set/$unset property change events (see description below)
 - Implements `NullModel` for templates that do not store models in existing PIO data stores. The Universal Recommender requires this feature since it stores models in Elasticsearch.
 - Does not implement SSL/HTTPS and so operates with all existing SDKs
 - Requires Java 7, but works with Java 8


## Salesforce's PredictionIO v0.9.6

 - Requires java 8
 - Require SSL/HTTPS for pio REST APIs. This make it incompatible with existing code that queries or sends events to the EventServer. It also makes it incompatible with the SDKs which will not operate with this version without changes.

## Use the [Salesforce Sponsored PredicitonIO v0.9.6](https://github.com/PredictionIO/PredictionIO)

- you need SSL/HTTPS **and** 
- you do not need The Universal Recommender v0.3.0+ **and** 
- you do not use an SDK or are willing to modify the SDK code, use the Salesforce sponsored project on [github](https://github.com/PredictionIO/PredictionIO)

## Use [ActionML's PredictionIO v0.9.6](https://github.com/actionml/cluster-setup/blob/master/install.md)

- you don't want SSL/HTTPS **or** 
- you want [The Universal Recommender](template-scala-parallel-universal-recommendation) v0.3.0+ **or** 
- you want to use the new [SelfCleaningDataSource](https://github.com/actionml/cluster-setup/blob/master/changes-predictionio-v0.9.6.md) 

Installation instructions [here](https://github.com/actionml/cluster-setup/blob/master/install.md).

**Note**: ActionML maintains a merged version for people who need SSL and other features of the ActionML v0.9.6 in a branch so contact ActionML on our [Google Group](https://groups.google.com/forum/#!forum/actionml-user) or email [support@actionml.com](mailto:support@actionml.com?subject=Need SSL/HTTPS Version of ActionML's PredictionIO v0.9.6) for instructions.

