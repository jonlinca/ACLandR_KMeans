# Tutorial: Unsupervised Learning with ACL Analytics & R

## Background

Unsupervised learning algorithms are powerful, exploratory tools that may help shed some light on patterns that may not be obvious on the surface. Finding patterns within an unlabelled dataset is already challenging enough, let alone trying to verbalize a sort of grouping associated with it.

With ACL v14, the introduction of the ```CLUSTER``` command enables audit practitioners to leverage a machine learning tool to further examine datasets to find potential patterns as part of their analysis.

This tutorial will briefly touch on what K-means is doing, as well as showing you how to execute the equivalent in R, but retain the results in ACL.

**Why is this important?** 
By understanding the fundamentals of using ACL's ```RCOMMAND```, you will be able to assign clusters to your data using any unsupervised method of labelling of your choosing, empowering you to use the best algorithm for your needs.

## Pre-requisites

* Access to the ACL 303 Academy, which gives you access to the ACL 303 1-6 Data.zip data file: https://academy.acl.com/learner/courseinfo/id:325 
* Installing R, and also having a non-Unicode version of ACL (see Troubleshooting for more details).
* Specifying the path of the version of R.exe directly into the PATH environment variable (through the Advanced System Settings in Windows)

## Situation: Analyzing call logs for the time length and cost of calls

Within PBX_Q1_Phonebill.xlsx, this spreadsheet contains the following information:

* *CallDateTime* - The date and time of a call
* *Extension* - The local number the call was made from/to
* *Minutes_Billed* - The duration of the call
* *Number_Dialed* - The destination of the outbound call (or source of an inbound call)
* *Amount_August* - The amount billed for the month of August
* *Amount_September* - The amount billed for the month of September
* *Amount_October* - The amount billed for the month of October

We want to trend the dollars billed and the amounts charged and see if there are any potential groupings within the dataset. This may help guide our examination of the data.

## Instructions
### Step 1: ACL Analytics - prepare the data

To use K-means, the values we want to use must be numeric. In this case, the features we want to compare will be:

* *Minutes_Billed*
* *Amount = Amount_August + Amount_September + Amount_October*

We will create an clean yet unprocessed dataframe that can be sent into R. Lets create a new ACL Project, and then use the following script to import data. Remember to download the data from ACL 303 into the same folder before continuing.

```
COMMENT
Phonebill Example
Author: Jonathan Lin, 2019-01-09

SET SAFETY OFF

COMMENT
Import data 
Data provided by ACL 303 (https://academy.acl.com/learner/courseinfo/id:325)

IMPORT EXCEL TO A00_phonebill "A00_phonebill.fil" FROM "PBX_Q1_Phonebill.xlsx" TABLE "PBX_August$" KEEPTITLE FIELD "CallDateTime" D WID 19 PIC "YYYY-MM-DD hh:mm:ss" AS "" FIELD "Extension" N WID 3 DEC 0 AS "" FIELD "Minutes_Billed" N WID 3 DEC 0 AS "" FIELD "Number_Dialed" C WID 15 AS "" FIELD "Amount_August" N WID 5 DEC 2 AS "" FIELD "Amount_September" N WID 5 DEC 2 AS "" FIELD "Amount_October" N WID 4 DEC 2 AS ""

COMMENT
Create fields for aggregation
We will perform clustering based on amount spent and minutes billed, and remove the time-series aspect

DEFINE FIELD amount COMPUTED Amount_August + Amount_September + Amount_October

OPEN A00_phonebill
SUMMARIZE ON Number_Dialed SUBTOTAL minutes_billed amount to "B01_Summ_Number_Minutes_Amount" OPEN PRESORT 

OPEN B01_Summ_Number_Minutes_Amount
DELETE FIELD COUNT OK
```

At the end of step 1, we will have an summarized list of *Number_Dialed*, aggregated by *minutes_billed* and *amount*. Observe that *Number_Dialed* is a character, while *minutes_billed* and *amount* are numeric data types. If you were to perform a scatterplot of the data, it may look like this:

![Scatterplot of minutes billed and amount, by number dialed](early_scatterplot.png?raw=true)

