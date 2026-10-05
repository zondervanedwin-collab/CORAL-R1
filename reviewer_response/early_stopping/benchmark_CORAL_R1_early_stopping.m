% benchmark_CORAL_R1_early_stopping.m
%
% Matched-seed test of topology-aware early stopping for frozen CORAL-R1.
% This script is intended for the Processes major revision evidence base.
%
% Key reproducibility features:
%   * fixed seed list;
%   * exact topology repair and nonlinear constraints;
%   * explicit feasibility tolerance;
%   * complete CORAL global/local evaluation accounting;
%   * raw CORAL result separated from optional final NLP polishing;
%   * runtime and repair counts saved for every run.

clear;
clc;

%% Frozen settings
nRuns = 30;
baseSeed = 12000;
feasTol = 1e-5;
stagnationRelTol = 1e-8;

reefSize = 120;
maxIterations = 300;
patience = 80;
localRefineProbability = 0.30; % legacy 8-process nominal; sensitivity tested separately
topologyEarlyStopping = true;
topologyPatience = 20;
topologyObjectiveTolerance = 1e-6;

%% Deterministic enumeration + multistart SQP reference
fprintf('Computing CORAL-R1 deterministic reference...\n');
reference = reference_eight_process_enumeration_R1( ...
    'MultiStartN',30, ...
    'Seed',321, ...
    'Display',false, ...
    'FeasibilityTolerance',feasTol);

referenceObjective = reference.best.f;
referenceTopology  = reference.best.y;

fprintf('Reference objective : %.12f\n',referenceObjective);
fprintf('Reference topology  : '); fprintf('%d ',find(referenceTopology)); fprintf('\n');
fprintf('Reference topologies: %d\n',reference.nFeasibleTopologies);
fprintf('Reference starts    : %d\n',reference.totalStarts);
fprintf('Reference oracle calls: %d\n',reference.totalOracleCalls);
fprintf('Reference runtime   : %.3f s\n\n',reference.runtime);

%% Problem definition
[lb,ub] = eight_process_bounds;
xBounds = [lb' ub'];

%% Storage
runNumber = (1:nRuns)';
seed = (baseSeed+(1:nRuns))';
objectiveRaw = nan(nRuns,1);
objectivePolished = nan(nRuns,1);
gapRawPercent = nan(nRuns,1);
gapPolishedPercent = nan(nRuns,1);
violationRaw = nan(nRuns,1);
feasibleRaw = false(nRuns,1);
feasiblePolished = false(nRuns,1);
topologyMatchRaw = false(nRuns,1);
topologyMatchPolished = false(nRuns,1);
maxEqRaw = nan(nRuns,1);
maxIneqRaw = nan(nRuns,1);
maxEqPolished = nan(nRuns,1);
maxIneqPolished = nan(nRuns,1);
runtimeCORAL = nan(nRuns,1);
runtimePolish = nan(nRuns,1);
iterations = nan(nRuns,1);
globalModelEvaluations = nan(nRuns,1);
localObjectiveEvaluations = nan(nRuns,1);
localConstraintEvaluations = nan(nRuns,1);
totalModelEvaluations = nan(nRuns,1);
totalOracleCalls = nan(nRuns,1);
localNLPCalls = nan(nRuns,1);
localNLPIterations = nan(nRuns,1);
localNLPRuntime = nan(nRuns,1);
topologyRepairChanges = nan(nRuns,1);
polishObjectiveCalls = nan(nRuns,1);
bestYRaw = zeros(nRuns,8);
bestYPolished = zeros(nRuns,8);
allHistory = cell(nRuns,1);
earlyStopTriggered = false(nRuns,1);

%% Final polishing options (post-CORAL; reported separately)
polishOptions = optimoptions('fmincon', ...
    'Display','off', ...
    'Algorithm','sqp', ...
    'MaxIterations',1000, ...
    'MaxFunctionEvaluations',30000, ...
    'OptimalityTolerance',1e-10, ...
    'ConstraintTolerance',1e-10, ...
    'StepTolerance',1e-12);

