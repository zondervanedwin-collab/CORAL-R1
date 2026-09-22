% sensitivity_localNLP_CORAL_R1.m
%
% Phase 1 - Step 3: local-NLP probability sensitivity for CORAL-R1.
%
% Purpose
% -------
% Quantify how the probability of fixed-topology SQP refinement affects:
%   * feasibility;
%   * recovery of the reference topology P2-P4-P6-P8;
%   * raw and post-polish objective quality;
%   * oracle calls;
%   * runtime;
%   * number of local NLP calls.
%
% Design
% ------
% Seven probability levels are tested, including the no-local-NLP baseline,
% the values explicitly requested by Reviewer 2, and the current R1 nominal 0.30:
%       p_NLP = [0 0.20 0.30 0.40 0.60 0.80 1.00]
%
% Ten matched seeds are used at every level. This is a screening sensitivity
% experiment; the same seed is used across all probability levels to enable
% paired comparisons. If a result is interrupted, rerunning this script will
% resume from the CSV and skip completed probability/seed combinations.
%
% IMPORTANT
% ---------
% Do not change any CORAL-R1 setting other than LocalRefineProbability.
% Final polishing is diagnostic only and is excluded from CORAL counters.

clear;
clc;

%% Frozen Step-2 reference
referenceObjective = 68.009744051065;
referenceTopology  = [0 1 0 1 0 1 0 1];

%% Sensitivity design
pLevels = [0 0.20 0.30 0.40 0.60 0.80 1.00];
nSeeds = 10;
baseSeed = 12000;
seedList = baseSeed + (1:nSeeds);

%% Frozen CORAL-R1 settings (identical to Step 2 except p_NLP)
feasTol = 1e-5;
stagnationRelTol = 1e-8;
reefSize = 120;
maxIterations = 300;
patience = 80;

%% Problem definition
[lb,ub] = eight_process_bounds;
xBounds = [lb' ub'];

%% Output files
rawFile = 'CORAL_R1_localNLP_sensitivity_runs.csv';
summaryFile = 'CORAL_R1_localNLP_sensitivity_summary.csv';
matFile = 'CORAL_R1_localNLP_sensitivity.mat';

%% Resume support
if isfile(rawFile)
    T = readtable(rawFile);
    fprintf('Existing result file found: %s\n',rawFile);
    fprintf('Completed rows will be skipped.\n\n');
else
    T = table();
end

%% Final diagnostic polishing options (not counted as CORAL work)
polishOptions = optimoptions('fmincon', ...
    'Display','off', ...
    'Algorithm','sqp', ...
    'MaxIterations',1000, ...
    'MaxFunctionEvaluations',30000, ...
    'OptimalityTolerance',1e-10, ...
    'ConstraintTolerance',1e-10, ...
    'StepTolerance',1e-12);

fprintf('CORAL-R1 local-NLP probability sensitivity\n');
fprintf('==========================================\n');
fprintf('Probability levels: '); fprintf('%.2f ',pLevels); fprintf('\n');
fprintf('Matched seeds/level: %d\n',nSeeds);
fprintf('Total planned runs : %d\n\n',numel(pLevels)*nSeeds);

