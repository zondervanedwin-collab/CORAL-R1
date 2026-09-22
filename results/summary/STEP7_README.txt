CORAL-R1 Phase 1 Step 7 - frozen statistical consolidation
Reference objective: 68.009744051065

Key evidence:
- 8-process deterministic enumeration reference: 68.009744051065, topology P2-P4-P6-P8.
- Direct constrained GA: 0/10 feasible, 0/10 reference-topology recovery within 1.5M calls.
- GA+local NLP, CRO-like+NLP, and CORAL-R1+NLP: 10/10 feasible and 10/10 topology recovery in equal-budget experiments.
- No solution-quality superiority of CORAL over simpler hybrids is claimed on this small benchmark.
- p_NLP=0.30 retained: lowest median oracle effort among successful tested probabilities.
- Reef-size confirmation: topology recovery 10/10 at sizes 60,120,240; feasibility 9/10,7/10,3/10 respectively.
- Reef size 60 is cheaper on this benchmark, but nominal 120 is retained to avoid post-hoc tuning.
- Oracle calls are the primary effort metric; wall-clock timing contained external anomalies.
