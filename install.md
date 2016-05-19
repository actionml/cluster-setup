# ActionML's PredictionIO and Universal Recommender

As of PredictionIO v0.9.6 and The Universal Recommender v0.3.0 ActionML has had to create a forked version, which is installed slightly differently than the Salesforce version. We are working to resolve these differences but in the meantime follow these steps.

**Note**: if you have installed before, follow the "Upgrade" instructions below.

## Upgrade

### Remove v0.9.5 or Saleforce v0.9.6

 1. Remove or rename the directory containing the old version of PredictionIO
 2. `$ rm -r ~/.ivy2` This is required and will remove the local cache of classes created when building PredictionIO and templates.
 
### Download ActionML's fork of PredictionIO

ActionML released v0.9.6 of our fork of PredictionIO 3 weeks before Salesforce did but they choose to use the same version number, which unfortunately causes a version clash and to use the Universal Recommender we must us ActionML's v0.9.6. To do this you must build PredictionIO from the ActionML github repo.

 1. `$ git clone https://github.com/actionml/PredictionIO.git pio` clone to some directory
 
Proceed to **Build PredictionIO**
 
## Install From a Script

For a completely fresh new install, do not use the script on PredictionIO's docs site do the following:

 1. `bash -c "$(curl -s https://raw.githubusercontent.com/actionml/PredictionIO/develop/bin/install.sh)"`
 
This will create a `vendors` subdirectory with needed services installed there. This is only for a single machine developer setup and is not advised for Production.

## Build PredictionIO

You must build PredictionIO from source to get needed classes installed in your local cache or the Universal Recommender will not build, you will get error in `pio build`. This is pretty easy:

 1. `cd /path/to/pio/source`
 2. `./make-distribution`
 
Make sure to install and configure all components using the methods described [here](https://github.com/actionml/cluster-setup/blob/master/readme.md).

To test your installation run `pio status` to make sure pio is working. Also check with  to make sure HDFS and and Spark are running correctly since `pio status` does not check the running status of those services.
 
## Build Universal Recommender
 
  1. `git clone https://github.com/actionml/template-scala-parallel-universal-recommendation.git ~/universal`
  2. Proceed with UR installation described [here](https://github.com/actionml/template-scala-parallel-universal-recommendation#quick-start).
  
## Build Any Template

Building a template with this version of PredictionIO is just the same as before:

    $ cd /path/to/template/directory
    $ pio build
