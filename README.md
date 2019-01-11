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

We want to trend the values and see if there are any potential groupings within the dataset. This may help guide our examination of the data.

## Instructions
### Step 1: ACL Analytics - prepare the data

To use K-Means, the values we want to use must be numeric and scaled. 

### Step 2: R - Scale

### Step 3: R - Create and save cluster assignments

** What about the centers? **

### Step 4: R - Understanding cluster assignments

### Step 5: ACL Analytics - Creating tests based on these cluster assignments

## What's next?

## Troubleshooting
