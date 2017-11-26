# Comparison 3: for loop vs. apply

Estimated reading time: 7 min

Overview
1. [Intro](#introduction)
2. [Method](#method)
3. [Results](#results)
4. [A few concluding words](#conclusion)

## Intro <a name="introduction"></a>

Suppose you have to run a function on every row of a dataset. For example, you may want to compute the **moving average** of some financial data. In a nutshell, a moving average is the average value of the last *n* observations. The following dataset illustrates a moving average with *n=3*:

```R
# A tibble: 10 x 2
   `fictitious price` `moving average`
		<int>            <dbl>
 1                  1               NA
 2                  2               NA
 3                  3                2
 4                  4                3
 5                  5                4
 6                  6                5
 7                  7                6
 8                  8                7
 9                  9                8
10                 10                9
```

*(Note: The first two rows have an NA in the 'moving average' column because there is not enough information to calculate the 3-observation moving average. For the algorithms used in this comparison, I included a smoothing method to circumvent this problem: When fewer observations than required are available, the moving average consists of the number of observations available.)*

In order for calculating the moving average (or any other computation that has to be done row-wise), `for loops` and `apply functions` are used oftentimes.

A function using a `for loop` for calculating a moving average would look like this:

```R
MA_loop <- function(data_dfr, price_col, window_length){
	# find the length of the dataframe
	table_length <- nrow(data_dfr) 
	# define vector that stores the result
	simple_ma <- vector(length = table_length) 
	# for loop
	for(i in 1 : table_length){ 
		#smoothing method, which circumvents the problem of having NA's in the first few rows (cf. example above)
		t <- max(i - window_length + 1, 1) 
		#compute the average for the given range
		simple_ma[i] <- mean(data_dfr[t : i, price_col])
	}
	# save the result
	loop_output <<- data.frame(data_dfr, simple_ma)
}
```

It's 'apply' counterpart would be:

```R
MA_apply <- function(data_dfr, price_col, window_length){
	# find the length of the dataframe
	table_length <- nrow(data_dfr)
	# define vector that stores the result
	simple_ma <- vector(length = table_length)
	# apply function, performing the same computations as the for loop
	simple_ma <- sapply(1 : table_length, function(x){
		mean(data_dfr[max(x - window_length + 1, 1) : x, price_col])
	})
	# save the result
	apply_output <<- data.frame(data_dfr, simple_ma)
}
```
*(Note: In this context, the `sapply` function is most sensible to use.)*

**But which of these two approaches is faster?** By default, R runs on one core of your computer. In this case, the consensus of the [R community](https://stackoverflow.com/questions/7142767/why-are-loops-slow-in-r/7142982#7142982) is that the two functions are equally efficient. These days, every computer has a multi-core processor. For example, my vanilla MacBook Air has four cores, which means that, roughly speaking, 1 core is used for R computations and another one is used for all other tasks a computer has to run at the same time; **this leaves 2 cores idling!** Therefore, the question of today's episode of R comparisons is: **How do `for loops` and `apply functions` compare when more than one core is used, i.e. when a task is parallelised?**

## Method <a name="method"></a>

For this comparison, I am going to use a **computationally simple** and **complex task**. The former is a trivial task for a computer and requires virtually no time. A moving average is a very representative example of this category. On the other hand, a computationally complex task is one that becomes much more difficult every time a new data point is included. For example, computing the average Euclidean distance from each data point to all others is a complex task. Let's illustrate this distinction: For the comparison that follows, I am going to use stock market data of [General Electric](https://www.ge.com/) as my input data (about 14 000 days), which I had retrieved from [Quandl](https://www.quandl.com). The last observation in the dataset is from Friday, the 15th of November 2017, where the closing price of GE was $ 18.26. Now, suppose we add the information of the price on the following Monday to the dataset. For the moving average, only the newest average has to be calculated. Conversely, for the average Euclidean distance, all prior calculations have to be re-done, and each calculation had just gotten slightly more difficult (because for every data point, the distance to the new observation has to be considered too).

For the computationally simple task, I computed the 3-day moving average. For the complex task, I computed the average Euclidean distance from a given day's price to all other days' prices (the results are obviously nonsense, but they serve the purpose). Each specification was executed 10 times, and the computational time was recorded by the use of the [tictoc](https://cran.r-project.org/web/packages/tictoc/index.html) package. For parallelising `for loops` and `apply functions`, I used the [foreach](https://cran.r-project.org/web/packages/foreach/foreach.pdf) and [doParallel](https://cran.r-project.org/web/packages/doParallel/doParallel.pdf) package. All the functions as well as the execution algorithms can be found [here](Rscripts/Comparison3.R). Overall, this comparison looks at 2 approaches (**`for loop`** vs **`apply function`**), 2 computational environments (**single-core** vs **multi-core**), and 2 kinds of tasks (computationally **simple** vs **complex**), leading to 8 specifications.


## Results <a name="results"></a>

The chart below shows the average computation time (the "whiskers" represent 95% confidence intervals of the average time) the `for loops`
 and the `apply functions` required for the simple/complex task in a single-core/multi-core environment:

![alt text](/images/Comparison3_Result1.jpeg "Comparison 3: Results")

* For the computationally simple task, using one core is more efficient. When a task is assigned to more than one core, your computer has to do additional tasks for managing the work across the cores. These additional tasks, often referred to as *overhead*, make the single-core environment faster.

* The parallelised `for loop` has a greater overhead than the parallelised `apply function`. This can be seen from both the simple as well as complex task; the average computational time is much lower for the `apply function`.

* For the computationally complex task, both parallelisations are more efficient than their single-core counterparts.

## A few concluding words <a name="conclusion"></a>

The old myth says that one should not use `for loops` but `apply functions` when trying to vectorise a function. While this is clearly wrong when using one core (`for loops` are even slightly faster), it is true when parallelising a task. Therefore, my conclusion from this comparison is:

* First and foremost, parallelisation is only useful when dealing with complex tasks—you shouldn't use several cores for everything!

* When you want to apply a function row-wise and you want to save some time (either because the task itself is complex or you are dealing with big data), a parallelised `apply function` can speed up the process.

* Given that the parallelised `for loop` creates a larger overhead (for a stackoverflow post on this, click [here](https://stackoverflow.com/a/5015485/8718701)), `for loops` can be effectively parallelised by assigning large tasks to each core at once. An efficient implementation of a parallelised `for loop` for the complex task would require to split the dataset into three parts, where each of the three cores computes the Euclidean distances for the assigned sub-dataset.

* This comparison looked at the vectorisation of functions and compared `for loops` and `apply functions`. While `apply functions` can only be used for vectorisation, `for loops` can be used for anything that requires iteration. Thus, when trying to speed up an iterative process that is not about vectorisation (examples are resampling, cross-validation, or performing a task across several columns), the parallelised `for loop` is the right choice.
