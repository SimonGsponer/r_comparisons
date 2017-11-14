########### BOOTSTRAPPING ALGORITHM ###########

library(tidyverse) #the bootstrapping algorithm is dependend upon the tidyverse package

#example:
bootstrapping_algorithm(nyc_flights_tbl, 2000)


bootstrapping_algorithm <- function(tibble_data, num_of_duplications){
  #row_count serves as an input for duplication_vector, specifies the range for resampling
  row_count <- nrow(tibble_data)
  #the duplication_vector generates random numbers representing the row indices of the observation to be resampled
  #to increase efficiency, it is computed how often a given row is going to be duplicated (group_by and summarise)
  duplication_vector <- as.tibble(as.integer(round(runif(num_of_duplications, min = 1, max = row_count), digits = 0))) %>%
    `colnames<-`(c("index_number")) %>%
    group_by(index_number) %>% 
    summarise(freq = n())
  #cache_tibble is orginally an empty dataset with the same headers as the input tibble
  #this way, it caches the duplicated observations before merging them with the input dataset
  cache_tibble <- slice(tibble_data, 0)
  #given that resampling takes its time, I used a progress bar to know more about the progress of the resampling
  pb <- txtProgressBar(min = 0, max = nrow(duplication_vector), style = 3)
  #for each row of the duplication vector, the corresponding observation is duplicated n times (n being the frequency computed earlier)
  for(i in 1 : nrow(duplication_vector)){
    copies <- as.integer(duplication_vector[i, "freq"])
    sliced <- slice(tibble_data, as.integer(duplication_vector[i, "index_number"]))  
    duplicated_rows <- as.tibble(lapply(sliced, rep, copies))
    cache_tibble <-  bind_rows(cache_tibble, duplicated_rows)
    setTxtProgressBar(pb, i)
  }
  #the result is saved as a tibble called 'duplication_tibble'
  duplication_tibble <<- cache_tibble
}

########### EXECUTION ALGORITHM ###########

library(tidyverse) #loads the tidyverse package
library(data.table) #loads the data.table package
library(tictoc) #used to measure the computation time

#example:
aggregation_comparison(50)

aggregation_comparison <- function(iterations){
  #simulation_n defines the length of the result vectors
  simulation_n <- iterations
  #the following three vectors store the results for Base R, the tidyverse package, and the data.table package
  results_base <- vector(length = simulation_n)
  results_tidyv <- vector(length = simulation_n)
  results_data.t <- vector(length = simulation_n)
  #again, I used a progress bar to keep track of the time remaining
  pb <- txtProgressBar(min = 0, max = (simulation_n * 3), style = 3)
  #loads the dataset as a dataframe into the workspace
  query_baseR <- as.data.frame(read_csv("Comparison2_data/big_data.csv"))
  #executes the Base R command as many times as specified by the 'iterations' argument
  for(i in 1 : simulation_n){
    tic()
    aggregate(query_baseR[,c("air_time", "distance")], by=list(query_baseR$carrier), mean)
    time_cache_base <- toc(quiet = TRUE)
    results_base[i] <- time_cache_base$toc - time_cache_base$tic
    setTxtProgressBar(pb, i)
  }
  #removes the dataframe from the workspace
  remove(query_baseR)
  #loads the dataset as a tibble into the workspace
  query_tidyv <- read_csv("Comparison2_data/big_data.csv")  
  #executes the tibble command as many times as specified by the 'iterations' argument
  for(j in 1 : simulation_n){
    tic()
    query_tidyv %>% group_by(carrier) %>% summarise(average_dist = mean(distance), average_time = mean(air_time))
    time_cache_tidyv <- toc(quiet = TRUE)
    results_tidyv[j] <- time_cache_tidyv$toc - time_cache_tidyv$tic
    setTxtProgressBar(pb, (simulation_n + j))
  }
  #removes the tibble from the workspace
  remove(query_tidyv)
  #loads the dataset as a data.table into the workspace
  query_data.t <- as.data.table(read_csv("Comparison2_data/big_data.csv"))
  #given that the coercion defined distance and air_time as integers, it was necessary to redefine them as double-precision vectors
  query_data.t$distance <- as.double(query_data.t$distance)
  query_data.t$air_time <- as.double(query_data.t$air_time)
  #executes the data.table command as many times as specified by the 'iterations' argument
  for(k in 1 : simulation_n){
    tic()
    query_data.t[, j=list(mean(air_time), mean(distance)), by = carrier]
    time_cache_data.t <- toc(quiet = TRUE)
    results_data.t[k] <- time_cache_data.t$toc - time_cache_data.t$tic
    setTxtProgressBar(pb, (2 * simulation_n + k))
  }
  #removes the data.tableframe from the workspace
  remove(query_data.t)
  #the results are saved as a tibble called 'output'
  output <<- tibble(results_base, results_tidyv, results_data.t)
}