We are now ready to pass a series of ACL .FIL data tables to R to process our data. While you could combine the next several R scripts into one, its important to understand why we're doing each step.

### Step 2: R - Scale the data

The features we want need to have units that are uniformly affected for each value change. Depending on your data, if there is inconsistency between each column and the values it represents, then the ideal method of pre-processing the data should should be to scale it.

For example:
* A change in one kilometer is different than a change in one mile.
* A change in one dollar is not directly relatable to a change in one kilometer.

Lets create and save the following Rscript, **acl_1_scale.R**, into the same folder as our ACL project folder. We expect to call this script with an ```RCOMMAND```, which means we need to accomodate the use of *acl.readData()* function and *acl.output* object.

```{r}
# Read in ACL data
original_data <- acl.readData()

# Reinforce that our first column is a character column, and isn't going to be analyzed or scaled.
original_data[,1] <- as.character(original_data[,1])
firstColID <- names(original_data)[1]

# Scale everything but the first column and save it as a data frame
# Do this as the scaled returned data type isn't going to work when you cbind it
scaled_data <- as.data.frame(scale(original_data[,-1])) 

# Preserve the first column name and header
scaled_data <- cbind(original_data[,1],scaled_data)
colnames(scaled_data)[1] <- firstColID

# Return data to ACL
acl.output <- as.data.frame(scaled_data)
```

This will allow us to return a new table into ACL. In fact, running the below in ACL will create a table with scaled data, using the script we just created.

```{acl}
COMMENT
Perform scaling using R

OPEN B01_Summ_Number_Minutes_Amount
RCOMMAND FIELDS Number_Dialed minutes_billed amount TO "B02_ScaledData" RSCRIPT "acl_1_scale.R" KEEPTITLE SEPARATOR "," QUALIFIER '"' OPEN
```

### Step 3: R - Determine number of centers

Before we cluster, we need to target the number of centers we want to create (i.e. the number of clusters). The goal of the task is to optimize the amount of error with each one of our clusters. A secondary objective is the number of clusters should help assist us in interpreting what is potentially meaningful. A simple model with 2 clusters may given more insight than a complex model with 15 clusters.

There are several clustering methods, and it is up to the practitioner to decide what is most reasonable for their case. The Elbow method is a straight-forward approach, and is one of many. Read here for more information: https://en.wikipedia.org/wiki/Determining_the_number_of_clusters_in_a_data_set

The elbow method essentially simulates multiple k-means clustering models, and then tells you which one gives you the most 'bang for the buck'. The downside with the Elbow method is that it doesn't authoratively prescribe the optimal number of clusters are - you need to understand your data to see what number of clusters could make sense to you.

The below script creates an empty vector to hold our values, and then simulates a number of clusters between 2 and 15. We return this to ACL, but also list the amount of information gain between each cluster to help us decide.

Save the below script into **acl_2_elbow.R**.

```{r}
scaled_data <- acl.readData()

# Reinforce that our first column is a character column, and isn't going to be analyzed or scaled.
scaled_data[,1] <- as.character(scaled_data[,1])

# First, establish a vector to hold all values.
clusters_sumSquares <- rep(0.0, 14)

# Number of times to run the clustering algorithm
cluster_num <- 2:15

# Control the randomness
set.seed(1)

# Using cluster params, 
for (i in cluster_num) {
  
  # Cluster data using K-means with the current value of i.
  kmeans_temp <- kmeans(scaled_data, centers = i)
  
  # Get the sum of squared for all point and cluster assignments
  # Save this as a data vector
  clusters_sumSquares[i - 1] <- kmeans_temp$tot.withinss
}   

# determine the infromation gain from each cluster
diffError <- diff(clusters_sumSquares)
diffError <- append(0, diffError) #there is no gain on the first simulation

# Combine these all together and throw back to ACL
elbow_data <- cbind(cluster_num, clusters_sumSquares, diffError)

acl.output <- elbow_data
```

Of course, calling this from ACL couldn't be easier.

