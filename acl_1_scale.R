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
