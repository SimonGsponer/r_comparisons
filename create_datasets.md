# Create Datasets

## data.frame vs. tibble vs. data.table

Currently, I am reading [R for Data Science](http://r4ds.had.co.nz/) to immerse myself in the tidyverse. The tidyverse includes many functions that represent updated, faster versions of their Base R counterparts. According to the authors, `read_csv()` is about 10x faster than `read.csv()`. Also, the tidyverse uses its own kind of data frames, the tibble.

When I want to check whether the stuff I code actually does what it is supposed to do, I usually use test datasets, consisting of random numbers, for evaluation. After reading about tibbles, I was curious: Similarly to `read_csv()`, **does creating a dataset by using `tibble()`require less computation time than using `data.frame()` ?**

This prompted me to start a little experiment, in which I wanted to formally examine this question. Furthermore, I was interested in how tibbles and data.frames compare to data.tables. Similar to the tidyverse, the data.table package (which is well-known for its efficiency) comes with its own data frame. Thus, the question was: **which one is the fastes in creating a test dataset: `data.frame()`, `tibble()`, or `data.table()` ?**

First, I created a function that crates a 3-vector dataset for each of these three data frames, where the number of rows is subject to a parameter (i.e. `n`). The functions look like this:

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

Just like in the test datasets I usually create, I generated random numbers by the use of distribution functions. Note that the distribution functions, as well as the corresponding parameters, are completely arbitrary.


