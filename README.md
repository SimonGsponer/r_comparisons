**Welcome to the r_comparisons repository! In a nutshell, this repository is about looking at and comparing different means that achieve the same objective in R.**

### Comparison 1: data.frame() vs. tibble() vs. data.table()
The first comparison investigates whether data.frames, tibbles, and data.tables differ in the computational time they need for creating a dataset with random numbers. Read the post [here](1_creating_a_dataset_DF_TBL_DT.md).

### Comparison 2: aggregating big data—Base R vs the tidyverse package vs the data.table package
Comparison № 2 assesses the performance of Base R, the tidyverse package, and the data.table package when running an aggregation command for big data. Read the post [here](2_aggregating_big_data.md).

### Comparison 3: for loops vs apply functions in a multi-core environment
When vectorising a function, the general consensus is that `for loops` and `apply functions` do equally well. However, this applies only to the case where one core of your CPU is used for all the computations. Episode 3 of R comparisons investigates whether there is a difference between these two approaches when the work is done by several cores. Read the post [here](3_forloop_apply.md).

### Comparison 4: resampling with replacement
Episode 4 of r_comparisons looks at the resampling algorithm I used in Comparison 2 and compares it to other approaches. Read the post [here](4_resampling_algorithms.md).

