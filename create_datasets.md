# Create Datasets

## data.frame vs. tibble vs. data.table

Currently, I am reading [R for Data Science](http://r4ds.had.co.nz/) to immerse myself in the tidyverse. The tidyverse includes many functions that represent updated, faster versions of their Base R counterparts. According to the authors, read_csv is about 10x faster than read.csv. 

When i want to check whether the stuff I code actually does what it is supposed to do, I usually use test datasets, consisting of random numbers, for evaluation. After reading about tibbles, I was curious: Similar to read_csv, do tibbles create random datasets considerably faster than data.frames?
