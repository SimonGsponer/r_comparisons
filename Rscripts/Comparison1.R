#### LIBRARIES

library(tidyverse) #for tibble()
library(data.table) #for data.table()
library(tictoc) #to measure the computational time
library(beepr) #since creating more than 45bn random numbers takes some minutes, this package let me know when the computations were done so I didn't had to stare at the screen all the time


#### FUNCTIONS
#these functions create a data frame whose length (i.e. nrow()) is specified by the parameter of the function

#function for creating a data.frame
dfr_creator <- function(n){
  data.frame(
    "x" = runif(n, min = 1, max = 100), 
    "y" = rnorm(n, mean = 50, sd = 4), 
    "z" = rlnorm(n, meanlog = 2, sdlog = 1)
  )
}

#function for creating a tibble
tbl_creator <- function(n){
  tibble(
    x = runif(n, min = 1, max = 100), 
    y = rnorm(n, mean = 50, sd = 4), 
    z = rlnorm(n, meanlog = 2, sdlog = 1)
  )
}

#function for creating a data.table
dtb_creator <- function(n){
  data.table(
    x = runif(n, min = 1, max = 100), 
    y = rnorm(n, mean = 50, sd = 4), 
    z = rlnorm(n, meanlog = 2, sdlog = 1)
  )
}

#function for creating a coerced data.table from a tibble
dtb_tbl_creator <- function(n){
  as.data.table(
    tibble(
      x = runif(n, min = 1, max = 100), 
      y = rnorm(n, mean = 50, sd = 4), 
      z = rlnorm(n, meanlog = 2, sdlog = 1)
    )
  )
}

#function for creating a coerced data.table from a data.frame
dtb_dfr_creator <- function(n){
  as.data.table(
    data.frame(
      "x" = runif(n, min = 1, max = 100), 
      "y" = rnorm(n, mean = 50, sd = 4), 
      "z" = rlnorm(n, meanlog = 2, sdlog = 1)
    )
  )
}

#### EXECUTION ALGORITHM 1
# yielded the data for chart 1
# input used:

tic()
creator_comparison(c(10000, 100000, 1000000, 100000000), 50)
toc()

# For all dataset sizes specified in the input_vector, the execution algorithm created 50 3-column data frames for 
#data.frame(), tibble(), and data.table().
# Accordingly, the first loop iterates over the length of the input_vector; subsequently, the second loop 
#interatves over the specified number of iterations (i.e. 50)
# For every generated dataset, the time was recorded by using the tictoc functions

creator_comparison <- function(input_vector, iterations){
  scenario_n <- length(input_vector)
  simulation_n <- iterations
  dfr_names <-  vector(length = scenario_n)
  tbl_names <-  vector(length = scenario_n)
  dtb_names <-  vector(length = scenario_n)
  result_cache_dfr <- vector(length = simulation_n)
  result_cache_tbl <- vector(length = simulation_n)
  result_cache_dtb <- vector(length = simulation_n)
  output <<- vector(length = simulation_n)
  for(i in 1 : scenario_n){
    dfr_names[i] <- paste("dfr_",i, sep = "")
    tbl_names[i] <- paste("tbl_",i, sep = "")
    dtb_names[i] <- paste("dtb_",i, sep = "")
    for(j in 1 : simulation_n){
      tic()
      dfr_creator(input_vector[i])
      time_cache_dfr <- toc(quiet = TRUE)
      result_cache_dfr[j] <- time_cache_dfr$toc - time_cache_dfr$tic
      tic()
      tbl_creator(input_vector[i])
      time_cache_tbl <- toc(quiet = TRUE)
      result_cache_tbl[j] <- time_cache_tbl$toc - time_cache_tbl$tic
      tic()
      dtb_creator(input_vector[i])
      time_cache_dtb <- toc(quiet = TRUE)
      result_cache_dtb[j] <- time_cache_dtb$toc - time_cache_dtb$tic
    }
    iteration_output <- data.frame(result_cache_dfr, result_cache_tbl, result_cache_dtb)
    colnames(iteration_output) <- c(dfr_names[i], tbl_names[i], dtb_names[i])
    output <<- data.frame(output, iteration_output)
  }
  output <<- output[-1]
  beep(sound = "facebook")
}


#### EXECUTION ALGORITHM 2
# yielded the data for chart 2
# input used:

tic()
creator_comparison_second(c(10000, 100000, 1000000, 100000000), 50)
toc()

#the only difference to the execution algorithm 1 is that different functions for the creation of the datasets are used

creator_comparison_second <- function(input_vector, iterations){
  scenario_n <- length(input_vector)
  simulation_n <- iterations
  dtb_names <-  vector(length = scenario_n)
  dtb_dfr_names <-  vector(length = scenario_n)
  dtb_tbl_names <-  vector(length = scenario_n)
  result_cache_dtb <- vector(length = simulation_n)
  result_cache_dtb_dfr <- vector(length = simulation_n)
  result_cache_dtb_tbl <- vector(length = simulation_n)
  output <<- vector(length = simulation_n)
  for(i in 1 : scenario_n){
    dtb_names[i] <- paste("dtb_",i, sep = "")
    dtb_dfr_names[i] <- paste("dtb_dfr_",i, sep = "")
    dtb_tbl_names[i] <- paste("dtb_tbl_",i, sep = "")
    for(j in 1 : simulation_n){
      tic()
      dtb_creator(input_vector[i])
      time_cache_dtb <- toc(quiet = TRUE)
      result_cache_dtb[j] <- time_cache_dtb$toc - time_cache_dtb$tic
      tic()
      dtb_tbl_creator(input_vector[i])
      time_cache_dtb_dfr <- toc(quiet = TRUE)
      result_cache_dtb_dfr[j] <- time_cache_dtb_dfr$toc - time_cache_dtb_dfr$tic
      tic()
      dtb_dfr_creator(input_vector[i])
      time_cache_dtb_tbl <- toc(quiet = TRUE)
      result_cache_dtb_tbl[j] <- time_cache_dtb_tbl$toc - time_cache_dtb_tbl$tic
    }
    iteration_output <- data.frame(result_cache_dtb, result_cache_dtb_dfr, result_cache_dtb_tbl)
    colnames(iteration_output) <- c(dtb_names[i], dtb_dfr_names[i], dtb_tbl_names[i])
    output <<- data.frame(output, iteration_output)
  }
  output <<- output[-1]
  beep(sound = "facebook")
}
