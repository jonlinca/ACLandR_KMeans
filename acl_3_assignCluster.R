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
