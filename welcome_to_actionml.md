# THESE DOCS ARE DEPRECATED SEE [ActionML.com/docs](actionml.com/docs)

The Guides are moved

The markdown templates are now in https://github.com/actionml/docs.actionml.com. Changes there are automatically published to the live site: actionml.com/docs. Please make any PRs to that new repos.

# Welcome to ActionML

We help people build Machine learning into their Apps. We create, the systems, algorithms, and infrastructure to make machine intelligence practical. We help customize or invent what is needed then we maintain open source implementations of it all. Try it and if you need help [contact us](/#contact) us or ask for [community support](https://groups.google.com/forum/#!forum/actionml-user) 

## Algorithms

 - **The Universal Recommender**: Perhaps the most flexible recommender in open source. Implemented as a complete end-to-end integrated system that you can run on premises or we can run it for you. The Universal Recommender contains a new Correlation Engine approach to ingesting data from many sources to make recommendations better. See the description [here](/docs/universal-recommender)
 
 - **The Page Variant Recommender**: Based on a Contextual Multi-armed Bandit, this algorithm allows you to instrument a site or mobile app to evolve into something pleasing to specific users. Pick a set of pages and the PVR finds which versions cause the best response to which users types. [Contact us](/#contact) if you are interested while we are preparing it's release.
 
 - **Behavioral Search**: This algorithm takes in data we know about users, learns what leads to purchases or reads, then hands this data back to you for inclusion in your content index. The augmenting data makes search personalized, which leads to greater user satisfaction as measured by sales (Amazon has claimed 3% sales lift for a similar algorithm).
 
## Machine Learning Libraries

 - **Spark MLlib**: Many of our Big Data algorithms are taken from Spark's MLlib then built into our production ready system. This Library supplies the algorithms for classification, single action recommenders, and clustering.

 - **Vowpal Wabbit**: Our Small Data (only requires a single machine) or streaming online learning algorithms come from Vowpal Wabbit, a well respected Machine learning library. It is at the core of our Page Variant Recommender.

 - **Apache Mahout**: Mahout Samsara is a reinvention of Mahout as a Big Data "roll your own math and algorithms" engine. Something like R but implemented in Scala as an R-like DSL, which runs on the latest fast execution engines like Spark and Flink. We use and commit to the project, which is at the core of the Universal Recommender.
 
 - **Others**: We are constantly cherry-picking open source for the best new technologies to solve real problems. Describe what you want your app to do and we can help find the right technology.
 
## PredictionIO

We maintain a fork of PredictionIO with some extra features. We use it to customize solutions and deliver scalable reliable systems. We deliver our algorithms as PredictionIO Templates. 