```{acl}
COMMENT
Determine error rates with different numbers of clusters

OPEN B02_ScaledData
RCOMMAND FIELDS Number_Dialed minutes_billed amount TO "B03_ElbowErrors" RSCRIPT "acl_2_elbow.R" KEEPTITLE SEPARATOR "," QUALIFIER '"' OPEN
```

We can now inspect the data - we get *cluster_params* (the number of clusters ran), the *clusters_sumSquares* (the amount of error), and *diffError* (the error reduced between each cluster ran). The below is a visual of the plot of the number of clusters and the corresponding error amount

![Scree Plot example of errors](screeplot.png?raw=true)

For our analysis here, I've chosen 4 as the number of clusters we will want to run for our analysis. Four clusters seems to have the biggest bang for buck, and since we only have two variables we're analyzing, seems like a reasonable segment. The number of clusters will depend on how many logical groups you think may be embedded in the data, which is also related to the number of features you may give the model to cluster.

### Step 4: ACL - Assign the clusters

As we've chosen four clusters in our analysis, now we want to know where each phone number dialed, along with amount and call duration, should be grouped together. We will run K-means one more time, but this time we will assign each phone number to a cluster. 

Save the below into **acl_3_assignCluster.R**. If you like, you can change the centersVal value to indicate the number of clusters that you would like to assign

```
# Imports the data from RCOMMAND
scaled_data <- acl.readData()
clustered_data <- scaled_data # Create separate object for easier tracking

# Reinforce that our first column is a character column, and isn't going to be analyzed or scaled.
clustered_data[,1] <- as.character(clustered_data[,1])
firstColID <- names(clustered_data)[1]

# Manually specify the number of clusters
centersVal <- 4

set.seed(1)
kmeans_df <- as.data.frame(clustered_data[,-1]) # Remove the first column
kmeans_df <- kmeans(clustered_data, centers = centersVal)

# Append the cluster number back to the df, which gets returned to ACL
cluster_df <- as.data.frame(kmeans_df$cluster)
colnames(cluster_df)[1] <- "cluster" # Preserve first column name
clustered_data$cluster <- cluster_df$cluster
colnames(clustered_data)[1] <- firstColID # Preserve first column name

acl.output <- clustered_data
```

Again, call this from ACL to get our final result.
```
COMMENT
Store KMeans cluster assignment

OPEN B02_ScaledData
RCOMMAND FIELDS Number_Dialed minutes_billed amount TO "B04_AssignClusters" RSCRIPT "acl_3_assignCluster.R" KEEPTITLE SEPARATOR "," QUALIFIER '"' OPEN
```

### Step 5: ACL Analytics - Creating data subset and tests based on these cluster assignments

![Example of the cluster assignments](clustersplot.png?raw=true)

Now that you have each phone number and its assigned clusters, you can join it back with your starting dataset. The grunt work now comes into understanding why did each phone number fall into a cluster, and looking for additional patterns or simply auditing these as samples to seek more information.

## What's next?

### Feature engineering
Could you additional features to compliment your data? Example: Identify which calls are within North America and International? Does adding this information make your groupings more clear and distinct?

### Other clustering algorithms
Now that you know how to implement one unsupervised algorithm, there are several more out there. Each one will group data differently (distance-based, density-based), so there are several options to experiement, but the way you want to approach each of them is fundamentally similar.

### Should I keep the K-Means center coordinates?
You may have keenly observed that the kmeans model also returns *centers* (if you run this in R, it shows up as a matrix under the kmeans_df object). While you may be tempted to create an ACL procedure by comparing how far a new 'phone number' is away from these centers for a future grouping, it won't be relevant as the kmeans is ran based on the scale of the data it was ran on. Each time you run the K-means algorithm, it will change the scale and centers as a result, rendering any prior centers generally useless.

## Troubleshooting
```Error occured when converting file``` - Means you're running ACL Unicode, which doesn't work with RCommand as well as it should quite yet. I'll remove this when ACL has deployed a bugfix.

Other errors that I ran while creating this included:
- Having *$* as field names in R that can't be transferred back into R. A diligent use of colnames will eliminate this risk.
- Having two double fields not fully returning into ACL. My fix was to ensure a character column act as the first field.
