---
layout: post
title: "TIL about functools.lru_cache - Automatically caching function return values in Python"
---

This is a short demonstration of how to use the __functools.lru_cache__ module to
automatically cache return values from a function in Python instead of explicitly
maintaining a dictionary mapping from function arguments to return value.

The __functools.lru_cache__ module implicitly maintains a dictionary and also
provides memory management. Since it uses a dictionary to map function arguments
to return values, all the __function arguments should be hashable__ (so that it can
be used as a dictionary key).

I found this very useful in processing rows of a large Pandas dataframes in
machine learning where I was performing some computation involving some of the
values in a row which may be repeated.

The following is a jupyter notebook demonstrating it's effectiveness on a simple
recursive problem.



__The problem of making change using the fewest coins:__

Given an amount and the denominations of all available coins, 
we would like to make change for that amount using the least 
number of coins possible.

The following is a recursive solution to the problem.


```python
def min_coins(denominations, amount):
    """
    denominations - The available coin denominations (a tuple)
    amount        - The amount we want to make change for
    
    Returns the minimum number of coins required to make change
    for the given amount using coins of given denominations.
    """
    
    if amount == 0:
        return 0
    
    elif amount in denominations:
        return 1
    
    else:
        v = []
        for d in [d for d in denominations if d <= amount]:
            v.append(min_coins(denominations, amount-d))

        try:
            r = 1 + min(v)
        except:
            # In case 'v' is empty, it is
            # not possible to make change for that amount.
            r = float('inf')

        return r
```

__Now, let us measure the time it takes to run the above function to make change for 63 cents using coins of denomination __1, 5, 10 and 25 cents.__


```python
%timeit -n1 -r3 print(min_coins((1,5,10,25), 63))
```

    6
    6
    6
    49.8 s ± 397 ms per loop (mean ± std. dev. of 3 runs, 1 loop each)


__We can see that it takes approximately 50 seconds to get the solution to such a simple problem.__

The reason it takes so long even for such a simple problem is that the solutions to intermediate problems are recomputed more than once.

It would be much more efficienty if we can remember the solution to intermediate subproblems instead of recomputing it again (memoization).

One way would be to maintain an explicity dictionary of return values for input argument.

There is a simpler way though. All we have to do is decorate the function with __functools.lru_cache__ and let Python handle the caching for us. As you will see below, this is just one extra line of code at the top of the function.

__Decorating the function to automatically cache return values.__


```python
from functools import lru_cache

@lru_cache(maxsize=None)
def min_coins_cached(denominations, amount):
    """
    denominations - The available coin denominations (a tuple)
    amount        - The amount we want to make change for
    
    Returns the minimum number of coins required to make change
    for the given amount using coins of given denominations.
    """
    
    if amount == 0:
        return 0
    
    elif amount in denominations:
        return 1
    
    else:
        v = []
        for d in [d for d in denominations if d <= amount]:
            v.append(min_coins_cached(denominations, amount-d))

        try:
            r = 1 + min(v)
        except:
            # In case 'v' is empty, it is
            # not possible to make change for that amount.
            r = float('inf')

        return r
```

__Now, let us measure the time take by this function to compute the solution for the same problem as before.__


```python
%timeit -n1 -r3 print(min_coins_cached((1,5,10,25), 63))
```

    6
    6
    6
    The slowest run took 14.62 times longer than the fastest. This could mean that an intermediate result is being cached.
    194 µs ± 124 µs per loop (mean ± std. dev. of 3 runs, 1 loop each)


__We can see a drastic improvement in performance - From approximately 50 seconds to approximately 194 micro seconds.__
