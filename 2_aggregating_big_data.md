# Comparison 2: Aggregating a 30-M-observations dataset

Estimated reading time: 5 min 12 sec

Overview
1. [Intro](#introduction)
2. [Method](#method)
3. [Results](#results)
4. [A few concluding words](#conclusion)

## Intro <a name="introduction"></a>

Hi there and welcome to comparison № 2! 

The [World Development Indicators dataset](https://data.worldbank.org/data-catalog/world-development-indicators) of the World Bank, which has about 400 000 rows, is the largest dataset I have ever worked with. While it is certainly too big for MS Excel, it's still far from being big data. For this comparison, I wanted to venture into the (for me personally) uncharted waters of analysing truly big data, which is why I came up with the following question: **How well do Base R, the [tidyverse package](https://www.tidyverse.org/), and the [data.table](https://github.com/Rdatatable/data.table/wiki) package perform when aggregating information from a dataset with 30 million rows?**  

*This comparison revolves around big data—but what is big data in the first place? Unfortunately, there is not really an official definition, but a practical one would describe big data as data that is so large that it doesn't fit into the RAM (the working memory) of your computer. Thus, this means that big data is probably one of the most relative terms of the computer science jargon: whether data is truly big depends on one's machine. (My mainstream Apple laptop has 4 GB of RAM, while the supercomputer of IBM has [16 TB of RAM](https://www.csee.umbc.edu/2011/02/is-watson-the-smartest-machine-on-earth/).) Therefore, when I talk about big data in this comparison, I mean files that require swap memory when I load them into my 4GB RAM.*

## Method <a name="method"></a>

### The Dataset

**How do I get a dataset with 30 000 000 observations?** First, I extracted all non-cancelled flights from the [nycflights13](https://github.com/hadley/nycflights13) database, which includes all outbound flights from NYC airports in 2013. This gave me 327 346 observations.

The first 10 observations of the dataset:

```R
# A tibble: 327,346 x 13
	year month   day dep_time sched_dep_time dep_delay arr_time sched_arr_time arr_delay carrier flight air_time distance
   <int> <int> <int>    <int>          <int>     <dbl>    <int>          <int>     <dbl>   <chr>  <int>    <dbl>    <dbl>
 1  2013     1     1      517            515         2      830            819        11      UA   1545      227     1400
 2  2013     1     1      533            529         4      850            830        20      UA   1714      227     1416
 3  2013     1     1      542            540         2      923            850        33      AA   1141      160     1089
 4  2013     1     1      544            545        -1     1004           1022       -18      B6    725      183     1576
 5  2013     1     1      554            600        -6      812            837       -25      DL    461      116      762
 6  2013     1     1      554            558        -4      740            728        12      UA   1696      150      719
 7  2013     1     1      555            600        -5      913            854        19      B6    507      158     1065
 8  2013     1     1      557            600        -3      709            723       -14      EV   5708       53      229
 9  2013     1     1      557            600        -3      838            846        -8      B6     79      140      944
10  2013     1     1      558            600        -2      753            745         8      AA    301      138      733
# ... with 327,336 more rows 
```
*(Note: I omitted the rows 'origin', 'dest', 'tailnum', 'hour', 'minute', 'time_hour' as I will not use them later on.)*

Now, I coded my own **bootstrapping algorithm** to artificially inflate the dataset. Basically, bootstrapping is to continuously resample with replacement. Accordingly, the probability of an observation of the original dataset to be duplicated is **always 1/(the number of all observations)**. I'll spare you guys the details about bootstrapping since they are not that relevant right now; also, I plan to do an R comparison about building an efficient bootstrapper anyways.

I used my bootstrapper to increase the dataset by about 6.5 M observations. Subsequently, I duplicated these 6.5 M 'extra' observations four times, which gave me a > 30 M dataset. Thus, the dataset I used for the subsequent analysis consisted of:

* The 327 346 non-cancelled flights that come from the nycflights13 database
* The roughly 6.5 M observations that were artificially created from the original 327 346 non-cancelled flights, which were duplicated four times in order for achieving the desired dataset size

At first, I wanted to bootstrap all extra observations. However, it turned out that bootstrapping millions of observations is a very time-consuming task, which is why I chose to speed up this process by the use of simple duplication. (We'll definitely come back to bootstrapping later on; I really want to figure out how to build an efficient bootstrapper for big data.) **The final csv file had a size of 1.5 GB and contained 31 408 651 observations.**

### The Task

In the above-shown tibble, the third observation represents a plane from the carrier AA (American Airlines), where this flight flew for 160 minutes and covered a distance of 1089 miles. **But what is the average air time and distance for each carrier?**

In Base R, one can figure this out by using the `aggregate()` command:

```R
aggregate(nyc_flights_big_data[, c("air_time", "distance")], 
	by = list(nyc_flights_big_data$carrier), 
	FUN = mean
	)
```

The first part of the syntax states the columns to be aggregated. In the second part, the `by` argument specifies how the entire dataset should be subsetted (i.e. by carrier). The last part states the functions which should be used for aggregation, which is `mean()`here.

In the tidyverse, the following command is used:

```R
nyc_flights_big_data %>% 
	group_by(carrier) %>% 
	summarise(average_dist = mean(distance),
		  average_time = mean(air_time)
	)
```

Note how easy it is to read the syntax.

The corresponding command in the data.table package is:

```R
nyc_flights_big_data[, j=list(mean(air_time), mean(distance)), 
             by = carrier
             ]
```

Now, I **compared these three commands by executing each 50 times**. The computation times were recorded by using the [tictoc package](https://cran.r-project.org/web/packages/tictoc/index.html). For the curious, the execution algorithm as well as the bootstrapping algorithm can be found [here](Rscripts/Comparison2.R).

## Results <a name="results"></a>

The chart below shows the average computation time (the "whiskers" represent 95% confidence intervals of the average time) the three functions required for processing the respective command. 

_Chart 1_

![alt text](/images/Comparison2_Results1.jpeg "Comparison 2: Results")

* **Base R does not seem to be the right choice for analysing big data**. While your computer is unlikely to hang up or catch fire from using Base R, it is very slow. Notwithstanding, it is imporatant to mention that big data *can* be analysed in Base R, which may come as a suprise to people who are new to R.

* **While both the tidyverse and the data.table package are very fast, the latter is the clear winner.** The average computation time for executing the command was 2.43 sec and 1.17 sec respectively. It took the average data.table command a little bit longer than one second to query and transform a dataset with 30 M observations!

## A few concluding words <a name="conclusion"></a>

From this comparison, the data.table package emerged as the clear winner, which is rather unsurprising since this package was designed for dealing with huge amounts of data. **Does this mean that one should always use data.table for such tasks?** Imagine you are working in a position where you have to analyse a fairly large amount of data (say 0.5 M observations) and you are asked to share your work with other people who are not programmers themselves. Now, the tidyverse is clearly the better option as it offers easy-to-read syntaxes that execute quickly.

Note: These results apply primarily to data analyses that are performed on ordinary computers. When analysing *big big data* (say a 500 GB file), the tidyverse package might be too slow (and Base R might not execute a command in the foreseeable future).
