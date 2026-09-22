# CORAL

**Coral reef Optimization for Adaptive Layouts**

CORAL is a topology-aware optimization framework for chemical process superstructures. It represents candidate process designs as corals living on a computational reef, where different process topologies behave as competing species.

Through settlement, budding, competition, depredation, bleaching, and recolonization, CORAL explores the discrete structural space of a process superstructure. Promising fixed topologies are subsequently refined using deterministic constrained nonlinear programming (NLP).

The resulting architecture combines:

- nature-inspired global exploration of process topology;
- explicit structural feasibility and topology repair;
- diversity-preserving population mechanisms;
- adaptive search operators; and
- deterministic constrained NLP refinement of continuous variables.

> **CORAL explores the structure; constrained NLP refines the design.**

---

## CORAL-R1

This repository contains the evolving CORAL project together with the frozen **CORAL-R1** implementation used for the computational experiments accompanying the manuscript.

CORAL-R1 should be regarded as a reproducible research release rather than as the final form of the algorithm. Future versions may introduce new search mechanisms, alternative ecological operators, additional benchmark problems, and more detailed connections between coral-reef ecology and computational optimization.

The frozen implementation is:

```text
src/CORALSuperstructureOptimizer_R1.m
```

It is intentionally preserved separately from future development.

---

## Optimization architecture

A candidate solution consists of

\[
(\mathbf{y},\mathbf{x}),
\]

where:

- \(\mathbf{y}\) contains discrete structural decisions defining the process topology;
- \(\mathbf{x}\) contains continuous operating and design variables.

CORAL operates primarily on the structural search space. Candidate topologies are generated and modified through reef-inspired population operators. Structural repair ensures that candidates belong to the admissible topology set.

For promising fixed topologies, a constrained NLP subproblem is solved using MATLAB `fmincon` with SQP.

Conceptually:

```text
Process superstructure
        |
        v
  CORAL reef search
        |
        |  discrete topology y
        v
Topology repair / feasibility
        |
        v
Constrained local NLP
        |
        |  continuous variables x
        v
   Refined process design
        |
        v
Selection and reef evolution
```

This hybridization is important for constrained process synthesis: in the CORAL-R1 experiments, population search alone did not reliably produce continuously feasible solutions, whereas coupling structural exploration to constrained local NLP did.

---

## Eight-process synthesis benchmark

The principal CORAL-R1 validation problem is the classic **eight-process synthesis benchmark**.

The benchmark contains eight possible processes and exactly **12 logically admissible process topologies**.

The deterministic reference calculation enumerates all admissible structures and applies multistart SQP to each fixed topology.

The resulting reference is:

```text
Objective:          68.009744051065
Selected processes: 2, 4, 6, 8
```

The reference solver is provided in:

```text
experiments/reference_enumeration/
```

and the complete benchmark definition is available in:

```text
benchmarks/eight_process/
```

---

## What CORAL-R1 shows

The computational study supports three main conclusions.

### 1. CORAL can recover the reference topology

With constrained local refinement enabled, CORAL-R1 consistently recovered the P2-P4-P6-P8 topology in the reported main and controlled experiments.

### 2. Hybridization is essential

The strongest result of the study is not that one population method dominates the others, but that deterministic constrained NLP refinement is critical for this constrained process-superstructure problem.

In the controlled comparisons:

- CORAL without local NLP did not reliably reach continuous feasibility;
- the reduced CRO-like search without local NLP showed the same difficulty;
- direct constrained GA did not obtain feasible solutions within the tested oracle budget;
- CORAL + NLP, CRO-like + NLP, and GA + local NLP all successfully recovered feasible reference-topology solutions in the corresponding hybrid experiments.

### 3. CORAL is a topology-oriented framework, not a demonstrated superior optimizer

On this relatively small benchmark, the topology-aware ecological mechanisms of CORAL did **not** demonstrate solution-quality superiority over simpler hybrid approaches.

The results therefore support CORAL as a topology-oriented global-search framework and research architecture rather than a claim of universal algorithmic superiority.

The larger research question is whether topology-aware and ecologically motivated search mechanisms become advantageous for larger, more structurally complex process-superstructure problems.

---

## Minimal example

A minimal CORAL-R1 run on the eight-process benchmark is provided in:

```text
examples/run_CORAL_R1_eight_process.m
```

From the repository root, ensure that the source and benchmark directories are on the MATLAB path and run the example.

The script uses the frozen CORAL-R1 settings and reports:

