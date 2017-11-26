library(tictoc)
library(foreach)
library(doParallel)

#load dataset 
GE_data <- read.csv("Comparison_data/GE_data.csv")


### wrapped up functions ###

#to make sure the differences in computational times are genuinely due to the different specifications, 
#the functions for the simple and complex task were wrapped up in all functions that were compared

## computationally simple task (moving average)
#based on the given index number (= rw_nmbr), this function returns the moving average for the corresponding range
#the variable rw_nmbr allows for incorporating this function into loops and apply functions

#data_dfr: specifies the data.frame to be used
#rw_number: specifies the row for which the moving average should be calculated
#price_col: specifies the name of the price column (= string)
#window_length: specifies the number of observations to be included in the moving average

indexed_average <- function(data_dfr, rw_nmbr, price_col, window_length){
  t <- max(rw_nmbr - window_length + 1, 1) #smoothing method: for all observations where there are not enough observations to calculate a n-day moving average, use the number of days that are available
  return(mean(data_dfr[t : rw_nmbr, price_col])) #computes the moving average and returns the value
}

## computationally complex task (average Euclidean distance)

#the design is similar to the moving-average function: for the given row (=rw_nmbr), the average Euclidean distance to all other data points is calculated
#the average Euclidean distance is based on the closing price (=price_col), the highest price of the day (=high_col), and the lowest price of the day (=low_col)

indexed_euclidean_dist <- function(data_dfr, rw_nmbr, price_col, high_col, low_col){
  calc_df <- data_dfr[-rw_nmbr,] #create a new dataset which includes all observations, apart from the one specified in rw_nmbr
  calc_df$Close_indexed <- data_dfr[rw_nmbr, price_col] #for this new dataset, create a new column: every row in this new column states the closing price of the day specified in rw_nmbr (i.e. all rows of this column have the same value)
  calc_df$High_indexed <- data_dfr[rw_nmbr, high_col] #do the same for the highest price
  calc_df$Low_indexed <- data_dfr[rw_nmbr, low_col] #do the same for the lowest price
  calc_df$Euc_dist <- sqrt((calc_df[, "Close_indexed"] - calc_df[, price_col])^2 + (calc_df[, "High_indexed"] - calc_df[, high_col])^2 + (calc_df[, "Low_indexed"] - calc_df[, low_col])^2) #compute the Euclidean distance from the selected observation to all others
  return(mean(calc_df$Euc_dist)) #compute and return the mean of all Euclidean distances
}

### FOR LOOP VS APPLY FUNCTION for a simple task, using a single core ###

# for loop
sliding_SMA_loop <- function(data_dfr, price_col, window_length){
  table_length <- nrow(data_dfr) #find length of the table
  simple_ma <- vector(length = table_length) #create a new vector which has the length of the dataset
  for(i in 1 : table_length){ #for the entire length of the dataset, compute the moving average
    simple_ma[i] <- indexed_average(data_dfr, i, price_col, window_length)
  }
  sma_loop_output <<- data.frame(data_dfr, simple_ma) #save the output
}

#apply function
#the function has exactly the same structure, but uses sapply instead of a for loop
sliding_SMA_apply <- function(data_dfr, price_col, window_length){
  table_length <- nrow(data_dfr)
  simple_ma <- vector(length = table_length)
  simple_ma <- sapply(1 : table_length, function(x){
    indexed_average(data_dfr, x, price_col, window_length)
  })
  sma_apply_output <<- data.frame(data_dfr, simple_ma)
}

