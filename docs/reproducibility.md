# Reproducing CORAL-R1

This document describes how to reproduce the computational experiments associated with **CORAL-R1**, the frozen research version of CORAL used for the eight-process synthesis study.

The repository contains three complementary levels of reproducibility:

1. the frozen CORAL-R1 implementation and benchmark definitions;
2. the experiment scripts used for the computational campaign;
3. the preserved run-level and consolidated results.

The complete stochastic campaign can require substantial computation. It is therefore not necessary to rerun every experiment simply to inspect or reproduce the reported analysis.

---

## 1. Requirements

CORAL-R1 is implemented in MATLAB.

Required MATLAB toolboxes are:

- **Optimization Toolbox**, including `fmincon`;
- **Global Optimization Toolbox**, for the GA baseline experiments.

The frozen experiments use constrained SQP through `fmincon`.

No specific MATLAB release is claimed for CORAL-R1.

---

## 2. Repository directories

The principal directories used for reproduction are:

```text
src/
benchmarks/eight_process/
examples/
experiments/
results/
```

The frozen optimizer is:

```text
src/CORALSuperstructureOptimizer_R1.m
```

The eight-process benchmark is defined in:

```text
benchmarks/eight_process/
```

This directory contains:

```text
eight_process_model.m
eight_process_constraints.m
eight_process_bounds.m
eight_process_logic_feasible.m
eight_process_topology_repair.m
```

---

## 3. MATLAB path

Before running an experiment, ensure that the CORAL source and benchmark directories are available on the MATLAB path.

For example, from the repository root:

```matlab
addpath('src');
addpath(fullfile('benchmarks','eight_process'));
```

The experiment scripts themselves should be treated as frozen research artifacts.

Do not alter algorithm settings, seeds, stopping criteria, feasibility tolerances, or benchmark definitions when attempting to reproduce the reported CORAL-R1 experiments.

---

## 4. Deterministic reference calculation

Start with the deterministic reference calculation:

```text
experiments/reference_enumeration/
    reference_eight_process_enumeration_R1.m
```

The calculation enumerates all logically admissible topologies and performs multistart constrained SQP for each fixed topology.

The default settings are:

```text
Multistart NLP solves per topology: 20
Random seed:                       321
Feasibility tolerance:             1e-5
```

The eight-process problem contains 12 logically admissible topologies.

The reference calculation gives:

```text
Reference objective:   68.009744051065
Selected processes:    2, 4, 6, 8
Total SQP starts:      240
```

The reference script returns a MATLAB structure containing the individual topology results and aggregate computational counters. It does not write a separate result file.

The reference calculation should be performed before interpreting stochastic CORAL results.

---

## 5. Minimal CORAL-R1 example

Before running the complete experimental campaign, run:

```text
examples/run_CORAL_R1_eight_process.m
```

This provides a single CORAL-R1 optimization of the eight-process benchmark using the frozen nominal settings.

The example reports:

- raw objective;
- selected topology;
- constraint residuals;
- logical feasibility;
- number of CORAL iterations;
- total oracle calls;
- local NLP calls;
- topology repairs;
- runtime.

The enumerated reference topology is:

```text
P2-P4-P6-P8
```

### Numerical tolerance

CORAL-R1 accepts feasibility at a finite tolerance of `1e-5`.

Consequently, a raw CORAL solution may occasionally have an objective value marginally below `68.009744051065`. Such a value must not be interpreted as a new global optimum.

High-accuracy fixed-topology polishing returns the deterministic reference value.

---

## 6. Recommended experimental sequence

The CORAL-R1 validation campaign can be reproduced in the following order.

### 6.1 Local-NLP probability sensitivity

Script:

```text
experiments/localNLP_probability/
    sensitivity_localNLP_CORAL_R1.m
```

Tested local-refinement probabilities are:

```text
0.00
0.20
0.30
0.40
0.60
0.80
1.00
```

Ten matched random seeds are used at each level.

The experiment evaluates the influence of local constrained NLP refinement on:

- feasibility;
- reference-topology recovery;
- objective quality;
- oracle calls;
- runtime;
- local NLP effort.

The probability retained for the subsequent CORAL-R1 experiments is:

```text
p_NLP = 0.30
```

Among the successful tested probability levels, this setting gave the lowest median oracle effort.