- best raw objective;
- selected process topology;
- equality and inequality residuals;
- logical feasibility;
- iterations;
- total oracle calls;
- local NLP calls;
- topology repairs; and
- runtime.

Because feasibility is accepted at a finite numerical tolerance, a raw CORAL objective can occasionally lie marginally below the high-accuracy enumerated reference. This should not be interpreted as a better global solution. High-accuracy fixed-topology polishing returns the deterministic reference value.

---

## Repository structure

```text
CORAL/
├── README.md
├── LICENSE
├── .gitignore
│
├── src/
│   └── CORALSuperstructureOptimizer_R1.m
│
├── examples/
│   └── run_CORAL_R1_eight_process.m
│
├── benchmarks/
│   └── eight_process/
│
├── experiments/
│   ├── reference_enumeration/
│   ├── components/
│   ├── equal_budget/
│   ├── GA_baselines/
│   ├── localNLP_probability/
│   ├── localNLP_intensity/
│   ├── sensitivity/
│   └── consolidation/
│
└── results/
    ├── raw/
    ├── summary/
    └── figures/
```

### `src/`

Frozen CORAL-R1 optimizer implementation.

### `benchmarks/`

Mathematical benchmark definitions, constraints, bounds, structural logic, and topology repair.

### `examples/`

Small runnable examples intended as the easiest entry point for new users.

### `experiments/`

Frozen scripts used for the CORAL-R1 computational validation, including:

- deterministic enumeration;
- component ablation;
- local-NLP probability sensitivity;
- local-NLP intensity sensitivity;
- equal-oracle-budget comparisons;
- direct and hybrid GA baselines;
- parameter and reef-size sensitivity; and
- final statistical consolidation.

### `results/raw/`

Preserved run-level CSV files, summary CSV files, and MATLAB result archives from the computational campaign.

### `results/summary/`

Publication-facing consolidated tables, including confidence intervals.

### `results/figures/`

Figures generated by the final statistical consolidation.

---

## Reproducing the CORAL-R1 study

The recommended order is:

1. Run the deterministic eight-process reference enumeration.
2. Run the minimal CORAL-R1 example.
3. Run the local-NLP probability sensitivity experiment.
4. Run the component comparison.
5. Run the equal-oracle-budget comparison.
6. Run the GA baselines.
7. Run the parameter and reef-size sensitivity studies.
8. Run the local-NLP intensity sensitivity experiment.
9. Run the statistical consolidation script.

The complete stochastic campaigns can require substantial computation. Frozen run-level and consolidated results are therefore included in `results/` so that the reported analysis can be inspected without rerunning the entire campaign.

Oracle calls are the preferred computational-effort metric for comparisons because wall-clock measurements can depend strongly on hardware and external system conditions.

---

## MATLAB requirements

CORAL-R1 is implemented in MATLAB.

The experiments require:

- **Optimization Toolbox** — constrained local optimization using `fmincon`;
- **Global Optimization Toolbox** — required for the GA baseline experiments.

No specific MATLAB release is claimed here; the frozen source and experiment scripts document the functions used.

---

## Reproducibility philosophy

CORAL-R1 separates three levels of evidence:

**Code**  
The exact optimizer, benchmark definitions, and experiment scripts are preserved.

**Raw computational evidence**  
Run-level results and MATLAB archives are provided in `results/raw/`.

**Publication-facing evidence**  
Consolidated tables, confidence intervals, and figures are provided in `results/summary/` and `results/figures/`.

This separation is intentional: the repository preserves not only the final figures but also the computational evidence from which they were derived.

---

## Project status

**CORAL-R1** is the frozen version associated with the present process-superstructure study.

The broader **CORAL** project remains under development.

Future work may investigate:

- larger process-superstructure problems;
- alternative topology representations;
- improved diversity and niche mechanisms;
- ecological disturbance and recolonization strategies;
- adaptive structural operators;
- multiobjective optimization;
- uncertainty and changing operating conditions; and
- closer collaboration with coral-reef ecologists to investigate whether greater ecological fidelity can generate useful computational mechanisms.

---

## Citation

A `CITATION.cff` file will provide the preferred citation for the software release.

When using CORAL-R1 before the associated article has received its final bibliographic information, please cite the repository and the corresponding software release.

---

## License

CORAL is released under the **MIT License**. See `LICENSE` for details.

---

## Author

**Edwin Zondervan**  
Sustainable Process Technology  
University of Twente  
The Netherlands

CORAL was developed as a research framework for exploring topology-aware and nature-inspired optimization of chemical process superstructures.
