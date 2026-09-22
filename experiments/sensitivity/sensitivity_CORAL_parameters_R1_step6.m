%% CORAL-R1 Phase 1 Step 6 - CORAL-specific parameter sensitivity
% One-factor-at-a-time screening on the 8-process benchmark.
% Frozen settings from previous phases are retained except for the parameter
% explicitly varied. This script DOES NOT modify CORALSuperstructureOptimizer_R1.
%
% Parameters:
%   ReefSize             = 60, 120, 240       (nominal 120)
%   BleachingThreshold   = 0.06, 0.12, 0.24   (nominal 0.12)
%   MutationScale        = 0.05, 0.10, 0.20   (nominal 0.10)
%
% The nominal configuration occurs in all three sweeps but is run only once,
% giving 7 unique configurations. Initial screening uses 5 matched seeds.
% Restart-safe: results are written after every completed run.

clear; clc;

referenceObjective = 68.009744051065;
referenceTopology  = [0 1 0 1 0 1 0 1];
[lb,ub] = eight_process_bounds();
xBounds = [lb(:),ub(:)];

% Five matched seeds are deliberately used for screening. We only expand to
% 10 seeds if the screening reveals a material parameter effect.
seeds = 12001:12005;

% Frozen nominal CORAL-R1 settings
nomReef   = 120;
nomBleach = 0.12;
nomMut    = 0.10;
pNLP      = 0.30;
maxIterations = 300;
patience = 80;
feasTol = 1e-5;
stagnationRelTol = 1e-8;

% Seven unique OFAT configurations.
configs = struct( ...
 'label', {'Reef_60','Nominal','Reef_240','Bleach_006','Bleach_024','Mut_005','Mut_020'}, ...
 'parameter', {'ReefSize','Nominal','ReefSize','BleachingThreshold','BleachingThreshold','MutationScale','MutationScale'}, ...
 'value', {60,NaN,240,0.06,0.24,0.05,0.20}, ...
 'reef', {60,nomReef,240,nomReef,nomReef,nomReef,nomReef}, ...
 'bleach', {nomBleach,nomBleach,nomBleach,0.06,0.24,nomBleach,nomBleach}, ...
 'mut', {nomMut,nomMut,nomMut,nomMut,nomMut,0.05,0.20});

outRuns = 'CORAL_R1_step6_parameter_sensitivity_runs.csv';
outSummary = 'CORAL_R1_step6_parameter_sensitivity_summary.csv';
outMat = 'CORAL_R1_step6_parameter_sensitivity.mat';

vars = {'Configuration','Parameter','ParameterValue','Seed','ReefSize', ...
    'BleachingThreshold','MutationScale','Objective','SignedGapPercent', ...
    'AbsGapPercent','Feasible','TopologyMatch','Iterations','OracleCalls', ...
    'LocalNLPCalls','TopologyRepairs','Runtime'};
types = {'string','string','double','double','double','double','double', ...
    'double','double','double','logical','logical','double','double','double','double','double'};

if isfile(outRuns)
    T = readtable(outRuns,'TextType','string');
    fprintf('Resuming from %s (%d completed rows).\n',outRuns,height(T));
else
    T = table('Size',[0 numel(vars)],'VariableTypes',types,'VariableNames',vars);
end

fprintf('\nCORAL-R1 Phase 1 Step 6 - parameter sensitivity screening\n');
fprintf('=========================================================\n');
fprintf('Unique configurations : %d\n',numel(configs));
fprintf('Matched seeds/config  : %d\n',numel(seeds));
fprintf('Total planned runs    : %d\n',numel(configs)*numel(seeds));
fprintf('Frozen p_NLP          : %.2f\n\n',pNLP);

