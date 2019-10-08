# CMPS 3240 Lab: Introduction to SIMD
An introduction to SIMD operations with basic linear algebra subroutines

## Objectives

During this lab you will:

1. Study a floating point (FP) implementation of AXPY
2. Learn about ARMv8 SIMD operations
3. Code SIMD operations at the assembly level
4. Benchmark AXPY operations with and without SIMD

## Prerequisites

* Single-instruction Multiple-Datastream (SIMD) concept
* Book's description of ARM Neon<sup>a</sup>
* Element14's description of ARMv8 FP/SIMD registers (Sec. 4.4.2)<sup>1</sup>
* Element14's description of SIMD load/store registers (Sec. 5.7.22)<sup>1</sup>
* Element14's description of SIMD load/store arithmetic (Sec. 5.7.4)<sup>1</sup>

This lab assumes you have read the above topics. Please take a look at them before the lab to ensure timely completion of the lab. Element14 is a manufacturer of embedded systems that often use ARM processors. While they are not the official maintainer of ARMv8, I find their documentation to be more readable and thus useful than the ARM infocenter.

## Requirements

The following is a list of requirements to complete the lab. Some labs can completed on any machine, whereas some require you to use a specific departmental teaching server. You will find this information here.

### Software

We will use the following programs:

* `gcc`
* `git`
* `gdb`

### Compatability

This lab requires the departmental ARM server, `fenrir.cs.csubak.edu`. It will not work on `odin.cs.csubak.edu`, `sleipnir.cs.csubak.edu`, other PCs, etc. that have x86 processors. It may work on a Raspberry Pi or similar system on chip with ARM, but it must be ARMv8-a.

| Linux | Mac | Windows |
| :--- | :--- | :--- |
| Limited | No | No |

## Background

In the following, we go over SIMD, FP/SIMD registers, and an example program that uses FP/SIMD.

### SIMD

Single-instruction Multiple-datastream (SIMD) is hardware level optimization for operating on an array of values. Let us assume that there is an operation that must be performed on an array of values. For index `i`, do the following:

```c
for( int i = 0; i < n; i++ )
  a[i] = func( b[i] );
```

The array steps through the array one element at a time. The cost of this operation is n * (time of each loop).

With SIMD, the processor supports instructions that:

1. Have registers that are very large which can be segmented to hold multiple values within the same register. This is called a *vector*.
2. With a single instruction, deference multiple data points at once, and place the results correspondingly in a vector register. This is similar to the `stp` and `ldp` operations we used with the stack, but we will use different instructions.
3. With a single instruction, store a vector register into multiple data points.
4. With a single instruction, perform arithmetic independently on each value in a vector register.

Conventionally, the loop-body would execute some function `func()` on data points i, i + 1, i + 2 and so on. However, with these features, the processor can execute multiple data points with a single loop iteration. For example, (i, i + 1), (i + 2, i + 3), etc. where each unit of work is executed in parallel. This is similar to loop unrolling, except the parallelism is handled by the processor on the hardware side. Assuming the operation does n units of work with each iteration, the operation costs ((time of each loop)/n + overhead).

### FP/SIMD Registers

ARMv8 has 32 registers used for both floating point and SIMD (FP/SIMD) operations. They are named `v0` to `v31`. Depending on context they can hold scalars and vectors. Similarly to the general purpose registers, we must further qualify the size of the register we are using, which must correspond to the type of element stored in the register. When used to hold scalar floating point values, they are:

| Size | Bits |
| --- | --- |
| `bt` | 8 |
| `ht` | 16 |
| `st` | 32 |
| `dt` | 64 |
| `qt` | 128 |

FP/SIMD registers can hold a vector--that is, a set of contents rather than a single value. Unlike other register addressing modes, you must specify the number of elements and the size of each element. This helps the processor determine the segmentation boundaries when performing loads, stores and arithmetic. The notation is as follows:

| Register | Bits | Lanes |
| --- | --- | --- |
| vt.8B |  8 | 8 |
| vt.16B | 8 | 16 |
| vt.4H | 16 | 4 |
| vt.8H | 16 | 8 |
| vt.2S | 32 | 2 |
| vt.4S | 32 | 4 |
| vt.1D | 64 | 1 |
| vt.2D | 64 | 2 |

For example, if you wanted to apply 4-lane SIMD on single precision floating points, register `v0.4s` is a valid choice. If you wanted to apply a 8-lane SIMD on half-word integers (16 bits ea.), register `v19.8h` is a valid choice. Notice in all examples that bits times lanes is no greater than 128. If bits times lanes does not equal 128 the upper 64 bits of are ignored when read and set to zero on a write. You can also randomly access individual elements in a vector register with C-style array indexing. For example, `v0.2s[0]` refers to the first 32-bit in a vector register. However,  `v0.2s[0]` is not synonymous with `s0`, they are different registers.

Further, unlike general purpose operations, FP/SIMD instructions often specify the type of value in the instruction mnemonic. Valid types are integers (signed, unsigned or irrelevant), floating point, polynomial or cryptographic hash.

## Approach

The repo has the following files:

