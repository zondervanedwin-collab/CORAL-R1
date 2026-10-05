# Topology-aware early-stopping experiment

This experiment was added in response to peer review of the CORAL-R1
manuscript. It evaluates the topology-aware stopping criterion implemented
in `CORALSuperstructureOptimizer_R1_ES.m`.

## Experimental setup

- Benchmark: classical eight-process synthesis problem
- Number of runs: 30
- Seeds: 12001–12030
- Reef size: 120
- Maximum CORAL iterations: 300
- Local NLP probability: 0.30
- Feasibility tolerance: 1e-5
- Topology-stability window: Ns = 20 iterations
- Objective-stability tolerance: epsilon_s = 1e-6

The stopping parameters were fixed before the 30-run comparison and were
not tuned to individual runs.

The search terminates when a feasible incumbent has retained the same
binary topology for 20 consecutive iterations and the relative change in
the incumbent objective over the same interval is no greater than 1e-6.

## Results

- Feasible solutions: 30/30
- Reference-topology recovery: 30/30
- Early-stopping criterion activated: 30/30
- Median termination iteration: 21
- Median raw objective: 68.009744051001
- Reference objective: 68.009744051065
- Polished median objective: 68.009744051065
- Median total oracle calls: 378,695
- Median local NLP calls: 714

For comparison, the original frozen 30-run CORAL-R1 validation required:

- Median total oracle calls: 1,447,466
- Median local NLP calls: 2,797

The topology-aware stopping criterion therefore reduced median total
oracle calls by 73.8% and median local NLP calls by 74.5%, while
preserving 30/30 feasibility and 30/30 recovery of the reference topology.

## Interpretation

The result indicates that, for this benchmark, the relevant process
topology stabilizes considerably earlier than the original generic
stagnation criterion terminates the search. Topology stabilization can
therefore be used as a practical stopping signal to avoid repeated
continuous NLP refinement after the structural search has stabilized.

This experiment should not be interpreted as demonstrating that
early-stopped CORAL is more efficient than the CRO-like+NLP baseline,
because the same topology-aware stopping criterion was not applied to
that baseline.
