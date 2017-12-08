#get the dataset
library(nycflights13)

nyc_flights <- nycflights13::flights %>%
  filter(!is.na(arr_time))

nyc_flights_DF <- as.data.frame(nyc_flights)



#get packages for the resampling algorithms
library(tidyverse) 
library(data.table)
#packages required for parallelisation
library(foreach)
library(doParallel)

#get package for recording computational time
library(tictoc)

#resampling algorithm from Comparison 2; design described in 4_resampling_algorithms.md
resampling_algorithm_c2 <- function(tibble_data, num_of_duplications){
  row_count <- nrow(tibble_data)
  duplication_vector <- as.tibble(as.integer(round(runif(num_of_duplications, min = 1, max = row_count), digits = 0))) %>%
    `colnames<-`(c("index_number")) %>%
    group_by(index_number) %>% 
    summarise(freq = n())
  cache_tibble <- slice(tibble_data, 0)
  for(i in 1 : nrow(duplication_vector)){
    copies <- as.integer(duplication_vector[i, "freq"])
    sliced <- slice(tibble_data, as.integer(duplication_vector[i, "index_number"]))  
    duplicated_rows <- as.tibble(lapply(sliced, rep, copies))
    cache_tibble <-  bind_rows(cache_tibble, duplicated_rows)
  }
  return(cache_tibble)
}

#improved version of resampling_algorithm_c2; design described in 4_resampling_algorithms.md
#this version consists of three functions, namely index_DT (which divides the vector listing the indices of the observations to resample into three pieces), 
#resampling_algorithm (does the actual resampling), 
#and more_efficient_c2 (puts everything together)

#to resample a dataset, one has to identify the observations that should be resampled in the first place (i.e. determine the row indices)
#index_DT takes the number of observations that should be resampled and defines (in my case) three sub-vectors that list the row indices of the observations to be resampled, where each of these sub-vectors contains the indices of a third of the number of observations that should be resampled
#the if statements are required to handle cases where the number of observations to resample is not divisible by three (for example: when 100 observations should be resampled, there is no way to create three equally-long sub-vectors right away)

#NOTE: I did not hard-code the number of sub-vectors the function should create; given the number of cores of your computer, the function creates (n-1) sub-vectors, where n denotes the number of cores your computer has (the MacBook Air I use has 4 cores)

index_DT <- function(resample_n, n_row_DT){
  no_cores <- detectCores() - 1 
  resample_vector_size <- resample_n %/% no_cores
  remainder <- resample_n %% no_cores
  if (remainder == 0){
    indexed_DT <- as.data.table(vector(length = resample_vector_size))
    for (i in 1 : no_cores){
      nam <- vector(length = resample_vector_size)
      nam <- round(runif(resample_vector_size, min = 1, max = n_row_DT), digits = 0)
      nam <- as.data.table(nam)
      setnames(nam, c(paste("resample.column", i, sep = ".")) )
      indexed_DT <- data.table(indexed_DT, nam)
    }
  } else {
    indexed_DT <- as.data.table(vector(length = resample_vector_size + 1))
    for (i in 1 : (no_cores - (no_cores - remainder))){
      nam <- vector(length = resample_vector_size)
      nam <- round(runif(resample_vector_size + 1, min = 1, max = n_row_DT), digits = 0)
      nam <- as.data.table(nam)
      setnames(nam, c(paste("resample.column", i, sep = ".")) )
      indexed_DT <- data.table(indexed_DT, nam)
    }
    for (i in (no_cores - (no_cores - remainder) + 1) : no_cores){
      nam <- vector(length = resample_vector_size)
      nam <- c(round(runif(resample_vector_size, min = 1, max = n_row_DT), digits = 0), 0)
      nam <- as.data.table(nam)
      setnames(nam, c(paste("resample.column", i, sep = ".")) )
      indexed_DT <- data.table(indexed_DT, nam)
    }
  }
  indexed_DT <- indexed_DT[,2 : (no_cores + 1)]
  return(indexed_DT)
}