* `faxpy.s` - An assembly solution single-precision floating point A time X plus Y (FAXPY). Note that we are simplifying the code to only perform an addition for this lab. X + Y only, no A times X plus Y.
* `test_faxpy.c` - C-language code for a benchmark program to test `faxpy()`.
* `make` - A makefile that assembles and then links the two files using `gcc`. `test_faxpy.o` is linked with `faxpy.o`, `faxpy.o` contains the definition of `faxpy()`.

This lab assumes that you have completed the FAXPY lab and will not take time to explain it. You task is to do the following:

1. Use the Makefile to compile the baseline binary file and test it with `time` three times, similar to the benchmark lab.
2. Understand the instructions below, and implement a SIMD `faxpy()` which uses 4 lanes.
3. Apply the instructions below, and implement a SIMD `faxpy()` which uses 2 lanes.

### Study `faxpy` and Prepare SIMD Solution

Study `faxpy.s` and the Makefile, and when you're confident continue. We implemented AXPY in a previous lab, so we will not go over the solution in depth. However, there are some differences:

* Floating point registers have a different notation (see Background)
* Floating point operations sometimes use different instructions, often prefixed with an `f`. E.g. `fadd` vs. `add`.

*Sidebar: This is the first lab where we are linking C-code with ARM code. The benchmark has been created in C, and you must code the subroutine called by the benchmark in ARM. The framework for the code is all there, you just need to insert the appropriate SIMD commands in faxpy.s.*

A good place to start is to copy the `faxpy()` solution and modify the code:

```bash
$ cp faxpy.s faxpySIMD4.s
```

and create some Make targets for your SIMD solutions. You should not need to create a separate benchmark test file because the interface of calling `faxpy()` will not change, only the assembly code. An example:

```make
faxpySIMD4.out: faxpySIMD4.o test_faxpy.o
  gcc -Wall -O0 $^ -o $@
faxpySIMD4.o: faxpySIMD4.s
    gcc -Wall -O0 -c $< -o $@
```

which continues to use `test_faxpy.o` because the benchmark does not change.

### SIMD Instructions

There are two (or three) concepts that you must apply to convert this function to a SIMD function. Generally:

1. Use a single SIMD instruction to take consecutive chunks from an array and place them in a vector register in order. Do this for `x` and `y`.
2. Use a single instruction to perform the addition, in parallel.
3. Use a single instruction to store the consecutive chunks into `result`.

#### 1. SIMD Loading

Loading multiple elements is of the form `ld1 {vt.<BL>}, addr`, where `ld1` is the instruction mnemonic, `vt` is the vector register of your choice, and `<BL>` is the bit lane suffix (see Background). `addr` is an address which acts similarly to `ldr` memory addressing (pre-indexing, post-indexing, etc.). Note that curly braces are required, even if you are supplying only one vector register. Here are some examples:

```arm
ld1 {v0.2d}, [x0] # Load two 64-bit values starting at [x0]
ld1 {v1.4s}, [x0], 16 # Load four 32-bit values starting at [x0] and post-increment by 16 bytes
ld1 {v2.2s}, [x0, 16] # Load two 32-bit values starting at [x0]+16
```

There are also `ld2`, `ld3`, `ld4` operations that can be used for 2-, 3- and 4-tuple data (Multi-dimensional). This is why a curly brace is required for the operation. We do not need beyond `ld1` for this lab. For a 4-lane single-precision FP load, `.4s` is the appropriate prefix. Replace the `ldr` instructions with:

```arm
# Load two 64-bit values starting at [x1], increment pointer
ld1 {v0.4s}, [x1], 16
# Load two 64-bit values starting at [x2], increment pointer
ld1 {v1.4s}, [x2], 16
```

#### 2. SIMD addition

`v0` holds `x[i]` thru `x[i+3]` and `v1` holds `y[i]` thru `y[i+3]`. We continue to use post-index to increment the pointer. However, note that we increment by 16 and not 4. The reason is that 4 lanes times 32-bits equals 16 bytes. Once loaded, replace the arithmetic instruction with one that uses vector registers:

```arm
fadd  v0.4s, v0.4s, v1.4s
```

Curly braces are only required for loads and stores.


#### 3. SIMD Store and Counter Increment

The SIMD store operation is similar to the load operation:

```arm
# Save two 64-bit values starting at [x3], increment pointer
st1 {v0.4s}, [x3], 16
```

*Comprehension check:* The last instruction before jumping to `_looptop` is to `add w5, w5, 1`. Is this still appropriate here?

#### Benchmarking

Now that your 4-lane SIMD code is complete, use the bash CLI code to benchmark the optimized and unoptimized versions of the code for 3 trials and take the average.

## Check off

For full credit, show the instructor your results for the following benchmark trials:

1. Unoptimized `faxpy()` (Given)
2. 4-lane SIMD `faxpy()` (Instructions given)
2. 2-lane SIMD `faxpy()` (Instructions *not* given)

## References

<sup>1</sup>https://www.element14.com/community/servlet/JiveServlet/previewBody/41836-102-1-229511/ARM.Reference_Manual.pdf

## Footnotes

<sup>a</sup> The book refers to ARM NEON, which is an optional ISA for a previous version of ARM. The version of ARM we are using, ARMv8, has folded SIMD instructions into the regular set of operations, and the mnemoics may be different from the textbook.