---

### 6.2 Component comparison

Script:

```text
experiments/components/
    benchmark_components_CORAL_R1_step4.m
```

Four configurations are compared:

```text
CRO-like
CRO-like + NLP
CORAL without NLP
CORAL + NLP
```

All configurations use the same admissible topology space and topology-repair mechanism.

This experiment separates the contribution of deterministic constrained NLP refinement from the explicitly topology-aware and adaptive CORAL mechanisms.

It is a component comparison under common algorithmic stopping settings and should not itself be interpreted as an equal-cost comparison.

---

### 6.3 Equal-oracle-budget comparison

Script:

```text
experiments/equal_budget/
    benchmark_equal_oracle_CORAL_R1_step4B.m
```

This experiment compares:

```text
CRO-like + constrained NLP
CORAL + constrained NLP
```

under a common useful oracle-call budget of:

```text
1,500,000 calls
```

Oracle calls are used as the principal effort measure.

This comparison is particularly important because wall-clock runtime can be affected by hardware, operating-system load, MATLAB state, and other external conditions.

---

### 6.4 GA baselines

Scripts:

```text
experiments/GA_baselines/
    benchmark_GA_NLP_CORAL_R1_step5A.m
    benchmark_GA_localNLP_CORAL_R1_step5B.m
```

Two GA-based approaches are considered.

#### Direct constrained GA

The first searches the mixed structural/continuous space directly and uses the explicit nonlinear constraints.

Within the tested 1.5-million-call budget, this configuration did not obtain feasible reference-topology solutions in the reported ten runs.

#### GA + local NLP

The second uses GA primarily for topology search and evaluates candidate fixed topologies using constrained local SQP.

This hybrid formulation recovered feasible reference-topology solutions in all ten reported runs.

The comparison therefore provides additional evidence for the importance of hybrid structural search and deterministic constrained NLP refinement.

---

### 6.5 Parameter sensitivity

Script:

```text
experiments/sensitivity/
    sensitivity_CORAL_parameters_R1_step6.m
```

This experiment performs one-factor-at-a-time screening of selected CORAL parameters around the frozen nominal configuration.

Its purpose is sensitivity analysis rather than post-hoc parameter optimization.

---

### 6.6 Reef-size confirmation

Script:

```text
experiments/sensitivity/
    sensitivity_CORAL_reefsize_R1_step6B.m
```

The targeted reef-size comparison considers:

```text
Reef size = 60
Reef size = 120
Reef size = 240
```

The confirmed ten-seed results show reference-topology recovery for all three sizes, while continuous feasibility rates differ.

The smaller reef is computationally cheaper on this benchmark. Nevertheless, the nominal reef size of 120 is retained in CORAL-R1 to avoid post-hoc tuning of the frozen algorithm after observing benchmark results.

---

### 6.7 Local-NLP intensity sensitivity

Script:

```text
experiments/localNLP_intensity/
    sensitivity_localNLP_intensity_CORAL_R1.m
```

The tested maximum local SQP iteration limits are:

```text
50
100
300
600
```

The local-NLP probability remains fixed at:

```text
p_NLP = 0.30
```

In the reported experiment, the realized local SQP solves generally terminated well before these iteration limits. The sensitivity study therefore supports the interpretation that the nominal limit is not the mechanism driving the reported CORAL-R1 result.

---

## 7. Statistical consolidation

After the frozen result CSV files are available, run:

```text
experiments/consolidation/
    consolidate_CORAL_R1_step7.m
```

This script performs **no optimization**.

It reads the frozen result files and generates publication-facing:

- summary tables;
- Wilson 95% confidence intervals;
- comparison tables;
- figures.

The preserved outputs are available in:

```text
results/summary/
results/figures/
```

This means the statistical reporting can be inspected without rerunning the stochastic optimization campaign.

---

## 8. Preserved raw results

The directory:

```text
results/raw/
```

contains the run-level and summary CSV files generated by the computational experiments, together with available MATLAB `.mat` archives.

These files preserve the numerical evidence underlying the consolidated tables.

Important preserved datasets include results from:

- local-NLP probability sensitivity;
- component comparison;
- equal-oracle-budget comparison;
- direct constrained GA;
- hybrid GA + local NLP;
- CORAL parameter sensitivity;
- reef-size sensitivity and confirmation.