%% Main sensitivity experiment
for ip = 1:numel(pLevels)
    pNLP = pLevels(ip);

    fprintf('\n------------------------------------------------------------\n');
    fprintf('p_NLP = %.2f\n',pNLP);
    fprintf('------------------------------------------------------------\n');

    for is = 1:nSeeds
        seed = seedList(is);

        % Skip completed pair when resuming.
        if ~isempty(T) && all(ismember({'pNLP','seed'},T.Properties.VariableNames))
            done = abs(T.pNLP-pNLP) < 1e-12 & T.seed == seed;
            if any(done)
                fprintf('p=%.2f seed=%d : already complete, skipped.\n',pNLP,seed);
                continue;
            end
        end

        optimizer = CORALSuperstructureOptimizer_R1( ...
            @eight_process_model, ...
            8, ...
            xBounds, ...
            'ReefSize',reefSize, ...
            'Seed',seed, ...
            'TopologyRepairFcn',@eight_process_topology_repair, ...
            'NonlinearConstraintFcn',@eight_process_constraints, ...
            'LocalRefinement',true, ...
            'AdaptiveOperators',true, ...
            'BleachingThreshold',0.12, ...
            'BleachingFraction',0.20, ...
            'LocalRefineProbability',pNLP, ...
            'LocalRefineMaxIterations',300, ...
            'LocalRefineMaxFunctionEvaluations',10000, ...
            'LocalRefineConstraintTolerance',1e-8, ...
            'FeasibilityTolerance',feasTol, ...
            'StagnationRelativeTolerance',stagnationRelTol);

        result = optimizer.optimize( ...
            'MaxIterations',maxIterations, ...
            'Patience',patience, ...
            'Verbose',false);

        b = result.best;

        % Raw result diagnostics.
        [cRaw,ceqRaw] = eight_process_constraints(b.y,b.x);
        maxEqRaw = max(abs(ceqRaw));
        maxIneqRaw = max([0;cRaw]);
        feasibleRaw = maxEqRaw <= feasTol && ...
                      maxIneqRaw <= feasTol && ...
                      eight_process_logic_feasible(b.y);
        topologyMatch = isequal(b.y,referenceTopology);
        rawObjective = b.f;
        rawGapPercent = 100*(rawObjective-referenceObjective)/abs(referenceObjective);

        % One final fixed-topology polish, used only to separate structural
        % recovery from continuous-variable convergence quality.
        polishedObjective = NaN;
        polishedGapPercent = NaN;
        feasiblePolished = false;
        polishRuntime = NaN;
        polishObjectiveCalls = NaN;
        maxEqPolished = NaN;
        maxIneqPolished = NaN;

        tPolish = tic;
        try
            yFixed = b.y;
            [xP,fP,~,outputP] = fmincon( ...
                @(x)objective_only_local(yFixed,x), ...
                b.x,[],[],[],[],lb,ub, ...
                @(x)eight_process_constraints(yFixed,x), ...
                polishOptions);
            polishRuntime = toc(tPolish);
            polishedObjective = fP;
            polishedGapPercent = 100*(fP-referenceObjective)/abs(referenceObjective);
            [cP,ceqP] = eight_process_constraints(yFixed,xP);
            maxEqPolished = max(abs(ceqP));
            maxIneqPolished = max([0;cP]);
            feasiblePolished = maxEqPolished <= feasTol && ...
                                maxIneqPolished <= feasTol && ...
                                eight_process_logic_feasible(yFixed);
            if isfield(outputP,'funcCount')
                polishObjectiveCalls = outputP.funcCount;
            end
        catch ME
            polishRuntime = toc(tPolish);
            warning('Final diagnostic polish failed at p=%.2f seed=%d: %s', ...
                pNLP,seed,ME.message);
        end

        ids = find(b.y);
        topologyLabel = string(join("P"+string(ids),"-"));

        row = table( ...
            pNLP,seed,rawObjective,rawGapPercent,feasibleRaw,topologyMatch, ...
            maxEqRaw,maxIneqRaw,polishedObjective,polishedGapPercent, ...
            feasiblePolished,maxEqPolished,maxIneqPolished, ...
            result.iterations,result.runtime, ...
            result.counters.globalModelEvaluations, ...
            result.counters.localObjectiveEvaluations, ...
            result.counters.localConstraintEvaluations, ...
            result.counters.totalModelEvaluations, ...
            result.counters.totalOracleCalls, ...
            result.counters.localNLPCalls, ...
            result.counters.localNLPIterations, ...
            result.counters.localNLPRuntime, ...
            result.counters.topologyRepairChanges, ...
            polishRuntime,polishObjectiveCalls,topologyLabel, ...
            'VariableNames',{ ...
            'pNLP','seed','rawObjective','rawGapPercent','feasibleRaw','topologyMatch', ...
            'maxEqRaw','maxIneqRaw','polishedObjective','polishedGapPercent', ...
            'feasiblePolished','maxEqPolished','maxIneqPolished', ...
            'iterations','runtimeCORAL','globalModelEvaluations', ...
            'localObjectiveEvaluations','localConstraintEvaluations', ...
            'totalModelEvaluations','totalOracleCalls','localNLPCalls', ...
            'localNLPIterations','localNLPRuntime','topologyRepairChanges', ...
            'polishRuntime','polishObjectiveCalls','topologyLabel'});

        if isempty(T)
            T = row;
        else
            T = [T; row]; %#ok<AGROW>
        end

        % Save after every run so a long experiment can safely be resumed.
        T = sortrows(T,{'pNLP','seed'});
        writetable(T,rawFile);
        save(matFile,'T','pLevels','seedList','referenceObjective','referenceTopology', ...
            'reefSize','maxIterations','patience','feasTol','stagnationRelTol');

        fprintf(['p=%4.2f seed=%d | raw=%11.7f | top=%d | feas=%d | ' ...
                 'pol=%11.7f | oracle=%8d | NLP=%5d | time=%7.2fs\n'], ...
            pNLP,seed,rawObjective,topologyMatch,feasibleRaw, ...
            polishedObjective,result.counters.totalOracleCalls, ...
            result.counters.localNLPCalls,result.runtime);
    end
end

