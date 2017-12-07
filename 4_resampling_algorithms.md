# Comparison 4: Resampling Algorithms (With Replacement)

Estimated reading time: 5 min 30 sec

Overview
1. [Intro](#introduction)
2. [The Resampling Algorithms](#method)
3. [First Results](#results1)
3. [Second Results](#results2)
4. [A few concluding words](#conclusion)

## Intro <a name="introduction"></a>

In [Comparison 2](3_forloop_apply.md), I used a resampling algorithm to artificially increase the number of observations of the [`nycflights13:flights`](https://github.com/hadley/nycflights13) dataset. It struck me that the resampling process took a lot of time, which prompted me to compare different resampling algorithms in this episode of r_comparisons. In case you are interested in the coding, click [here]().
*(Note: When I am talking about **resampling** in this comparison, I mean **resampling with replacement**. When resampling with replacement, the probability of a given row to be resampled is always 1/(the total number of rows).)*

## The Resampling Algorithms <a name="method"></a>

In Comparison 2, the resampling algorithm which I coded ran through the following steps:

1. Determine the observations that should be resampled.

2. Summarise this list: Which observations have to be resampled more than once? For example, observation #5609 might have been chosen 4 times. Accordingly, this summarised list shows every observation that was chosen to be resampled + the number of times it was chosen.

3. For every row of this summarised list, resample the given row *n* times (*n* indicates the frequency) and add this resampled observation to the `output dataset` (which is empty at the beginning). Taking the example from above, observation #5609 would be resampled 4 times in one single step. The `output dataset` grows with every resampled observation.

4. Return the final `output dataset`.

The illustration below shows the same information more visually:

![illustration 1](/images/Comparison4_Illustration1.jpg "Illustration 1")

Back in Comparison 2, I had already realised that this algorithm could probably be improved, given the enormous amount of time it took to resample the observations. I improved this algorithm by i) re-building it in the `[data.table](https://cran.r-project.org/web/packages/data.table/index.html) package and ii) using 3 cores of my 4-core CPU to do the resampling. 

Illustration #2 shows the design of the improved version:

![illustration 2](/images/Comparison4_Illustration2.jpg "Illustration 2")

Besides improving the algorithm from Comparison 2, I consulted google about how other people resample in R. Google was more than happy to help and referred me to a StackOverflow user called andreister, who used the following code to resample a dataset (read the SO post of andreister [here](https://stackoverflow.com/questions/18385099/random-subsampling-in-r/18385168#18385168)). andreister's solution is:

```R
data.frame[ sample(1 : nrow(data.frame), number of observations to resample, replace = TRUE), ]
```

At this point, it is important to understand the bracket notation R uses. A dataset can be subsetted by specifying the desired rows and columns within the brackets, where the desired rows are put first (i.e. `data.frame[desired rows, desired columns]`. Moreover, the *desired rows* can include a certain row several times, making this solution so simple and beautiful: instead of *explicitly* resampling every selected observation and adding them to the output dataset, this approach *implicitly* specifies the output dataset by taking the original dataset and selecting those rows that are desired. It is already pretty obvious that this approach is likely to outperform the ones I had come up with so far—but how big will the difference be?

The solution by andreister represents the benchmark for evaluating the efficiency of my algorithms. Therefore, I coded two other algorithms that were inspired by this solution. First, I re-wrote andreister's solution in the `data.table package`, leading to:

```R
data.table[ sample(1 : nrow(data.table), number of observations to resample, replace = TRUE), ]
```

Second, I parallelised the `data.table` version of andreister's approach. The resulting design looks similar to the one used in my improved resampling algorithm (cf. Illustration 2):

![illustration 3](/images/Comparison4_Illustration3.jpg "Illustration3")

Overall, I am going to compare 5 resampling algorithms at first:

1. My resampling algorithm from Comparison 2 (henceforward referred to as 'Comparison 2')

2. The improved version of 'Comparison 2' (henceforth referred to as 'Comparison 2 more efficient')

3. andreister's approach ('Base R')

4. The `data.table` version of 'Base R' ('data.table')

5. The parallelised version of 'data.table' ('parallelised data.table')

This first round compares the 5 algorithms when resampling 10 000 observations of the `nycflights13:flights` dataset. As before, I used the `[tictoc](https://cran.r-project.org/web/packages/tictoc/index.html) package` for recording the computational time required, where each resampling algorithm was executed 5 times.

## First Results <a name="results1"></a>

The chart below shows the average computational time (the "whiskers" represent 95% confidence intervals of the average time) the 5 algorithms required for this task:

![alt text](/images/Comparison4_Result1.jpeg "Comparison 4: First Results")

Well, this is somewhat embarrassing for me. The solutions I came up with initially ('Comparison 2' & 'Comparison 2 more efficient') perform horribly compared to the others. No wonder it took me ages to resample the dataset in Comparison 2: The algorithm I used is simply a synonym for inefficiency.

## Second Results <a name="results2"></a>

But how do my other specifications compare to andreister's approach? For this, I ran a second comparison, in which I let the algorithms resample 100, 1 000, 10 000, 100 000, 1 000 000, and 10 000 000 observations of the `nycflights13:flights` dataset; where each algorithm was executed 10 times for the given number of resampled observations. The results are:

![alt text](/images/Comparison4_Result2.jpeg "Comparison 4: Second Results")

From the two plots, one can see that 'data.table' outperforms andreister's solution for 10 000 or more resampled observations. The 'parallelised data.table' approach is the most efficient choice when the resampling leads to a 'big' dataset (i.e. 10 million observations in this case).

## A few concluding words <a name="conclusion"></a>

From this comparison, I learned two very important things:

* **First and foremost, don't re-invent the wheel.** Before coding the resampling algorithm for Comparison 2, I should have checked the web for how people had already tackled this problem. If you don't do state-of-the-art coding (like programming some advanced neural nets), it is very likely that someone has posted a solution to your problem online.

* **Notwithstanding, dare to 'tune' the wheel.** Use what there already is as an inspiration, and think about how the given solution can be further improved. I was able to significantly improve the solution of andreister by simply using a `data.table` instead of a `data.frame`. 
