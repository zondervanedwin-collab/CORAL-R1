%% run_CORAL_R1_eight_process.m
% Minimal reproducible example for the frozen CORAL-R1 implementation.
%
% Run this script from the repository root after adding the source and
% benchmark directories to the MATLAB path.

clear;
clc;

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repoRoot,'src'));
addpath(fullfile(repoRoot,'benchmarks','eight_process'));

nBinary = 8;
[lb,ub] = eight_process_bounds();
xBounds = [lb(:),ub(:)];

optimizer = CORALSuperstructureOptimizer_R1( ...
    @eight_process_model, ...
    nBinary, ...
    xBounds, ...
    'ReefSize',120, ...
    'Seed',12001, ...
    'TopologyRepairFcn',@eight_process_topology_repair, ...
    'NonlinearConstraintFcn',@eight_process_constraints, ...
    'LocalRefinement',true, ...
    'AdaptiveOperators',true, ...
    'DiversityWeight',0.15, ...
    'BleachingThreshold',0.12, ...
    'BleachingFraction',0.20, ...
    'LocalRefineProbability',0.30, ...
    'LocalRefineMaxIterations',300, ...
    'LocalRefineMaxFunctionEvaluations',10000, ...
    'LocalRefineConstraintTolerance',1e-8, ...
    'FeasibilityTolerance',1e-5, ...
    'StagnationRelativeTolerance',1e-8);

result = optimizer.optimize( ...
    'MaxIterations',300, ...
    'Patience',80, ...
    'Verbose',true);

best = result.best;
[c,ceq] = eight_process_constraints(best.y,best.x);

fprintf('\n====================================================\n');
fprintf('CORAL-R1: EIGHT-PROCESS BENCHMARK\n');
fprintf('====================================================\n');
fprintf('Raw objective          : %.12f\n',best.f);
fprintf('Selected processes     : ');
fprintf('%d ',find(best.y > 0.5));
fprintf('\n');
fprintf('Max equality residual  : %.3e\n',max(abs(ceq)));
fprintf('Max inequality viol.   : %.3e\n',max([0;c(:)]));
fprintf('Logic feasible         : %d\n',eight_process_logic_feasible(best.y));
fprintf('Iterations             : %d\n',result.iterations);
fprintf('Total oracle calls     : %d\n',result.counters.totalOracleCalls);
fprintf('Local NLP calls        : %d\n',result.counters.localNLPCalls);
fprintf('Topology repairs       : %d\n',result.counters.topologyRepairChanges);
fprintf('Runtime [s]            : %.3f\n',result.runtime);

referenceObjective = 68.009744051065;
referenceTopology  = [0 1 0 1 0 1 0 1];

fprintf('\nEnumerated reference   : %.12f\n',referenceObjective);
fprintf('Reference processes    : 2 4 6 8\n');
fprintf('Topology match         : %d\n',isequal(best.y,referenceTopology));
fprintf('Signed raw gap [%%]     : %.6g\n', ...
    100*(best.f-referenceObjective)/abs(referenceObjective));
fprintf('====================================================\n');

% Note: raw CORAL-R1 objective values can lie marginally below the enumerated
% reference because feasibility is accepted at a finite tolerance (1e-5).
% The manuscript reports a separate high-accuracy fixed-topology polish when
% comparing final objective values with the deterministic reference.