%% Summary statistics
pOut = pLevels(:);
n = zeros(numel(pLevels),1);
feasibleRate = nan(numel(pLevels),1);
topologyRecoveryRate = nan(numel(pLevels),1);
medianRawObjective = nan(numel(pLevels),1);
medianRawGapPercent = nan(numel(pLevels),1);
medianPolishedObjective = nan(numel(pLevels),1);
medianPolishedGapPercent = nan(numel(pLevels),1);
medianOracleCalls = nan(numel(pLevels),1);
iqrOracleCalls = nan(numel(pLevels),1);
medianRuntime = nan(numel(pLevels),1);
iqrRuntime = nan(numel(pLevels),1);
medianLocalNLPCalls = nan(numel(pLevels),1);
medianIterations = nan(numel(pLevels),1);

for ip = 1:numel(pLevels)
    idx = abs(T.pNLP-pLevels(ip)) < 1e-12;
    S = T(idx,:);
    n(ip) = height(S);
    if n(ip)==0, continue; end

    feasibleRate(ip) = mean(S.feasibleRaw);
    topologyRecoveryRate(ip) = mean(S.topologyMatch);
    medianRawObjective(ip) = median(S.rawObjective,'omitnan');
    medianRawGapPercent(ip) = median(S.rawGapPercent,'omitnan');
    medianPolishedObjective(ip) = median(S.polishedObjective,'omitnan');
    medianPolishedGapPercent(ip) = median(S.polishedGapPercent,'omitnan');
    medianOracleCalls(ip) = median(S.totalOracleCalls,'omitnan');
    iqrOracleCalls(ip) = iqr(S.totalOracleCalls);
    medianRuntime(ip) = median(S.runtimeCORAL,'omitnan');
    iqrRuntime(ip) = iqr(S.runtimeCORAL);
    medianLocalNLPCalls(ip) = median(S.localNLPCalls,'omitnan');
    medianIterations(ip) = median(S.iterations,'omitnan');
end

summaryTable = table( ...
    pOut,n,feasibleRate,topologyRecoveryRate, ...
    medianRawObjective,medianRawGapPercent, ...
    medianPolishedObjective,medianPolishedGapPercent, ...
    medianOracleCalls,iqrOracleCalls,medianRuntime,iqrRuntime, ...
    medianLocalNLPCalls,medianIterations, ...
    'VariableNames',{ ...
    'pNLP','n','feasibleRate','topologyRecoveryRate', ...
    'medianRawObjective','medianRawGapPercent', ...
    'medianPolishedObjective','medianPolishedGapPercent', ...
    'medianOracleCalls','iqrOracleCalls','medianRuntime','iqrRuntime', ...
    'medianLocalNLPCalls','medianIterations'});

writetable(summaryTable,summaryFile);

fprintf('\n============================================================\n');
fprintf('LOCAL-NLP PROBABILITY SENSITIVITY SUMMARY\n');
fprintf('============================================================\n');
disp(summaryTable);
fprintf('Raw runs saved to    : %s\n',rawFile);
fprintf('Summary saved to     : %s\n',summaryFile);
fprintf('MATLAB data saved to : %s\n',matFile);
fprintf('============================================================\n');

%% Figures
fig1 = figure('Name','CORAL-R1 local NLP sensitivity - topology recovery');
plot(pOut,100*topologyRecoveryRate,'o-','LineWidth',1.5);
xlabel('Local refinement probability, p_{NLP}');
ylabel('Topology recovery [%]');
ylim([0 105]);
grid on;
title('CORAL-R1: topology recovery vs local-NLP probability');
exportgraphics(fig1,'CORAL_R1_localNLP_topology_recovery.png','Resolution',300);

fig2 = figure('Name','CORAL-R1 local NLP sensitivity - oracle calls');
plot(pOut,medianOracleCalls,'o-','LineWidth',1.5);
xlabel('Local refinement probability, p_{NLP}');
ylabel('Median total oracle calls');
grid on;
title('CORAL-R1: computational effort vs local-NLP probability');
exportgraphics(fig2,'CORAL_R1_localNLP_oracle_calls.png','Resolution',300);

fig3 = figure('Name','CORAL-R1 local NLP sensitivity - runtime');
plot(pOut,medianRuntime,'o-','LineWidth',1.5);
xlabel('Local refinement probability, p_{NLP}');
ylabel('Median CORAL runtime [s]');
grid on;
title('CORAL-R1: runtime vs local-NLP probability');
exportgraphics(fig3,'CORAL_R1_localNLP_runtime.png','Resolution',300);

%% Local helper: objective only for diagnostic final polish
function f = objective_only_local(y,x)
    [f,~,~] = eight_process_model(y,x);
end