---

## 9. Publication-facing results

The final statistical consolidation is preserved in:

```text
results/summary/
```

including:

```text
Table_7_master_benchmark.csv
Table_S7_components_with_CI.csv
Table_S7_equal_budget_with_CI.csv
Table_S7_GA_baselines_with_CI.csv
Table_S7_parameter_screening_with_CI.csv
Table_S7_pNLP_sensitivity_with_CI.csv
Table_S7_reefsize_10seed_with_CI.csv
STEP7_README.txt
```

The associated figures are preserved in:

```text
results/figures/
```

including:

```text
Figure_7a_hybrid_oracle_effort.png
Figure_7b_pNLP_sensitivity.png
Figure_7c_reefsize_sensitivity.png
```

---

## 10. Interpretation of the computational evidence

The CORAL-R1 experiments support three main conclusions.

### Structural search succeeds

When coupled to constrained local refinement, CORAL-R1 identifies the deterministic reference topology:

```text
P2-P4-P6-P8
```

### Local constrained NLP is critical

Across CORAL, reduced CRO-like search, and GA experiments, the decisive computational feature is the coupling of global structural exploration with deterministic constrained NLP.

Population search without this refinement does not reliably resolve continuous feasibility on the eight-process benchmark.

### No superiority claim is made

The eight-process benchmark does not provide evidence that the explicitly topology-aware CORAL mechanisms outperform simpler hybrid approaches in final solution quality.

In particular, the frozen experiments should **not** be interpreted as demonstrating that CORAL is universally superior to CRO-like + NLP or GA + NLP.

CORAL-R1 instead demonstrates a topology-oriented optimization architecture and establishes a reproducible basis for testing the approach on larger and more structurally challenging superstructures.

---

## 11. Computational-effort metric

The principal computational-effort metric used in the CORAL-R1 comparisons is:

```text
total oracle calls
```

This includes the relevant objective- and constraint-evaluation effort recorded by the frozen implementation and comparison scripts.

Wall-clock runtime is retained as supplementary information but should be interpreted cautiously because it is machine- and environment-dependent.

For this reason, conclusions concerning computational effort should primarily be based on oracle counts rather than small differences in measured runtime.

---

## 12. Random seeds and repeatability

The stochastic experiments use explicit MATLAB random seeds.

Where comparisons are made across algorithmic configurations or parameter settings, matched seeds are used wherever specified by the frozen experiment scripts.

Do not replace the published seed sets with newly generated random seeds when attempting exact reproduction.

New seeds may of course be used for independent replication studies, but those runs should be identified as new experiments rather than reproduction of the frozen CORAL-R1 campaign.

---

## 13. Frozen versus future CORAL versions

The file:

```text
src/CORALSuperstructureOptimizer_R1.m
```

is the frozen implementation corresponding to CORAL-R1.

It should not be silently modified.

Future algorithm development should be introduced as a new version rather than changing the historical R1 implementation. This allows the numerical results in the manuscript to remain traceable to an identifiable version of the code.

The broader CORAL project can therefore evolve while CORAL-R1 remains reproducible.

---

## 14. Suggested quick reproduction path

For a user who wants to understand CORAL without rerunning the full computational campaign, the recommended sequence is:

```text
1. Inspect benchmarks/eight_process/
2. Run the deterministic reference enumeration
3. Run examples/run_CORAL_R1_eight_process.m
4. Inspect results/raw/
5. Inspect results/summary/
6. Inspect results/figures/
```

This is sufficient to understand the benchmark, execute CORAL-R1, and trace the reported conclusions back to the preserved computational evidence.

---

## 15. Full reproduction path

For a complete rerun of the computational campaign:

```text
1. Deterministic reference enumeration
2. Minimal CORAL-R1 run
3. Local-NLP probability sensitivity
4. Component comparison
5. Equal-oracle-budget comparison
6. Direct GA baseline
7. GA + local NLP baseline
8. Parameter sensitivity
9. Reef-size confirmation
10. Local-NLP intensity sensitivity
11. Statistical consolidation
```

Because several of these experiments contain repeated stochastic optimization runs, a full reproduction can be computationally expensive.

The frozen results included in this repository are therefore part of the reproducibility package, not merely supplementary convenience files.
