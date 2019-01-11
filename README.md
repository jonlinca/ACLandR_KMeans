# Tutorial: Unsupervised Learning with ACL Analtyics

## Background

Finding patterns within a dataset is challenging, as it generally lacks labelled data, let alone any sort of discerable patterns. Unsupervised learning algoritms are powerful, exploratory tools that may help shed some light on patterns that may not be obvious on the surface.

With ACL v14 and the introduction of the CLUSTER command, this enables audit practitioners to leverage a machine learning tool to further examine datasets to find potential patterns as part of their analysis.

This tutorial will briefly touch on what K-means is doing, as well as showing you how to execute the equivalent outside of ACL, but retain those results in R.

**Why is this important?** 
By understanding the fundamentals of using ACL's ```RCOMMAND```, you will be able to assign clusters to your data using any unsupervised method of labelling of your choosing, empowering you to use the best algorithm for your needs (since there is no such thing as a free lunch).

## Pre-requisites

* Access to the ACL 303 Academy, which gives you access to the ACL 303 1-6 Data.zip data file: https://academy.acl.com/learner/courseinfo/id:325 

## Situation: Analyzing call logs for the time length and cost of calls

Within PBX_Q1_Phonebill.xlsx, there is a spreadsheet that contains the following information:

* CallDateTime - The date and time of a call
* Extension - The local number the call was made from/to
* Minutes_Billed - The duration of the call
* Number_Dialed - The destination of the outbound call (or source of an inbound call)
* Amount_August - The amount billed for the month of August
* Amount_September - The amount billed for the month of September
* Amount_October - The amount billed for the month of October

We want to trend the dollars billed and the amounts charged and see if there are any potential groupings within the dataset. This may help guide our examination of the data.

## Instructions
### Step 1: ACL Analytics - prepare the data

To use K-Means, the values we want to use must be numeric. In this case, the features we want to compare will be:

* Minutes_Billed
* Amount = Amount_August + Amount_September + Amount_October

We will create an clean, yet unprocessed dataframe that can be sent into R. First, lets create a new ACL Project, and then use the following script to import data. Remember to download the data from ACL 303 into the same folder before continuing.

```
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

At the end of step 1, we will have an summarized list of Number_Dialed, aggregated by minutes_billed and amount. Observe that Number_Dialed is a character, while minutes_billed and amount are our numeric data types. 

We are now ready to pass a series of ACL .FIL data tables to R to process our data. While you could combine the next several steps into one, its important to understand why we're doing each step.

### Step 2: R - Scale the data

The features we want need to have units that are uniformly affected for each value change. Depending on your data, if there is inconsistency between each column and the values it represents, then the ideal method of pre-processing the data should should be to scale it.

For example:
* A change in one kilometer is different than a change in one mile.
* A change in one dollar is not directly relatable to a change in one kilometer.

Lets create and save the following Rscript, **acl_centre.R**, into the same folder as our ACL project folder. We expect to call this script with an ```RCOMMAND```, which means we need to accomodate the use of *acl.readData()* function and *acl.output* object.

```{r}
# Read in ACL data
df <- acl.readData()

# Reinforce that our first column is a character column, and isn't going to be analyzed or scaled.
df[,1] <- as.character(df[,1])

# Scale all columns excluding the first column
df <- scale(df[,-1])

# Return data to ACL
acl.output <- as.data.frame(df)
```

This will allow us to return a new table into ACL. In fact, running the below in ACL will create a table with scaled data, using 

```{acl}
COMMENT
Call and store KMeans cluster assignment

RCOMMAND FIELDS amount TO "B02_ScaledData" RSCRIPT "acl_centre.R" KEEPTITLE SEPARATOR "," QUALIFIER '"' OPEN
```

### Step 3: R - Elbow method to determine number of centers


### Step 3: ACL - Call the cluster assignment

```
COMMENT
Call and store KMeans cluster assignment

RCOMMAND FIELDS amount TO "B02_AssignClusters" RSCRIPT "acltest.R" KEEPTITLE SEPARATOR "," QUALIFIER '"' OPEN
```

### Step 4: R - Understanding cluster assignments

### Step 5: ACL Analytics - Creating tests based on these cluster assignments

## What's next?

** What about the centers? **

## Troubleshooting