#for a given vector listing the row indices of the observations to be resampled, resampling_algorithm goes through this vector and does the resampling row-wise
resampling_algorithm <- function(input_DT, indexed_resample_DT, column_number){
  DT_frame <- input_DT[0]
  for (j in 1 : nrow(indexed_resample_DT)){
    DT_frame <- rbindlist(list(DT_frame, input_DT[as.numeric(indexed_resample_DT[get("j"), get("column_number"), with=FALSE])]), use.names = TRUE, fill = FALSE, idcol = NULL)
  }
  return(DT_frame)
}

#more_efficient_c2 puts index_DT and resampling_algorithm together: 
#in my case, more_efficient_c2 creates three sub-vectors, which define the indices of the observations to be resampled, and passes them to three cores of my CPU, which do the resampling simultaneously
more_efficient_c2 <- function(input_DataT, num_resamples){
  resample_indexing <- index_DT(num_resamples, nrow(input_DataT))
  no_cores <- detectCores() - 1 
  cl <- makeCluster(no_cores)
  registerDoParallel()
  resampled_DT <- foreach(i = 1: length(resample_indexing), .export = "resampling_algorithm", .combine = rbind , .multicombine=TRUE) %dopar% {
    resampling_algorithm(input_DataT, resample_indexing, get("i"))
  }
  return(resampled_DT)
  on.exit(stopCluster(cl))
}


#this algorithm combines the design of more_efficient_c2 with the solution of andreister; design described in 4_resampling_algorithms.md
#the algorithm creates three sub-vectors that define the indices of the observations to be resampled (i.e. it uses index_DT)
#subsequently, three cores *implicitly* resample the dataset, where these three resampled sub-datasets are binded together at the end
parallelised_data_table <- function(dataset_DT, num_resamples){
  resample_indexing <- index_DT(num_resamples, nrow(dataset_DT))
  no_cores <- detectCores() - 1 
  cl <- makeCluster(no_cores)
  registerDoParallel()
  resampled_DT <- foreach(i = 1: length(resample_indexing), .combine = rbind , .multicombine=TRUE) %dopar% {
    dataset_DT[as.numeric(unlist(resample_indexing[, get("i")])), ]
  }
  return(resampled_DT)
  on.exit(stopCluster(cl))
}

#algorithm used to record the computational times of all five resampling algorithms mentioned in 4_resampling_algorithms.md, yielding the data for 'Round One'
execution_algorithm <- function(dataset_DF, resampling_N, iterations){
  group <- vector(length = iterations * 5)
  function_name <- vector(length = iterations * 5)
  time <- vector(length = iterations * 5)
  results <- data.frame(group, function_name, time)
  pb <- txtProgressBar(min = 0, max = iterations * 5, style = 3)
  for (i in 1 : iterations){
    tic()
    #'Base R'
    df_new <- dataset_DF[sample(1:nrow(dataset_DF), resampling_N, replace=TRUE),]
    time_cache <- toc(quiet = TRUE)
    results[get("i"), "group"] <- 1
    results[get("i"), "function_name"] <- "baseR"
    results[get("i"), "time"] <- time_cache$toc - time_cache$tic
    setTxtProgressBar(pb, i)
  }
  dataset_TBL <- as.tibble(dataset_DF)
  for (i in (iterations + 1) : (2 * iterations)){
    tic()
    #'Comparison 2'
    df_new <- resampling_algorithm_c2(dataset_TBL, resampling_N)
    time_cache <- toc(quiet = TRUE)
    results[get("i"), "group"] <- 2
    results[get("i"), "function_name"] <- "Comparison2"
    results[get("i"), "time"] <- time_cache$toc - time_cache$tic
    setTxtProgressBar(pb, i)
  }
  remove(dataset_TBL)
  dataset_DT <- as.data.table(dataset_DF)
  for (i in ((2 * iterations) + 1) : (3 * iterations)){
    tic()
    #'data.table'
    df_new <- dataset_DT[sample(1:nrow(dataset_DT), resampling_N, replace=TRUE),]
    time_cache <- toc(quiet = TRUE)
    results[get("i"), "group"] <- 3
    results[get("i"), "function_name"] <- "DT_basic"
    results[get("i"), "time"] <- time_cache$toc - time_cache$tic
    setTxtProgressBar(pb, i)
  }
  for (i in ((3 * iterations) + 1) : (4 * iterations)){
    tic()
    #'Comparison 2 more efficient'
    df_new <- more_efficient_c2(dataset_DT, resampling_N)
    time_cache <- toc(quiet = TRUE)
    results[get("i"), "group"] <- 4
    results[get("i"), "function_name"] <- "DT_MC_resampler"
    results[get("i"), "time"] <- time_cache$toc - time_cache$tic
    setTxtProgressBar(pb, i)
  }
  for (i in ((4 * iterations) + 1) : (5 * iterations)){
    tic()
    #'parallelised data.table'
    df_new <- parallelised_data_table(dataset_DT, resampling_N)
    time_cache <- toc(quiet = TRUE)
    results[get("i"), "group"] <- 5
    results[get("i"), "function_name"] <- "parallelised_data_table"
    results[get("i"), "time"] <- time_cache$toc - time_cache$tic
    setTxtProgressBar(pb, i)
  }
  return(results)
}

