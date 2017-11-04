# Comparison 1: Creating a Test Dataset - data.frame vs. tibble vs. data.table

## Intro

Currently, I am reading [R for Data Science](http://r4ds.had.co.nz/) to immerse myself in the tidyverse. The tidyverse includes many functions that represent updated, faster versions of their Base R counterparts. According to the authors of the book, `read_csv()` is about 10x faster than `read.csv()`. Also, the tidyverse uses its own kind of data frames, the tibble.

When I want to check whether the stuff I code actually does what it is supposed to do, I usually use test datasets for evaluation, which consist of random numbers. After reading about tibbles, I was curious; similarly to `read_csv()`, **does creating a dataset by using `tibble()`require less computation time than using `data.frame()` ?**

Furthermore, I was interested in how tibbles and data.frames compare to data.tables. The data.table package (which is well-known for its efficiency) comes with its own data frame too. Thus, I examined the following question: **which one is the fastest in creating a test dataset—`data.frame()`, `tibble()`, or `data.table()` ?**

First, I created a function that creates a 3-vector dataset for each of these three data frames, where the number of rows is subject to a parameter (i.e. `n`). The functions look like this:

For data.frame:
```R
dfr_creator <- function(n){
  data.frame(
    "x" = runif(n, min = 1, max = 100), 
    "y" = rnorm(n, mean = 50, sd = 4), 
    "z" = rlnorm(n, meanlog = 2, sdlog = 1)
  )
}
```

For tibble:
```R
tbl_creator <- function(n){
  tibble(
    x = runif(n, min = 1, max = 100), 
    y = rnorm(n, mean = 50, sd = 4), 
    z = rlnorm(n, meanlog = 2, sdlog = 1)
  )
}
```

For data.table:
```R
dtb_creator <- function(n){
  data.table(
    x = runif(n, min = 1, max = 100), 
    y = rnorm(n, mean = 50, sd = 4), 
    z = rlnorm(n, meanlog = 2, sdlog = 1)
  )
}
```

Just like for the test datasets I usually create, I generated random numbers by the use of distribution functions. Note that the distribution functions, as well as the corresponding parameters, are completely arbitrary.

The relative performance of these 3 functions depends on two aspects. On one side, the row numbers are likely to be an important determinant. On the other side, there is some variability regarding the execution time it takes to run the functions, since a computer does a bunch of other tasks at the same time. Therefore, **the functions were compared for several sizes** of the datasets (namely **10K, 100K, 1M, and 100M**), and **each function was, for a given dataset size, run 50 times**. A documented version of the algorithm used for this comparison can be found in …

For this investigation, the execution algorithm generated **45 499 500 000** (i.e. 45 bn) **random numbers!** The chart below shows the average computation time (the "whiskers" represent 95% confidence intervals of the average time) the three functions required for each of the four dataset sizes. 

Chart 1:
![alt text](https://github.com/SimonGsponer/r_comparisons/blob/first_comparison/images/Comparison1_Results1.jpeg "Computation Time for Creating a 3-Column Dataset")




Here we go again: 
![alt text](https://github.com/SimonGsponer/r_comparisons/blob/first_comparison/images/Comparison1_Results2_edit.jpeg "Computation Time for Creating a 3-Column Dataset - Second Round")