for ic = 1:numel(configs)
    C = configs(ic);
    fprintf('\n------------------------------------------------------------\n%s | Reef=%g Bleach=%g Mutation=%g\n------------------------------------------------------------\n', ...
        C.label,C.reef,C.bleach,C.mut);

    for seed = seeds
        if any(T.Configuration == string(C.label) & T.Seed == seed)
            fprintf('%s seed=%d already complete; skipping.\n',C.label,seed);
            continue;
        end

        opt = CORALSuperstructureOptimizer_R1( ...
            @eight_process_model,8,xBounds, ...
            'ReefSize',C.reef, ...
            'Seed',seed, ...
            'TopologyRepairFcn',@eight_process_topology_repair, ...
            'NonlinearConstraintFcn',@eight_process_constraints, ...
            'LocalRefinement',true, ...
            'LocalRefineProbability',pNLP, ...
            'AdaptiveOperators',true, ...
            'DiversityWeight',0.15, ...
            'BleachingThreshold',C.bleach, ...
            'BleachingFraction',0.20, ...
            'MutationScale',C.mut, ...
            'LocalRefineMaxIterations',300, ...
            'LocalRefineMaxFunctionEvaluations',10000, ...
            'LocalRefineConstraintTolerance',1e-8, ...
            'FeasibilityTolerance',feasTol, ...
            'StagnationRelativeTolerance',stagnationRelTol);

        R = opt.optimize('MaxIterations',maxIterations,'Patience',patience,'Verbose',false);
        b = R.best;
        [c,ceq] = eight_process_constraints(b.y,b.x);
        maxEq = max([0;abs(ceq(:))]);
        maxIneq = max([0;c(:)]);
        feasible = maxEq <= feasTol && maxIneq <= feasTol && eight_process_logic_feasible(b.y);
        topmatch = isequal(b.y,referenceTopology);
        sgap = 100*(b.f-referenceObjective)/abs(referenceObjective);
        agap = abs(sgap);

        if strcmp(C.parameter,'Nominal')
            pval = NaN;
        else
            pval = C.value;
        end
        row = {string(C.label),string(C.parameter),pval,seed,C.reef,C.bleach,C.mut, ...
            b.f,sgap,agap,feasible,topmatch,R.iterations,R.counters.totalOracleCalls, ...
            R.counters.localNLPCalls,R.counters.topologyRepairChanges,R.runtime};
        T = [T; cell2table(row,'VariableNames',vars)]; %#ok<AGROW>
        writetable(T,outRuns);

        fprintf('%-11s seed=%d | obj=%11.7f | top=%d | feas=%d | oracle=%8d | NLP=%5d | it=%3d | %7.1fs\n', ...
            C.label,seed,b.f,topmatch,feasible,R.counters.totalOracleCalls, ...
            R.counters.localNLPCalls,R.iterations,R.runtime);
    end
end

% Summary per unique configuration
S = table('Size',[numel(configs) 14], ...
    'VariableTypes',{'string','string','double','double','double','double','double','double','double','double','double','double','double','double'}, ...
    'VariableNames',{'Configuration','Parameter','ParameterValue','n','FeasibleRate', ...
    'TopologyRecoveryRate','MedianObjective','MedianAbsGapPercent','MedianOracleCalls', ...
    'IQROracleCalls','MedianLocalNLPCalls','MedianIterations','MedianRuntime','IQRRuntime'});

for ic=1:numel(configs)
    C=configs(ic);
    A=T(T.Configuration==string(C.label),:);
    S.Configuration(ic)=string(C.label);
    S.Parameter(ic)=string(C.parameter);
    S.ParameterValue(ic)=C.value;
    S.n(ic)=height(A);
    S.FeasibleRate(ic)=mean(A.Feasible);
    S.TopologyRecoveryRate(ic)=mean(A.TopologyMatch);
    S.MedianObjective(ic)=median(A.Objective);
    S.MedianAbsGapPercent(ic)=median(A.AbsGapPercent);
    S.MedianOracleCalls(ic)=median(A.OracleCalls);
    S.IQROracleCalls(ic)=iqr(A.OracleCalls);
    S.MedianLocalNLPCalls(ic)=median(A.LocalNLPCalls);
    S.MedianIterations(ic)=median(A.Iterations);
    S.MedianRuntime(ic)=median(A.Runtime);
    S.IQRRuntime(ic)=iqr(A.Runtime);
end

writetable(S,outSummary);
save(outMat,'T','S','configs','seeds','referenceObjective','referenceTopology', ...
    'nomReef','nomBleach','nomMut','pNLP','maxIterations','patience','feasTol');

fprintf('\n============================================================\n');
fprintf('STEP 6 PARAMETER SENSITIVITY SCREENING SUMMARY\n');
fprintf('============================================================\n');
disp(S);
fprintf('Runs    : %s\n',outRuns);
fprintf('Summary : %s\n',outSummary);
fprintf('MAT     : %s\n',outMat);
fprintf('============================================================\n');