results <- execution_algorithm(nyc_flights_DF, 10, 5)


#algorithm used to record the computational times of the three resampling algorithms compared in 'Round Two'
second_execution_algorithm <- function(dataset_DF, resampling_N_vector, iterations){
  vec_length <-  length(resampling_N_vector)
  group <- vector(length = iterations * 3 * vec_length)
  resample_group <- vector(length = iterations * 3 * vec_length)
  function_name <- vector(length = iterations * 3 * vec_length)
  time <- vector(length = iterations * 3 * vec_length)
  results <- data.frame(group, function_name, time)
  pb <- txtProgressBar(min = 0, max = iterations * 3* vec_length, style = 3)
  counter <- 0
  dataset_DT <- as.data.table(dataset_DF)
  for (j in 1: vec_length){
    for (i in 1 : iterations){
      counter <- counter + 1
      tic()
      #'Base R'
      df_new <- dataset_DF[sample(1:nrow(dataset_DF), resampling_N_vector[get("j")], replace=TRUE),]
      time_cache <- toc(quiet = TRUE)
      results[get("counter"), "group"] <- 1
      results[get("counter"), "resample_group"] <- j
      results[get("counter"), "function_name"] <- "baseR"
      results[get("counter"), "time"] <- time_cache$toc - time_cache$tic
      setTxtProgressBar(pb, counter)
    }
    for (i in ((2 * iterations) + 1) : (3 * iterations)){
      counter <- counter + 1
      tic()
      #'data.table'
      df_new <- dataset_DT[sample(1:nrow(dataset_DF), resampling_N_vector[get("j")], replace=TRUE),]
      time_cache <- toc(quiet = TRUE)
      results[get("counter"), "group"] <- 2
      results[get("counter"), "resample_group"] <- j
      results[get("counter"), "function_name"] <- "DT"
      results[get("counter"), "time"] <- time_cache$toc - time_cache$tic
      setTxtProgressBar(pb, counter)
    }
    for (i in ((2 * iterations) + 1) : (3 * iterations)){
      counter <- counter + 1
      tic()
      #'parallelised data.table'
      df_new <- parallelised_data_table(dataset_DT, resampling_N_vector[get("j")])
      time_cache <- toc(quiet = TRUE)
      results[get("counter"), "group"] <- 3
      results[get("counter"), "resample_group"] <- j
      results[get("counter"), "function_name"] <- "parallelised_data_table"
      results[get("counter"), "time"] <- time_cache$toc - time_cache$tic
      setTxtProgressBar(pb, counter)
    }
  }
  return(results)
}

results_2 <- second_execution_algorithm(nyc_flights_DF, c(100, 1000, 10000, 100000, 1000000, 10000000), 10)