%% Main benchmark
for r = 1:nRuns

    optimizer = CORALSuperstructureOptimizer_R1_ES( ...
        @eight_process_model, ...
        8, ...
        xBounds, ...
        'ReefSize',reefSize, ...
        'Seed',seed(r), ...
        'TopologyRepairFcn',@eight_process_topology_repair, ...
        'NonlinearConstraintFcn',@eight_process_constraints, ...
        'LocalRefinement',true, ...
        'AdaptiveOperators',true, ...
        'BleachingThreshold',0.12, ...
        'BleachingFraction',0.20, ...
        'LocalRefineProbability',localRefineProbability, ...
        'LocalRefineMaxIterations',300, ...
        'LocalRefineMaxFunctionEvaluations',10000, ...
        'LocalRefineConstraintTolerance',1e-8, ...
        'FeasibilityTolerance',feasTol, ...
        'StagnationRelativeTolerance',stagnationRelTol, ...
        'TopologyEarlyStopping',topologyEarlyStopping, ...
        'TopologyPatience',topologyPatience, ...
        'TopologyObjectiveTolerance',topologyObjectiveTolerance);

    result = optimizer.optimize( ...
        'MaxIterations',maxIterations, ...
        'Patience',patience, ...
        'Verbose',false);

    b = result.best;

    %% Raw CORAL-R1 result
    objectiveRaw(r) = b.f;
    violationRaw(r) = b.v;
    iterations(r) = result.iterations;
    runtimeCORAL(r) = result.runtime;
    bestYRaw(r,:) = b.y;
    allHistory{r} = result.history.bestF;
    earlyStopTriggered(r) = result.earlyStopTriggered;

    globalModelEvaluations(r) = result.counters.globalModelEvaluations;
    localObjectiveEvaluations(r) = result.counters.localObjectiveEvaluations;
    localConstraintEvaluations(r) = result.counters.localConstraintEvaluations;
    totalModelEvaluations(r) = result.counters.totalModelEvaluations;
    totalOracleCalls(r) = result.counters.totalOracleCalls;
    localNLPCalls(r) = result.counters.localNLPCalls;
    localNLPIterations(r) = result.counters.localNLPIterations;
    localNLPRuntime(r) = result.counters.localNLPRuntime;
    topologyRepairChanges(r) = result.counters.topologyRepairChanges;

    [cRaw,ceqRaw] = eight_process_constraints(b.y,b.x);
    maxEqRaw(r) = max(abs(ceqRaw));
    maxIneqRaw(r) = max([0;cRaw]);

    feasibleRaw(r) = ...
        maxEqRaw(r) <= feasTol && ...
        maxIneqRaw(r) <= feasTol && ...
        eight_process_logic_feasible(b.y);

    topologyMatchRaw(r) = isequal(b.y,referenceTopology);
    gapRawPercent(r) = 100*(objectiveRaw(r)-referenceObjective)/abs(referenceObjective);

    %% Optional final constrained polish; excluded from CORAL core counters
    yFixed = b.y;
    tPolish = tic;

    try
        [xPolished,fPolished,~,outputP] = fmincon( ...
            @(x)objective_only(yFixed,x), ...
            b.x, ...
            [],[],[],[], ...
            lb,ub, ...
            @(x)eight_process_constraints(yFixed,x), ...
            polishOptions);

        runtimePolish(r) = toc(tPolish);
        if isfield(outputP,'funcCount')
            polishObjectiveCalls(r)=outputP.funcCount;
        end

        [cP,ceqP] = eight_process_constraints(yFixed,xPolished);
        maxEqPolished(r) = max(abs(ceqP));
        maxIneqPolished(r) = max([0;cP]);
        objectivePolished(r) = fPolished;
        bestYPolished(r,:) = yFixed;

        feasiblePolished(r) = ...
            maxEqPolished(r) <= feasTol && ...
            maxIneqPolished(r) <= feasTol && ...
            eight_process_logic_feasible(yFixed);

        topologyMatchPolished(r) = isequal(yFixed,referenceTopology);
        gapPolishedPercent(r) = ...
            100*(objectivePolished(r)-referenceObjective)/abs(referenceObjective);

    catch ME
        runtimePolish(r) = toc(tPolish);
        warning('Polish failed for run %d: %s',r,ME.message);
        objectivePolished(r) = objectiveRaw(r);
        maxEqPolished(r) = maxEqRaw(r);
        maxIneqPolished(r) = maxIneqRaw(r);
        feasiblePolished(r) = feasibleRaw(r);
        topologyMatchPolished(r) = topologyMatchRaw(r);
        gapPolishedPercent(r) = gapRawPercent(r);
        bestYPolished(r,:) = bestYRaw(r,:);
    end

    fprintf(['run=%2d | raw=%11.7f | polished=%11.7f | gap=%9.5f%% | ' ...
             'feas=%d | top=%d | oracle=%8d | localNLP=%5d | repairs=%6d | ' ...
             'CORAL=%7.2fs\n'], ...
             r,objectiveRaw(r),objectivePolished(r),gapPolishedPercent(r), ...
             feasiblePolished(r),topologyMatchPolished(r),totalOracleCalls(r), ...
             localNLPCalls(r),topologyRepairChanges(r),runtimeCORAL(r));