#execution algorithm, which stores the computational times required
execution_oneC_simple <- function(data_dfr, n){
  vec_length <- n
  pb <- txtProgressBar(min = 0, max = vec_length, style = 3)
  results_loop <- vector(length = vec_length)
  results_apply <- vector(length = vec_length)
  for (i in 1 : vec_length) {
    tic()
    sliding_SMA_loop(data_dfr, "Close", 3)
    time_cache_loop <- toc(quiet = TRUE)
    results_loop[i] <- time_cache_loop$toc - time_cache_loop$tic
    tic()
    sliding_SMA_apply(data_dfr, "Close", 3)
    time_cache_apply <- toc(quiet = TRUE)
    results_apply[i] <- time_cache_apply$toc - time_cache_apply$tic
    setTxtProgressBar(pb, i)
  }
  output_c3_oneC_simple <<- data.frame(results_loop, results_apply)
}

execution_oneC_simple(GE_data, 10)

### FOR LOOP VS APPLY FUNCTION for a complex task, using a single core  ###

#this loop has the same structure as the one from the simple task; the only difference is a different function that was wrapped up

Euclidean_loop <- function(data_dfr, price_col, high_col, low_col){
  total_rows <- nrow(data_dfr)
  ave_euc_dist <- vector(length = total_rows)
  for(i in 1 : nrow(data_dfr)){
    ave_euc_dist[i] <- indexed_euclidean_dist(data_dfr, i, price_col, high_col, low_col)
  }
  ave_euc_dist_loop <<- data.frame(data_dfr, ave_euc_dist)
}

#same for this apply function

Euclidean_apply <- function(data_dfr, price_col, high_col, low_col){
  total_rows <- nrow(data_dfr)
  ave_euc_dist <- vector(length = total_rows)
  ave_euc_dist <- sapply(1 : nrow(data_dfr), function(x){
    indexed_euclidean_dist(data_dfr, x, price_col, high_col, low_col)
  })
  ave_euc_dist_sapply <<- data.frame(data_dfr, ave_euc_dist)
}

#execution algorithm, which stores the computational times required
execution_oneC_complex <- function(data_dfr, n){
  vec_length <- n
  pb <- txtProgressBar(min = 0, max = vec_length, style = 3)
  results_loop <- vector(length = vec_length)
  results_apply <- vector(length = vec_length)
  for (i in 1 : vec_length) {
    tic()
    Euclidean_loop(data_dfr, "Close", "High", "Low")
    time_cache_loop <- toc(quiet = TRUE)
    results_loop[i] <- time_cache_loop$toc - time_cache_loop$tic
    tic()
    Euclidean_apply(data_dfr, "Close", "High", "Low")
    time_cache_apply <- toc(quiet = TRUE)
    results_apply[i] <- time_cache_apply$toc - time_cache_apply$tic
    setTxtProgressBar(pb, i)
  }
  output_c3_oneC_complex <<- data.frame(results_loop, results_apply)
}

execution_oneC_complex(GE_data, 10)


### FOR LOOP VS APPLY FUNCTION for a simple task, using multiple cores  ###

# again, the basic structure of the loop is the same; however, the multicore loops use 'foreach' instead of 'for' and specify additional arguments in order for parallelising the task

sliding_SMA_loop_MC <- function(data_dfr, price_col, window_length){
  table_length <- nrow(data_dfr)
  simple_ma <- vector(length = table_length)
  no_cores <- detectCores() - 1 #take the number of cores your computer has and substract one (to not overload your CPU)
  cl <- makeCluster(no_cores) #makeCluster based on the specified number of cores
  registerDoParallel() #initiate parallelisation
  simple_ma <- foreach(i = 1 : table_length, .export = "indexed_average", .combine= c, .multicombine=TRUE) %dopar% { #parallelised for loop
    indexed_average(data_dfr, i, price_col, window_length)
  }
  sma_loop_output_MC <<- data.frame(data_dfr, simple_ma)
  on.exit(stopCluster(cl)) #stop parallelisation
}

# instead of sapply (which is used in the single core functions), parSapply is used for parallelisation

