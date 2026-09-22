# Changelog

All notable changes to the CORAL project will be documented in this file.

## CORAL-R1

Initial frozen research release of **CORAL — Coral reef Optimization for Adaptive Layouts**.

### Included

- Frozen `CORALSuperstructureOptimizer_R1` implementation.
- Eight-process synthesis benchmark and topology logic.
- Deterministic multistart-SQP reference enumeration.
- Minimal reproducible CORAL-R1 example.
- Local-NLP probability and intensity sensitivity experiments.
- Component comparison of CORAL and reduced CRO-like configurations.
- Equal-oracle-budget comparison.
- Direct constrained GA and hybrid GA-NLP baselines.
- Parameter and reef-size sensitivity studies.
- Frozen run-level computational results.
- Consolidated statistical tables with confidence intervals.
- Publication-facing figures.
- Reproducibility documentation.

### Reference benchmark result

The deterministic enumeration identifies:

```text
Objective:           68.009744051065
Selected processes:  2, 4, 6, 8
