%% sensitivity_localNLP_intensity_CORAL_R1.m
%
% Phase 3.3: local-NLP INTENSITY sensitivity for frozen CORAL-R1.
%
% PURPOSE
% -------
% Complete Reviewer 2.2 by varying the maximum SQP iterations allowed per
% fixed-topology local-refinement call, while keeping p_NLP and every other
% CORAL-R1 setting frozen.
%
% DESIGN
% ------
% LocalRefineMaxIterations = [50 100 300 600]
% LocalRefineMaxFunctionEvaluations = 10000 for every setting.
% p_NLP = 0.30 for every setting.
% Ten matched seeds: 12001:12010.
%
% IMPORTANT
% ---------
% * CORALSuperstructureOptimizer_R1.m is NOT modified.
% * Only LocalRefineMaxIterations changes between configurations.
% * The 10000-function-evaluation limit is retained as a common safeguard,
%   not treated as a second tuning dimension.
% * Final polishing is diagnostic only and excluded from CORAL counters.
% * The script is restart-safe: completed intensity/seed pairs are skipped.
% * Oracle calls are the primary computational-effort measure.
%
% REQUIRED FILES ON MATLAB PATH
% -----------------------------
% CORALSuperstructureOptimizer_R1.m
% eight_process_model.m
% eight_process_constraints.m
% eight_process_bounds.m
% eight_process_logic_feasible.m
% eight_process_topology_repair.m
%
% OUTPUTS
% -------
% CORAL_R1_localNLP_intensity_runs.csv
% CORAL_R1_localNLP_intensity_summary.csv
% CORAL_R1_localNLP_intensity.mat
% CORAL_R1_localNLP_intensity_oracle_calls.png
% CORAL_R1_localNLP_intensity_feasibility.png
% CORAL_R1_localNLP_intensity_iterations.png

clear;
clc;

%% Frozen reference
referenceObjective = 68.009744051065;
referenceTopology  = [0 1 0 1 0 1 0 1];

%% Phase 3.3 design
intensityLevels = [50 100 300 600];
nSeeds = 10;
seedList = 12001:12010;

%% Frozen CORAL-R1 settings
pNLP = 0.30;
feasTol = 1e-5;
stagnationRelTol = 1e-8;
reefSize = 120;
maxIterations = 300;
patience = 80;

% Frozen local-NLP settings except for LocalRefineMaxIterations.
localMaxFunctionEvaluations = 10000;
localConstraintTolerance = 1e-8;

% Frozen topology-aware CORAL settings used in the revision campaign.
bleachingThreshold = 0.12;
bleachingFraction = 0.20;

%% Dependency checks
requiredFunctions = { ...
    'CORALSuperstructureOptimizer_R1', ...
    'eight_process_model', ...
    'eight_process_constraints', ...
    'eight_process_bounds', ...
    'eight_process_logic_feasible', ...
    'eight_process_topology_repair'};

for k = 1:numel(requiredFunctions)
    if exist(requiredFunctions{k},'file') == 0
        error('Required file/function not found on MATLAB path: %s',requiredFunctions{k});
    end
end

if exist('fmincon','file') ~= 2
    error('MATLAB Optimization Toolbox function fmincon was not found.');
end

%% Problem definition
[lb,ub] = eight_process_bounds();
lb = lb(:);
ub = ub(:);
xBounds = [lb ub];

%% Output files
rawFile = 'CORAL_R1_localNLP_intensity_runs.csv';
summaryFile = 'CORAL_R1_localNLP_intensity_summary.csv';
matFile = 'CORAL_R1_localNLP_intensity.mat';

%% Restart support
if isfile(rawFile)
    T = readtable(rawFile,'TextType','string');
    fprintf('Existing result file found: %s\n',rawFile);
    fprintf('Completed intensity/seed pairs will be skipped.\n\n');
else
    T = table();
end

%% Final diagnostic polishing options
% Not counted as CORAL work. This polish separates structural recovery from
% residual continuous-convergence quality.
polishOptions = optimoptions('fmincon', ...
    'Display','off', ...
    'Algorithm','sqp', ...
    'MaxIterations',1000, ...
    'MaxFunctionEvaluations',30000, ...
    'OptimalityTolerance',1e-10, ...
    'ConstraintTolerance',1e-10, ...
    'StepTolerance',1e-12);

