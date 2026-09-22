<p align="center">
  <img src="docs/CORAL_banner.png" alt="CORAL — Coral reef Optimization for Adaptive Layouts" width="100%">
</p>

# CORAL

**Coral reef Optimization for Adaptive Layouts**

CORAL is a topology-aware optimization framework for chemical process superstructures. It combines coral-reef-inspired structural exploration with deterministic constrained nonlinear programming for continuous design-variable refinement.

This repository contains **CORAL-R1**, the frozen and reproducible research version associated with the initial process-superstructure study.

> **CORAL-R1 is preserved as a research release.**  
> Future development of CORAL may extend the ecological mechanisms, computational architecture, and application scope, while this repository remains the reproducible reference implementation for the R1 study.

---

## Concept

CORAL treats alternative process structures as competing species on a computational reef.

A candidate solution consists of:

- a discrete process topology, **y**;
- continuous design variables, **x**;
- an objective value;
- feasibility information.

The reef provides a finite computational environment in which candidate structures can settle, reproduce, compete, disappear, and recolonize.

The biological analogy is used to organize structural search:

| Reef ecology | CORAL interpretation |
|---|---|
| Reef | Computational population |
| Coral colony | Candidate process design |
| Species | Process topology |
| Settlement | Introduction of a candidate |
| Budding | Local generation of related candidates |
| Competition | Selection under limited population capacity |
| Depredation | Removal of poor candidates |
| Bleaching / disturbance | Deliberate population disruption |
| Recolonization | Introduction of new structural diversity |
| Diversity | Coexistence of alternative topologies |
| Local refinement | Constrained nonlinear optimization |

CORAL is **inspired by coral-reef ecology**, rather than intended as a biologically faithful reef model.

---

## Optimization architecture

CORAL separates structural exploration from continuous optimization.

```text
                    CORAL reef
                        |
                        v
              discrete topology search
                        |
                        v
                 topology repair
                        |
                        v
              fixed process topology
                        |
                        v
          constrained local NLP refinement
                 (fmincon / SQP)
                        |
                        v
             feasibility + objective
                        |
                        v
             return candidate to reef
```

The reef therefore explores the discrete structural space, while deterministic constrained nonlinear programming refines the continuous variables for promising fixed topologies.

This hybrid architecture is a central feature of CORAL-R1.

---

## CORAL-R1

CORAL-R1 is the frozen implementation corresponding to the first systematic computational validation of the framework.

The release includes:

- the CORAL-R1 optimizer;
- a reproducible eight-process synthesis benchmark;
- deterministic reference enumeration;
- component-ablation experiments;
- equal-oracle-budget comparisons;
- GA and GA+local-NLP baselines;
- local-NLP probability and intensity studies;
- parameter and reef-size sensitivity studies;
- raw computational results;
- consolidated statistical tables and figures;
- documentation for reproducing the experiments.

The frozen release is tagged:

**v1.0.0 — CORAL-R1**

---

## Eight-process synthesis benchmark

The principal validation case is the classical eight-process synthesis problem.

The deterministic reference calculation enumerates all **12 logically admissible process topologies** and solves the continuous nonlinear subproblem using multistart SQP.

Reference solution:

```text
Objective value:     68.009744051065
Selected processes:  2, 4, 6, 8
```

This deterministic reference is used as the numerical benchmark for the CORAL-R1 experiments.

---

## Main computational findings

The computational study supports three main conclusions.

### 1. CORAL can recover the reference topology

In the principal repeated-run experiments, CORAL-R1 recovered the process topology **2–4–6–8** and produced feasible solutions under the reported experimental settings.

### 2. Hybridization with constrained NLP is essential

Experiments without local constrained NLP refinement generally failed to obtain continuous feasibility on the eight-process problem.

When structural search was coupled to deterministic constrained NLP refinement, CORAL, CRO-like search, and GA-based search could all recover feasible high-quality solutions under the tested conditions.

### 3. No superiority claim is made

On this relatively small benchmark, the topology-aware ecological mechanisms of CORAL-R1 did **not** demonstrate superiority over simpler hybrid search approaches.

The results therefore support CORAL-R1 as a **topology-oriented hybrid optimization framework and research platform**, rather than as evidence that coral-inspired search universally outperforms alternative optimization methods.

---

## Repository structure

