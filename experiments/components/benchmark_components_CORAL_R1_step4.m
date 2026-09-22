%% Phase 1 - Step 4: component/baseline comparison for CORAL-R1
% Four matched-seed configurations on the 8-process benchmark:
%   1 Reduced CRO-like search (no topology-aware niche/bleaching/adaptation, no NLP)
%   2 Reduced CRO-like search + constrained NLP
%   3 Topology-aware CORAL (no NLP)
%   4 Full CORAL + constrained NLP
%
% IMPORTANT:
% - CORALSuperstructureOptimizer_R1.m is NOT modified.
% - Exact topology repair is retained in all configurations so every method
%   searches the same 12 admissible structures.
% - p_NLP = 0.30 is frozen from Phase 1 Step 3.
% - This experiment is a COMPONENT comparison under identical algorithmic
%   stopping settings. It records oracle calls and runtime. Equal-oracle-call
%   budgeting should be done as a separate follow-up if required; do not call
%   these four runs equal-cost.
% - Restart safe: completed rows are saved and skipped on rerun.

clear; clc;

referenceObjective = 68.009744051065;
referenceTopology  = [0 1 0 1 0 1 0 1];
[lb,ub] = eight_process_bounds();
xBounds = [lb(:), ub(:)];

seeds = 12001:12010;
reefSize = 120;
maxIterations = 300;
patience = 80;
feasTol = 1e-5;
stagnationRelTol = 1e-8;
pNLP = 0.30;

% Topology-aware CORAL settings frozen from Steps 2/3.
TA_bleachThreshold = 0.12;
TA_bleachFraction  = 0.20;
TA_diversityWeight = 0.15; % class default used by frozen R1

% Reduced CRO-like comparator: retain the same reproduction operators,
% repair, selection and population size, but disable the explicitly
% topology-aware/adaptive mechanisms.
configs = struct( ...
 'name', {'CRO_like','CRO_like_NLP','CORAL_noNLP','CORAL_full'}, ...
 'local', {false,true,false,true}, ...
 'adaptive', {false,false,true,true}, ...
 'divWeight', {0,0,TA_diversityWeight,TA_diversityWeight}, ...
 'bleachThreshold', {0,0,TA_bleachThreshold,TA_bleachThreshold}, ...
 'bleachFraction', {TA_bleachFraction,TA_bleachFraction,TA_bleachFraction,TA_bleachFraction});

outRuns = 'CORAL_R1_step4_component_runs.csv';
outSummary = 'CORAL_R1_step4_component_summary.csv';
outMat = 'CORAL_R1_step4_component.mat';

vars = {'Configuration','Seed','LocalRefinement','AdaptiveOperators', ...
    'RawObjective','RawGapPercent','Feasible','TopologyMatch', ...
    'Iterations','OracleCalls','GlobalModelEvaluations', ...
    'LocalObjectiveEvaluations','LocalConstraintEvaluations', ...
    'LocalNLPCalls','LocalNLPIterations','TopologyRepairs','Runtime'};
types = {'string','double','logical','logical', ...
    'double','double','logical','logical', ...
    'double','double','double','double','double','double','double','double','double'};

if isfile(outRuns)
    T = readtable(outRuns,'TextType','string');
    fprintf('Resuming from %s (%d completed rows).\n',outRuns,height(T));
else
    T = table('Size',[0 numel(vars)],'VariableTypes',types,'VariableNames',vars);
end

fprintf('\nCORAL-R1 Phase 1 Step 4 - component comparison\n');
fprintf('================================================\n');
fprintf('Matched seeds/configuration: %d\n',numel(seeds));
fprintf('p_NLP when enabled       : %.2f\n\n',pNLP);