fprintf('CORAL-R1 local-NLP INTENSITY sensitivity\n');
fprintf('========================================\n');
fprintf('SQP iteration limits : '); fprintf('%d ',intensityLevels); fprintf('\n');
fprintf('p_NLP frozen at      : %.2f\n',pNLP);
fprintf('Local max func evals : %d\n',localMaxFunctionEvaluations);
fprintf('Matched seeds/level  : %d\n',nSeeds);
fprintf('Total planned runs   : %d\n\n',numel(intensityLevels)*nSeeds);

%% Main experiment
for ii = 1:numel(intensityLevels)

    localMaxIterations = intensityLevels(ii);

    fprintf('\n------------------------------------------------------------\n');
    fprintf('LocalRefineMaxIterations = %d\n',localMaxIterations);
    fprintf('------------------------------------------------------------\n');

    for is = 1:nSeeds

        seed = seedList(is);

        % Restart-safe skip.
        if ~isempty(T) && all(ismember( ...
                {'LocalRefineMaxIterations','Seed'},T.Properties.VariableNames))
            done = T.LocalRefineMaxIterations == localMaxIterations & ...
                   T.Seed == seed;
            if any(done)
                fprintf('NLPiter=%d seed=%d : already complete, skipped.\n', ...
                    localMaxIterations,seed);
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
            'BleachingThreshold',bleachingThreshold, ...
            'BleachingFraction',bleachingFraction, ...
            'LocalRefineProbability',pNLP, ...
            'LocalRefineMaxIterations',localMaxIterations, ...
            'LocalRefineMaxFunctionEvaluations',localMaxFunctionEvaluations, ...
            'LocalRefineConstraintTolerance',localConstraintTolerance, ...
            'FeasibilityTolerance',feasTol, ...
            'StagnationRelativeTolerance',stagnationRelTol);

        result = optimizer.optimize( ...
            'MaxIterations',maxIterations, ...
            'Patience',patience, ...
            'Verbose',false);

        b = result.best;

        %% Raw result diagnostics
        [cRaw,ceqRaw] = eight_process_constraints(b.y,b.x);
        maxEqRaw = local_max_abs(ceqRaw);
        maxIneqRaw = local_max_positive(cRaw);

        feasibleRaw = maxEqRaw <= feasTol && ...
                      maxIneqRaw <= feasTol && ...
                      eight_process_logic_feasible(b.y);

        topologyMatch = isequal(b.y(:)',referenceTopology);

        rawObjective = b.f;
        rawGapPercent = 100*(rawObjective-referenceObjective) / ...
                        abs(referenceObjective);
        rawAbsGapPercent = abs(rawGapPercent);

        %% Diagnostic final fixed-topology polish
        polishedObjective = NaN;
        polishedGapPercent = NaN;
        polishedAbsGapPercent = NaN;
        feasiblePolished = false;
        maxEqPolished = NaN;
        maxIneqPolished = NaN;
        polishRuntime = NaN;
        polishObjectiveCalls = NaN;
        polishExitflag = NaN;

        tPolish = tic;
        try
            yFixed = b.y;
            [xP,fP,polishExitflag,outputP] = fmincon( ...
                @(x)objective_only_local(yFixed,x), ...
                b.x,[],[],[],[],lb,ub, ...
                @(x)eight_process_constraints(yFixed,x), ...
                polishOptions);

            polishRuntime = toc(tPolish);
            polishedObjective = fP;
            polishedGapPercent = 100*(fP-referenceObjective) / ...
                                 abs(referenceObjective);
            polishedAbsGapPercent = abs(polishedGapPercent);

            [cP,ceqP] = eight_process_constraints(yFixed,xP);
            maxEqPolished = local_max_abs(ceqP);
            maxIneqPolished = local_max_positive(cP);

            feasiblePolished = maxEqPolished <= feasTol && ...
                                maxIneqPolished <= feasTol && ...
                                eight_process_logic_feasible(yFixed);

            if isfield(outputP,'funcCount')
                polishObjectiveCalls = outputP.funcCount;
            end

        catch ME
            polishRuntime = toc(tPolish);
            warning('Diagnostic polish failed for NLPiter=%d seed=%d: %s', ...
                localMaxIterations,seed,ME.message);
        end

        %% Mean local SQP iterations per local-NLP call
        if result.counters.localNLPCalls > 0
            meanIterationsPerLocalNLP = ...
                result.counters.localNLPIterations / ...
                result.counters.localNLPCalls;
        else
            meanIterationsPerLocalNLP = NaN;
        end

        topologyCode = sum(double(b.y(:)').*(2.^(0:7)));

        %% Store one restart-safe row
        row = table( ...
            localMaxIterations,localMaxFunctionEvaluations,pNLP,seed, ...
            rawObjective,rawGapPercent,rawAbsGapPercent, ...
            feasibleRaw,topologyMatch,maxEqRaw,maxIneqRaw, ...
            polishedObjective,polishedGapPercent,polishedAbsGapPercent, ...
            feasiblePolished,maxEqPolished,maxIneqPolished, ...
            result.iterations,result.runtime, ...
            result.counters.globalModelEvaluations, ...
            result.counters.localObjectiveEvaluations, ...
            result.counters.localConstraintEvaluations, ...
            result.counters.totalModelEvaluations, ...
            result.counters.totalOracleCalls, ...
            result.counters.localNLPCalls, ...
            result.counters.localNLPIterations, ...
            meanIterationsPerLocalNLP, ...
            result.counters.localNLPRuntime, ...
            result.counters.topologyRepairChanges, ...
            polishRuntime,polishObjectiveCalls,polishExitflag,topologyCode, ...
            'VariableNames',{ ...
            'LocalRefineMaxIterations','LocalRefineMaxFunctionEvaluations', ...
            'pNLP','Seed', ...
            'RawObjective','RawGapPercent','RawAbsGapPercent', ...
            'FeasibleRaw','TopologyMatch','MaxEqRaw','MaxIneqRaw', ...
            'PolishedObjective','PolishedGapPercent','PolishedAbsGapPercent', ...
            'FeasiblePolished','MaxEqPolished','MaxIneqPolished', ...
            'Iterations','RuntimeCORAL', ...
            'GlobalModelEvaluations','LocalObjectiveEvaluations', ...
            'LocalConstraintEvaluations','TotalModelEvaluations', ...
            'TotalOracleCalls','LocalNLPCalls','LocalNLPIterations', ...
            'MeanIterationsPerLocalNLP','LocalNLPRuntime', ...
            'TopologyRepairChanges','PolishRuntime','PolishObjectiveCalls', ...
            'PolishExitflag','TopologyCode'});

        if isempty(T)
            T = row;
        else
            T = [T; row]; %#ok<AGROW>
        end

        T = sortrows(T,{'LocalRefineMaxIterations','Seed'});
        writetable(T,rawFile);

        save(matFile,'T','intensityLevels','seedList', ...
            'referenceObjective','referenceTopology','pNLP', ...
            'reefSize','maxIterations','patience','feasTol', ...
            'stagnationRelTol','localMaxFunctionEvaluations', ...
            'localConstraintTolerance','bleachingThreshold', ...
            'bleachingFraction');

        fprintf(['NLPiter=%3d seed=%d | raw=%11.7f | top=%d | feas=%d | ' ...
                 'pol=%11.7f | oracle=%8d | NLP=%5d | ' ...
                 'meanSQPit=%6.2f | time=%7.2fs\n'], ...
            localMaxIterations,seed,rawObjective,topologyMatch,feasibleRaw, ...
            polishedObjective,result.counters.totalOracleCalls, ...
            result.counters.localNLPCalls,meanIterationsPerLocalNLP, ...
            result.runtime);
    end
end

%% Summary statistics
nLevels = numel(intensityLevels);

NLPMaxIterations = intensityLevels(:);
n = zeros(nLevels,1);
FeasibleRate = nan(nLevels,1);
TopologyRecoveryRate = nan(nLevels,1);
PolishedFeasibleRate = nan(nLevels,1);

MedianRawObjective = nan(nLevels,1);
MedianRawAbsGapPercent = nan(nLevels,1);
MedianPolishedObjective = nan(nLevels,1);
MedianPolishedAbsGapPercent = nan(nLevels,1);

MedianOracleCalls = nan(nLevels,1);
IQROracleCalls = nan(nLevels,1);
MedianRuntime = nan(nLevels,1);
IQRRuntime = nan(nLevels,1);

MedianLocalNLPCalls = nan(nLevels,1);
MedianLocalNLPIterations = nan(nLevels,1);
MedianMeanIterationsPerLocalNLP = nan(nLevels,1);
MedianLocalNLPRuntime = nan(nLevels,1);
MedianCORALIterations = nan(nLevels,1);

for ii = 1:nLevels

    idx = T.LocalRefineMaxIterations == intensityLevels(ii);
    S = T(idx,:);
    n(ii) = height(S);

    if n(ii) == 0
        continue;
    end

    FeasibleRate(ii) = mean(S.FeasibleRaw);
    TopologyRecoveryRate(ii) = mean(S.TopologyMatch);
    PolishedFeasibleRate(ii) = mean(S.FeasiblePolished);

    MedianRawObjective(ii) = median(S.RawObjective,'omitnan');
    MedianRawAbsGapPercent(ii) = median(S.RawAbsGapPercent,'omitnan');
    MedianPolishedObjective(ii) = median(S.PolishedObjective,'omitnan');
    MedianPolishedAbsGapPercent(ii) = ...
        median(S.PolishedAbsGapPercent,'omitnan');

    MedianOracleCalls(ii) = median(S.TotalOracleCalls,'omitnan');
    IQROracleCalls(ii) = iqr(S.TotalOracleCalls);
    MedianRuntime(ii) = median(S.RuntimeCORAL,'omitnan');
    IQRRuntime(ii) = iqr(S.RuntimeCORAL);

    MedianLocalNLPCalls(ii) = median(S.LocalNLPCalls,'omitnan');
    MedianLocalNLPIterations(ii) = ...
        median(S.LocalNLPIterations,'omitnan');
    MedianMeanIterationsPerLocalNLP(ii) = ...
        median(S.MeanIterationsPerLocalNLP,'omitnan');
    MedianLocalNLPRuntime(ii) = median(S.LocalNLPRuntime,'omitnan');
    MedianCORALIterations(ii) = median(S.Iterations,'omitnan');
end

summaryTable = table( ...
    NLPMaxIterations,n,FeasibleRate,TopologyRecoveryRate, ...
    PolishedFeasibleRate, ...
    MedianRawObjective,MedianRawAbsGapPercent, ...
    MedianPolishedObjective,MedianPolishedAbsGapPercent, ...
    MedianOracleCalls,IQROracleCalls,MedianRuntime,IQRRuntime, ...
    MedianLocalNLPCalls,MedianLocalNLPIterations, ...
    MedianMeanIterationsPerLocalNLP,MedianLocalNLPRuntime, ...
    MedianCORALIterations);

writetable(summaryTable,summaryFile);

fprintf('\n============================================================\n');
fprintf('LOCAL-NLP INTENSITY SENSITIVITY SUMMARY\n');
fprintf('============================================================\n');
disp(summaryTable);
fprintf('Raw runs saved to    : %s\n',rawFile);
fprintf('Summary saved to     : %s\n',summaryFile);
fprintf('MATLAB data saved to : %s\n',matFile);
fprintf('============================================================\n');

%% Figures
fig1 = figure('Name','CORAL-R1 local NLP intensity - oracle calls');
plot(NLPMaxIterations,MedianOracleCalls,'o-','LineWidth',1.5);
xlabel('Maximum SQP iterations per local refinement');
ylabel('Median total oracle calls');
grid on;
title('CORAL-R1: computational effort vs local-NLP intensity');
exportgraphics(fig1, ...
    'CORAL_R1_localNLP_intensity_oracle_calls.png','Resolution',300);

fig2 = figure('Name','CORAL-R1 local NLP intensity - feasibility');
plot(NLPMaxIterations,100*FeasibleRate,'o-','LineWidth',1.5);
hold on;
plot(NLPMaxIterations,100*TopologyRecoveryRate,'s--','LineWidth',1.5);
xlabel('Maximum SQP iterations per local refinement');
ylabel('Successful runs [%]');
ylim([0 105]);
grid on;
legend('Raw feasible','Reference topology','Location','best');
title('CORAL-R1: reliability vs local-NLP intensity');
exportgraphics(fig2, ...
    'CORAL_R1_localNLP_intensity_feasibility.png','Resolution',300);

fig3 = figure('Name','CORAL-R1 local NLP intensity - actual SQP iterations');
plot(NLPMaxIterations,MedianMeanIterationsPerLocalNLP, ...
    'o-','LineWidth',1.5);
xlabel('Maximum SQP iterations per local refinement');
ylabel('Median mean SQP iterations per local-NLP call');
grid on;
title('CORAL-R1: realized local-refinement intensity');
exportgraphics(fig3, ...
    'CORAL_R1_localNLP_intensity_iterations.png','Resolution',300);

%% Local helper functions
function f = objective_only_local(y,x)
    [f,~,~] = eight_process_model(y,x);
end

function value = local_max_abs(v)
    if isempty(v)
        value = 0;
    else
        value = max(abs(v(:)));
    end
end

function value = local_max_positive(v)
    if isempty(v)
        value = 0;
    else
        value = max([0;v(:)]);
    end
end
