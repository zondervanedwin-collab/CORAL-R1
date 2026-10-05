# Deterministic global MINLP comparison using BARON

This experiment was added in response to peer review of the CORAL-R1
manuscript. Its purpose is to compare CORAL with a deterministic global
MINLP solver on the classical eight-process synthesis benchmark.

## Model

`logmip3_baron_revised.gms` is an algebraic MINLP reformulation of the
eight-process LOGMIP3 benchmark.

The original model contains disjunctive process equations and logical
relations between the eight candidate process units. For the BARON
comparison, these relations are represented algebraically using binary
variables and big-M constraints.

An earlier comparison model used a blanket upper bound of 20 for all
continuous stream variables. This bound is not part of the canonical
LOGMIP3 formulation and is therefore not used here.

Instead, finite upper bounds are derived analytically from the explicit
bounds, mass balances, process equations, specifications, and active/off
disjunctions of the benchmark. Unit-specific big-M constants are derived
from these valid bounds.

## Solver

The reported calculation used:

- GAMS 40.1.1
- BARON 22.7.23
- MINLP formulation
- `optcr = 0`
- resource limit = 300 s

The complete solver output is provided in
`logmip3_baron_revised.lst`.

## Result

BARON returned:

- Solver status: Normal Completion
- Model status: Optimal
- Objective: 68.0097429224943
- Best possible bound: 68.0097428545
- Absolute gap: 6.7994e-8
- Relative gap: 9.9977e-10
- Selected units: 2, 4, 6, and 8
- Solver resource usage: 2.520 s
- Evaluation errors: 0

The selected topology and objective agree with the deterministic reference
solution used in the CORAL-R1 study.

## Interpretation

For this small and algebraically explicit MINLP benchmark, deterministic
global optimization is clearly preferable to stochastic structural search:
BARON identifies the reference topology and provides a global optimality
certificate in a few seconds.

The purpose of CORAL-R1 is therefore not to claim superiority over a
deterministic global MINLP solver on this problem. The benchmark instead
provides a controlled environment for studying a reproducible hybrid
structural-search/constrained-NLP architecture.

Potential advantages of topology-aware stochastic search may arise for
larger structural spaces or problems involving simulation-based,
black-box, or otherwise less explicit models. Such advantages are not
demonstrated by the present eight-process benchmark and remain a subject
for future investigation.