for ic = 1:numel(configs)
    C = configs(ic);
    fprintf('\n------------------------------------------------------------\n%s\n------------------------------------------------------------\n',C.name);
    for seed = seeds
        already = any(T.Configuration == string(C.name) & T.Seed == seed);
        if already
            fprintf('%s seed=%d already complete; skipping.\n',C.name,seed);
            continue;
        end

        opt = CORALSuperstructureOptimizer_R1( ...
            @eight_process_model,8,xBounds, ...
            'ReefSize',reefSize, ...
            'Seed',seed, ...
            'TopologyRepairFcn',@eight_process_topology_repair, ...
            'NonlinearConstraintFcn',@eight_process_constraints, ...
            'LocalRefinement',C.local, ...
            'LocalRefineProbability',pNLP, ...
            'AdaptiveOperators',C.adaptive, ...
            'DiversityWeight',C.divWeight, ...
            'BleachingThreshold',C.bleachThreshold, ...
            'BleachingFraction',C.bleachFraction, ...
            'LocalRefineMaxIterations',300, ...
            'LocalRefineMaxFunctionEvaluations',10000, ...
            'LocalRefineConstraintTolerance',1e-8, ...
            'FeasibilityTolerance',feasTol, ...
            'StagnationRelativeTolerance',stagnationRelTol);

        R = opt.optimize('MaxIterations',maxIterations,'Patience',patience,'Verbose',false);
        b = R.best;
        [c,ceq] = eight_process_constraints(b.y,b.x);
        maxEq = max(abs(ceq));
        maxIneq = max([0;c]);
        feasible = maxEq <= feasTol && maxIneq <= feasTol && eight_process_logic_feasible(b.y);
        topmatch = isequal(b.y,referenceTopology);
        gap = 100*(b.f-referenceObjective)/abs(referenceObjective);

        row = {string(C.name),seed,C.local,C.adaptive,b.f,gap,feasible,topmatch, ...
            R.iterations,R.counters.totalOracleCalls,R.counters.globalModelEvaluations, ...
            R.counters.localObjectiveEvaluations,R.counters.localConstraintEvaluations, ...
            R.counters.localNLPCalls,R.counters.localNLPIterations, ...
            R.counters.topologyRepairChanges,R.runtime};
        T = [T; cell2table(row,'VariableNames',vars)]; %#ok<AGROW>
        writetable(T,outRuns);

        fprintf('%-13s seed=%d | obj=%11.7f | top=%d | feas=%d | oracle=%8d | NLP=%5d | it=%3d | %7.1fs\n', ...
            C.name,seed,b.f,topmatch,feasible,R.counters.totalOracleCalls, ...
            R.counters.localNLPCalls,R.iterations,R.runtime);
    end
end

% Summary
S = table('Size',[numel(configs) 11], ...
    'VariableTypes',{'string','double','double','double','double','double','double','double','double','double','double'}, ...
    'VariableNames',{'Configuration','n','FeasibleRate','TopologyRecoveryRate', ...
    'MedianRawObjective','MedianAbsGapPercent','MedianOracleCalls','IQROracleCalls', ...
    'MedianRuntime','MedianLocalNLPCalls','MedianIterations'});

for ic=1:numel(configs)
    idx = T.Configuration == string(configs(ic).name);
    A = T(idx,:);
    S.Configuration(ic)=string(configs(ic).name);
    S.n(ic)=height(A);
    S.FeasibleRate(ic)=mean(A.Feasible);
    S.TopologyRecoveryRate(ic)=mean(A.TopologyMatch);
    S.MedianRawObjective(ic)=median(A.RawObjective);
    S.MedianAbsGapPercent(ic)=median(abs(A.RawGapPercent));
    S.MedianOracleCalls(ic)=median(A.OracleCalls);
    S.IQROracleCalls(ic)=iqr(A.OracleCalls);
    S.MedianRuntime(ic)=median(A.Runtime);
    S.MedianLocalNLPCalls(ic)=median(A.LocalNLPCalls);
    S.MedianIterations(ic)=median(A.Iterations);
end

writetable(S,outSummary);
save(outMat,'T','S','configs','seeds','referenceObjective','referenceTopology', ...
    'reefSize','maxIterations','patience','feasTol','pNLP');

fprintf('\n============================================================\nSTEP 4 COMPONENT COMPARISON SUMMARY\n============================================================\n');
disp(S);
fprintf('Runs    : %s\n',outRuns);
fprintf('Summary : %s\n',outSummary);
fprintf('MAT     : %s\n',outMat);
fprintf('============================================================\n');
