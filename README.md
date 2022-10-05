# Lab 2: Clocks

**Due:** October 15, 2022 9pm

**NOTE:** [Hand-in instructions](#handing-in) are at the end of this document. 
It is very important you follow these instructions. Failure to do so might result
in receiving 0 on this lab.

## Introduction
In this lab you will implement Lamport clocks, and vector clocks. 
While we covered the former in class, the later track causality and we have not
talked about them before. You might want to read [this
paper](https://cs.nyu.edu/~apanda/classes/fa21/papers/fidge88timestamps.pdf),
[this
video](https://www.oreilly.com/library/view/distributed-systems-in/9781491924914/video215280.html)
or Wikipedia to understand that.
Please make sure
you have read the papers corresponding with this before beginning the lab.
The instructions that follow are not nearly as detailed as the instructions
for Lab 1, this is because we assume that you already know Elixir, and we
only provide information about the code when it is particularly different
from what you have seen in the past. You might find these
[notes](https://cs.nyu.edu/~apanda/classes/fa20/notes/elixir-help.pdf),
specifically the bit about 
[Map.merge/3](https://hexdocs.pm/elixir/Map.html#merge/3)
useful.

All your work in this lab goes into `apps/lab2/time_lab.ex`.

## Getting Started
To create a repository for Lab 2 go to the URL 
[https://classroom.github.com/a/Q6dK5USF](https://classroom.github.com/a/Q6dK5USF)
after logging into Github. This will present a button you can use to accept
the assignment, which in turn will create a repository for you under the
`nyu-distributed-systems`. 

## Data Types in Elixir
Sometimes it is useful to have named fields rather than tuples. In Elixir
[defstruct](https://elixir-lang.org/getting-started/structs.html) provides
a way of doing this, though structures are just glorified maps. Unfortunately
a structure is associated with a single module.

As a result `time_lab.ex` consists of two modules:
*  [`VirtualTimeMessage`](https://github.com/nyu-distributed-systems/fa20-lab2-code/blob/master/apps/lab2/lib/time_lab.ex#L1) which has a structure
   consisting of a Lamport clock and vector clocks.

* [`TimeLab`](https://github.com/nyu-distributed-systems/fa20-lab2-code/blob/master/apps/lab2/lib/time_lab.ex#L70) where all your logic should go.

## Application Events and Failure Model

In this assignment we only consider two application events: message sends, and
message receives. This is common practice for distributed logging.

You **do not** need to consider message losses in this project.

## Part 1: Lamport Clocks (35%)
For this part you need to implement two functions:

* [`update_lamport_clock/2`](https://github.com/nyu-distributed-systems/fa20-lab2-code/blob/master/apps/lab2/lib/time_lab.ex#L98): This function is
  called whenever a process receives a message. The `current` argument is the
  processes current Lamport clock, while the `received` argument contains the
  clock attached to the received message.
* [`update_lamport_clock/1`](https://github.com/nyu-distributed-systems/fa20-lab2-code/blob/master/apps/lab2/lib/time_lab.ex#L111) is called before the
  process sends a message. Similar to `update_lamport_clock/2` the `current`
  argument is the current process clock.
  
Both functions should return the updated value of the process clock. The function [`lamport_ping_server/1`](https://github.com/nyu-distributed-systems/fa20-lab2-code/blob/master/apps/lab2/lib/time_lab.ex#L117) demonstrates a case where
they are used.

### Testing
You can test this part of the code by running

```
mix test test/virtual_clock_test.exs:10:50
```

This syntax just means run all tests in the `virtual_clock_test.ex` file
between lines 10 and 50. You might need to adjust this if you add or remove
tests.

## Part 2: Vector Clocks (50%)
### 2A. Updating Vector Clocks

For this part you need to update vector clocks when messages are received
or sent.

#### Updates when messages are received
When a message is received a process that uses vector clocks will call
[`combine_vector_clocks`](https://github.com/nyu-distributed-systems/fa20-lab2-code/blob/master/apps/lab2/lib/time_lab.ex#L220) which gets two maps as
input: `current` representing the vector clock at the current process, and
`received` representing the vector clock attached to the received message.

Updating a vector requires iterating through the vector, and the Lab code
accomplishes this task by using `Map.merge`. The `Map.merge` call in 
`combine_vector_clocks` will call [`combine_component/2`](https://github.com/nyu-distributed-systems/fa20-lab2-code/blob/master/apps/lab2/lib/time_lab.ex#L208)
with a single component from each vector clock. You need to implement your
update algorithm in this function. The `combine_component` function should
return a non-negative integer.

#### Updates when messages are sent
The [`update_vector_clock/2`](https://github.com/nyu-distributed-systems/fa20-lab2-code/blob/master/apps/lab2/lib/time_lab.ex#L234) function is called whenever
a process sends a message. The two arguments are `proc`, the process
identifier and `clock` the current vector clock. This function should
return an updated vector clock.

### 2B: Comparing Vector Clocks
You also need to implement the [compare_vectors/2](https://github.com/nyu-distributed-systems/fa20-lab2-code/blob/master/apps/lab2/lib/time_lab.ex#L277)
function for comparing two vector clocks `v1` and `v2`. This function should
return:

* `:before` (`@before`) if `v1` happens before `v2`.
* `:after` (`@hafter`) if `v2` happens before `v1`.
* `:concurrent` (`@concurrent`) if `v1` and `v2` are incomparable.

In order to get `compare_vectors/2` working you will also need to fill out
[`compare_component/2`](https://github.com/nyu-distributed-systems/fa20-lab2-code/blob/master/apps/lab2/lib/time_lab.ex#L265).

### Testing
Assuming you have Lamport clocks done, you can test this 
part of the code by running. Otherwise read through the tests
to find and pass the appropriate line numbers.

```
mix test test/virtual_clock_test.exs
```

### 3: Generating a few traces (15%)
Next we are going to construct a few example scenarios:
(a) Implement a distributed system comprising of three processes, where each process
sends at least **one** message to one other process. Construct a scenario 
(a schedule/sequence of events) where at least a pair of events are **concurrent**.

(b) Implement a distributed system comprising of three processes, where each process
sends at least **one** message to one other process. Construct a scenario 
(a schedule/sequence of events) where no pair of events is **concurrent**.

Implement your examples in the `test/virtual_clock_test.exs` file.

Provide line numbers for your implementation here: **FILL THIS IN**

#### Implementation Notes
**FILL THIS IF DESIRED**

## Handing In 

**WARN WARN WARN** PLEASE READ THESE INSTRUCTIONS CAREFULLY. YOU MAY **RECEIVE
A 0 (ZERO) IF YOU DO NOT**, EVEN IF YOU COMPLETE EVERYTHING THUS FAR.


To handin this assignment:

* First make sure `mix test` shows that you pass all tests. If not be aware
  that you will loose points.
* Second, make sure you have updated this `README.md` file. This requires
  providing line numbers for the test you added in Part 2, potentially adding
  implementation notes to Part 3, and filling out the information below.
* Commit and push all your changes.
* Use `git rev-parse --short HEAD` to get a commit hash for your changes.
* Fill out the [submission form](https://forms.gle/zEW7XcsuEMZzbodPA) with
  all of the information requested.

We will be using information in the submission form to grade your lab, determine
late days, etc. It is therefore crucial that you fill this out correctly.

Github username: (e.g., apanda)
NYU NetID: (e.g., ap191)
NYU N#:
Name: 

### Citations