end

%% Results table
resultsTable = table( ...
    runNumber,seed,objectiveRaw,objectivePolished,gapRawPercent,gapPolishedPercent, ...
    violationRaw,feasibleRaw,feasiblePolished,topologyMatchRaw,topologyMatchPolished, ...
    maxEqRaw,maxIneqRaw,maxEqPolished,maxIneqPolished,iterations,runtimeCORAL,runtimePolish, ...
    globalModelEvaluations,localObjectiveEvaluations,localConstraintEvaluations, ...
    totalModelEvaluations,totalOracleCalls,localNLPCalls,localNLPIterations, ...
    localNLPRuntime,topologyRepairChanges,polishObjectiveCalls,earlyStopTriggered);

writetable(resultsTable,'CORAL_R1_early_stopping_runs.csv');
save('CORAL_R1_early_stopping_histories.mat','allHistory','seed','reference', ...
    'reefSize','maxIterations','patience','localRefineProbability','feasTol', ...
    'stagnationRelTol','topologyEarlyStopping','topologyPatience', ...
    'topologyObjectiveTolerance','earlyStopTriggered');

%% Summary
fprintf('\n============================================================\n');
fprintf('CORAL-R1 + TOPOLOGY-AWARE EARLY STOPPING: 8-PROCESS BENCHMARK\n');
fprintf('============================================================\n');
fprintf('Reference objective          : %.12f\n',referenceObjective);
fprintf('Reference topology           : '); fprintf('%d ',find(referenceTopology)); fprintf('\n');
fprintf('Reference feasible topologies: %d\n',reference.nFeasibleTopologies);
fprintf('Reference SQP starts         : %d\n',reference.totalStarts);
fprintf('Reference oracle calls       : %d\n',reference.totalOracleCalls);
fprintf('Reference runtime [s]        : %.3f\n\n',reference.runtime);

fprintf('RAW CORAL-R1 + EARLY STOPPING\n');
fprintf('Feasible runs                : %d/%d (%.1f%%)\n',nnz(feasibleRaw),nRuns,100*mean(feasibleRaw));
fprintf('Topology recovery            : %d/%d (%.1f%%)\n',nnz(topologyMatchRaw),nRuns,100*mean(topologyMatchRaw));
fprintf('Best objective               : %.12f\n',min(objectiveRaw));
fprintf('Median objective             : %.12f\n',median(objectiveRaw));
fprintf('Median gap [%%]               : %.8f\n',median(gapRawPercent));
fprintf('Median CORAL runtime [s]     : %.3f\n',median(runtimeCORAL));
fprintf('Median total oracle calls    : %.0f\n',median(totalOracleCalls));
fprintf('Median local NLP calls       : %.0f\n',median(localNLPCalls));
fprintf('Median topology repairs      : %.0f\n',median(topologyRepairChanges));
fprintf('Early-stop triggered         : %d/%d (%.1f%%)\n',nnz(earlyStopTriggered),nRuns,100*mean(earlyStopTriggered));
fprintf('Median iterations            : %.1f\n\n',median(iterations));

fprintf('AFTER FINAL NLP POLISH (reported separately)\n');
fprintf('Feasible runs                : %d/%d (%.1f%%)\n',nnz(feasiblePolished),nRuns,100*mean(feasiblePolished));
fprintf('Topology recovery            : %d/%d (%.1f%%)\n',nnz(topologyMatchPolished),nRuns,100*mean(topologyMatchPolished));
fprintf('Median objective             : %.12f\n',median(objectivePolished));
fprintf('Std objective                : %.12e\n',std(objectivePolished));
fprintf('Median gap [%%]               : %.8f\n',median(gapPolishedPercent));
fprintf('Median polish runtime [s]    : %.3f\n',median(runtimePolish));
fprintf('============================================================\n');

%% Topology frequencies
labels = strings(nRuns,1);
for r = 1:nRuns
    ids = find(bestYPolished(r,:));
    labels(r) = join("P"+string(ids),"-");
end
[G,names] = findgroups(labels);
frequency = splitapply(@numel,labels,G);
topologyFrequency = sortrows(table(names,frequency),'frequency','descend');
writetable(topologyFrequency,'CORAL_R1_early_stopping_topology_frequencies.csv');

%% Plot: polished relative gap (publication figure styling deferred)
figure;
bar(runNumber,gapPolishedPercent);
yline(0,'--','Reference');
xlabel('Independent run');
ylabel('Relative optimality gap [%]');
title('CORAL-R1 + early stopping - 8-process synthesis - polished optimality gap');
grid on;

function f=objective_only(y,x)
    [f,~,~]=eight_process_model(y,x);
end
