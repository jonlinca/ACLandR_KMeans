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