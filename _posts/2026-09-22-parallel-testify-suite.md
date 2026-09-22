---
title: "The Parallel Testify Suite"
date: 2026-09-22 10:00:00 +0530
categories: [Software]
tags: [Go, Testing, testify, Parallel tests]
description: Why stretchr/testify's Suite cannot run parallel tests, and how a generics-based fork fixes it
media_subpath: /assets/img/posts/parallel-testify-suite
---

You can find the repository here - [testify](https://github.com/varunbpatil/testify).

The [stretchr/testify](https://github.com/stretchr/testify) suite is the closest thing Go has to JUnit-style test classes. It gives you `SetupSuite`/`SetupTest`/`TearDownTest` hooks, a baked-in `assert`/`require`, and each `Test*` method runs as a proper subtest, so `go test -run TestSuite/TestOne` works. It is a lot of boilerplate removed.

There is one giant hole though: you cannot run your tests in parallel. Call `t.Parallel()` inside a test method and everything quietly breaks - teardown runs before the test body, and the whole suite shares one mutable struct across goroutines. Parallel support has been requested upstream over the years and closed as not planned, because doing it properly needs breaking changes.

This project is a fork that fixes exactly that. It keeps the same hooks and the same ergonomics, and the whole suite - tests *and* subtests - becomes parallel-safe.

## Why `parallel()` doesn't work there

Two independent problems, and either one alone is enough to sink it.

### One instance, shared by every test

The original suite runs all test methods against a **single** instance of your suite struct. Before each test it just swaps the context in place:

```go
func Run(t *testing.T, suite TestingSuite) {
	suite.SetT(t)
	// ...
	for _, test := range tests {
		t.Run(test.Name, test.F)
	}
}

// inside the per-test function:
F: func(t *testing.T) {
	parentT := suite.T()
	suite.SetT(t)          // one shared instance, one shared `t`
	defer func() {
		// ... teardown ...
		suite.SetT(parentT)
	}()
	method.Func.Call(...)
}
```

That is fine when tests run one at a time. The moment two tests run in parallel, both `SetupTest()` and the user's test body write per-test data onto the **same struct**, and both tests fight over the same `t` for their assertions. Data races and garbled test output are guaranteed.

### Teardown via `defer` runs too early

This is the subtle one. All teardown in the original is wired with `defer`, including suite-level teardown:

```go
defer func() {
	if tearDownAllSuite, ok := suite.(TearDownAllSuite); ok {
		tearDownAllSuite.TearDownSuite()
	}
}()
```

Now recall how Go schedules parallel subtests: when a subtest calls `t.Parallel()`, it **pauses** - the code after `Parallel()` has not run yet. The parent keeps going and eventually returns. Only after the parent test function has fully returned do the paused tests get scheduled to run.

In the original suite, the "parent" is the suite's `Run` function. So with parallel tests, this happens:

1. `Run` launches `TestOne`, `TestTwo`, ...
2. Each test method calls `t.Parallel()` and pauses.
3. `Run` finishes its loop and **returns** - and its deferred `TearDownSuite()` runs right now.
4. Only then do the parallel test bodies actually execute.

Teardown before the tests have even started. This is precisely why [Go 1.14 introduced `testing.T.Cleanup`](https://pkg.go.dev/testing#T.Cleanup): cleanup functions are guaranteed to run only after the test *and all of its parallel subtests* have completed. `defer` cannot give you that ordering; `Cleanup` can.

## The fix: an instance per test, teardown via Cleanup

The fix has two parts, and generics make the first one possible.

**A fresh suite instance per test.** The suite type is now a generic `*suite.Suite[T, G]` embedded in your struct. Every test and every subtest gets its own `new(T)` - its own `testing.T`, its own `assert`/`require`, its own per-test data fields. Nothing is shared between parallel tests, so there is nothing to race on.

**All teardown via `t.Cleanup`.** `TearDownTest`, `TearDownSubTest` and `TearDownSuite` are registered with `t.Cleanup(...)`, which the testing framework only invokes after every parallel subtest has finished. The ordering the original suite could never get - teardown after all parallel work - now comes from the testing package itself, in the correct LIFO order.

![architecture](/architecture_diagram.svg)

## Global and local data

Parallel tests need *some* isolated state, and suites need *some* shared state. The two generic parameters make the split explicit:

```go
type OrderSuite struct {
	// This must be embedded.
	*suite.Suite[OrderSuite, GlobalData]

	// Per-test data - unique to each test/subtest.
	priceCalc *PriceCalculator
}

// Global data - one instance per suite run, shared by all tests.
type GlobalData struct {
	DB *sql.DB
}
```

Local data lives on the suite struct and is zero-valued for every new test instance. Global data lives in `G` and is created once per `Run`, then threaded through every instance - set it up in `SetupSuite`, read it anywhere via `s.G()`.

## What it looks like

```go
func TestOrderSuite(t *testing.T) {
	t.Parallel()
	suite.Run[OrderSuite, GlobalData](t)
}

func (s *OrderSuite) SetupSuite() {
	s.G().DB = connectToTestDB()
}

func (s *OrderSuite) TestOne() {
	s.Parallel()                          // this just works now
	s.priceCalc = NewPriceCalculator()    // per-test data

	for _, v := range []string{"sub1", "sub2", "sub3"} {
		s.Run(v, func(sub *OrderSuite) {
			sub.Parallel()                // parallel subtests, nested
			sub.T().Log(sub.G().DB.Name())  // global data is shared
		})
	}
}

func (s *OrderSuite) TearDownSuite() {
	s.G().DB.Close()
}
```

`go test -run TestSuite/TestOne/sub2` still works, because every test and subtest is a real subtest. The `-testify.m` method filter works too, plus a new `-testify.x` flag that does the opposite - exclude tests matching a regex.

## Trade-offs

- **You own global data synchronization.** `SetupSuite` runs before any test starts, so reads of `G` are safe everywhere, but if two parallel tests mutate the same global field, that is a race you must lock yourself.
- **One semantic change you will hit:** subtest instances are zero-valued, so data set in `SetupTest()` is not copied into subtests. Reach back to it explicitly via `sub.Parent().someField`.
- **Go 1.18+** for generics.
- VSCode CodeLens needs an (otherwise useless) blank import of the original `stretchr/testify/suite` package. It exists solely so vscode-go shows "run test" / "debug test" actions inline above each `Test*` method - a quirk of the extension.

The testing package got the hardest piece right in 1.14. All this project does is stop fighting it: one instance per test, `Cleanup` for teardown, and explicit global data. The suite you know, minus the "cannot run in parallel" asterisk.