sliding_SMA_apply_MC <- function(data_dfr, price_col, window_length){
  table_length <- nrow(data_dfr)
  simple_ma <- vector(length = table_length)
  no_cores <- detectCores() - 1 #similar additional arguments as the ones used for the parallelised for loop
  cl <- makeCluster(no_cores)
  registerDoSEQ()
  clusterExport(cl, "indexed_average")
  simple_ma <- parSapply(cl, 1 : table_length, function(x){ #parallelised apply function
    indexed_average(data_dfr, x, price_col, window_length)
  })
  sma_apply_output_MC <<- data.frame(data_dfr, simple_ma)
  on.exit(stopCluster(cl)) #stop parallelisation
}

#execution algorithm, which stores the computational times required

execution_MC_simple <- function(data_dfr, n){
  vec_length <- n
  pb <- txtProgressBar(min = 0, max = vec_length, style = 3)
  results_loop <- vector(length = vec_length)
  results_apply <- vector(length = vec_length)
  for (i in 1 : vec_length) {
    tic()
    sliding_SMA_loop_MC(data_dfr, "Close", 3)
    time_cache_loop <- toc(quiet = TRUE)
    results_loop[i] <- time_cache_loop$toc - time_cache_loop$tic
    tic()
    sliding_SMA_apply_MC(data_dfr, "Close", 3)
    time_cache_apply <- toc(quiet = TRUE)
    results_apply[i] <- time_cache_apply$toc - time_cache_apply$tic
    setTxtProgressBar(pb, i)
  }
  output_c3_MC_simple <<- data.frame(results_loop, results_apply)
}

execution_MC_simple(GE_data, 10)

### FOR LOOP VS APPLY FUNCTION for a hard task, using multiple cores ###

#same loops as the multi-core loop used for the simple task; only a different function is wrapped up

Euclidean_loop_MC <- function(data_dfr, price_col, high_col, low_col){
  total_rows <- nrow(data_dfr)
  ave_euc_dist <- vector(length = total_rows)
  no_cores <- detectCores() - 1 
  cl <- makeCluster(no_cores)
  registerDoParallel()
  ave_euc_dist <- foreach(i = 1 : total_rows, .export = "indexed_average", .combine = c , .multicombine=TRUE) %dopar% {
    indexed_euclidean_dist(data_dfr, i, price_col, high_col, low_col)
  }
  ave_euc_dist_loop_MC <<- data.frame(data_dfr, ave_euc_dist)
  on.exit(stopCluster(cl))
}

#same for this apply function

Euclidean_apply_MC <- function(data_dfr, price_col, high_col, low_col){
  total_rows <- nrow(data_dfr)
  ave_euc_dist <- vector(length = total_rows)
  no_cores <- detectCores() - 1 
  cl <- makeCluster(no_cores)
  registerDoSEQ()
  clusterExport(cl, "indexed_euclidean_dist")
  ave_euc_dist <- parSapply(cl, 1 : total_rows, function(x){
    indexed_euclidean_dist(data_dfr, x, price_col, high_col, low_col)
  })
  ave_euc_dist_apply_MC <<- data.frame(data_dfr, ave_euc_dist)
  on.exit(stopCluster(cl))
}

#execution algorithm, which stores the computational times required

execution_MC_complex <- function(data_dfr, n){
  vec_length <- n
  pb <- txtProgressBar(min = 0, max = vec_length, style = 3)
  results_loop <- vector(length = vec_length)
  results_apply <- vector(length = vec_length)
  for (i in 1 : vec_length) {
    tic()
    Euclidean_loop_MC(data_dfr, "Close", "High", "Low")
    time_cache_loop <- toc(quiet = TRUE)
    results_loop[i] <- time_cache_loop$toc - time_cache_loop$tic
    tic()
    Euclidean_apply_MC(data_dfr, "Close", "High", "Low")
    time_cache_apply <- toc(quiet = TRUE)
    results_apply[i] <- time_cache_apply$toc - time_cache_apply$tic
    setTxtProgressBar(pb, i)
  }
  output_c3_MC_complex <<- data.frame(results_loop, results_apply)
}

execution_MC_complex(GE_data, 10)