```text
CORAL-R1/
│
├── src/
│   └── CORALSuperstructureOptimizer_R1.m
│
├── examples/
│   └── run_CORAL_R1_eight_process.m
│
├── benchmarks/
│   └── eight_process/
│       ├── eight_process_model.m
│       ├── eight_process_constraints.m
│       ├── eight_process_bounds.m
│       ├── eight_process_logic_feasible.m
│       └── eight_process_topology_repair.m
│
├── experiments/
│   ├── reference_enumeration/
│   ├── components/
│   ├── equal_budget/
│   ├── GA_baselines/
│   ├── localNLP_probability/
│   ├── sensitivity/
│   └── consolidate/
│
├── results/
│   ├── raw/
│   ├── summary/
│   └── figures/
│
├── docs/
│   ├── CORAL_banner.png
│   └── reproducibility.md
│
├── README.md
├── LICENSE
├── CITATION.cff
├── CHANGELOG.md
└── .gitignore
```

The `localNLP_probability` directory also contains the experiment examining local-NLP iteration intensity.

---

## Quick start

MATLAB users can start with:

```matlab
run('examples/run_CORAL_R1_eight_process.m')
```

The example:

1. loads the eight-process benchmark;
2. initializes CORAL-R1;
3. activates topology repair and explicit nonlinear constraints;
4. performs topology search with constrained local NLP refinement;
5. reports the final objective, topology, feasibility residuals, and computational counters.

For a complete reproduction of the computational study, see:

```text
docs/reproducibility.md
```

---

## Reproducing the study

A logical reproduction sequence is:

1. **Deterministic reference enumeration**
2. **Single CORAL-R1 example**
3. **Local-NLP probability sensitivity**
4. **Component ablation**
5. **Equal-oracle-budget comparison**
6. **GA and GA+local-NLP baselines**
7. **Parameter and reef-size sensitivity**
8. **Local-NLP intensity sensitivity**
9. **Statistical consolidation**

The repository includes frozen output files so that the published numerical evidence can be inspected without rerunning the more computationally expensive campaigns.

---

## Computational effort

For comparisons between algorithms, CORAL-R1 primarily uses **oracle evaluations** rather than wall-clock time.

This is intentional. Wall-clock measurements can depend strongly on hardware, MATLAB configuration, operating-system scheduling, and external computational load.

Oracle counts provide a more reproducible measure of computational effort across the reported experiments.

Runtime information is retained where available, but should be interpreted as secondary evidence.

---

## Reproducibility philosophy

CORAL-R1 distinguishes between:

- **frozen research evidence**, corresponding to the reported computational study;
- **future algorithm development**, which may modify CORAL beyond R1.

The R1 implementation and results are therefore retained as a stable reference rather than continually modified to reflect later improvements.

The aim is that the computational claims associated with the R1 study remain inspectable and reproducible even as the broader CORAL project evolves.

---

## Software requirements

CORAL-R1 is implemented in **MATLAB**.

The computational study uses:

- **Optimization Toolbox** — constrained nonlinear optimization using `fmincon`;
- **Global Optimization Toolbox** — genetic-algorithm baseline experiments.

No specific MATLAB release is claimed as a requirement.

---

## Results

Frozen computational outputs are available in:

```text
results/raw/
```

Consolidated statistical tables are available in:

```text
results/summary/
```

Publication-facing figures are available in:

```text
results/figures/
```

These include the component comparison, equal-budget experiments, baseline comparisons, local-NLP sensitivity, and reef-size sensitivity.

---

## Project status

**CORAL-R1 / v1.0.0** is a frozen research release.

The broader CORAL project remains open to further development. Potential future directions include:

- richer structural search mechanisms;
- larger chemical-process superstructures;
- alternative deterministic local solvers;
- parallel reef evaluation;
- dynamic and uncertain process-design problems;
- deeper investigation of ecological mechanisms;
- collaboration with coral-reef ecologists to explore whether greater ecological fidelity can generate useful new optimization mechanisms.

Such developments should be treated as extensions beyond CORAL-R1 rather than modifications of the frozen R1 evidence.

---

## Citation

If you use CORAL-R1 in research, please cite the software and the associated publication when available.

Citation metadata are provided in:

```text
CITATION.cff
```

GitHub can generate citation formats directly from this metadata using **Cite this repository**.

---

## Historical CORAL project

CORAL-R1 is the frozen reproducibility repository for the R1 study.

The original CORAL project and its development history are maintained separately in the main **CORAL** repository under `zondervanedwin-collab`.

This separation allows the original project to continue evolving while preserving CORAL-R1 as an immutable scientific reference.

---

## License

CORAL-R1 is released under the **MIT License**.

See `LICENSE` for details.

---

## Author

**Edwin Zondervan**  
Sustainable Process Technology  
University of Twente  
The Netherlands

ORCID: 0000-0003-2659-1622

---

**CORAL — Coral reef Optimization for Adaptive Layouts**

*Nature inspires. Algorithms evolve. Layouts improve.*
