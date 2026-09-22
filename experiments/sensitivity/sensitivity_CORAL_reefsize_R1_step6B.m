%% CORAL-R1 Phase 1 Step 6B - reef-size confirmation
% Targeted confirmation of the reef-size effect identified in Step 6.
% Frozen settings from previous phases are retained except for the parameter
% explicitly varied. This script DOES NOT modify CORALSuperstructureOptimizer_R1.
%
% Only ReefSize is varied: 60, 120, 240.
% Seeds 12006:12010 extend the Step 6 screening to 10 matched seeds
% when combined with the existing Step 6 seeds 12001:12005.
% All other CORAL-R1 settings remain frozen.
% Restart-safe: extension results are written after every completed run.

clear; clc;

referenceObjective = 68.009744051065;
referenceTopology  = [0 1 0 1 0 1 0 1];
[lb,ub] = eight_process_bounds();
xBounds = [lb(:),ub(:)];

% Five matched seeds are deliberately used for screening. We only expand to
% 10 seeds if the screening reveals a material parameter effect.
seeds = 12006:12010;

% Frozen nominal CORAL-R1 settings
nomReef   = 120;
nomBleach = 0.12;
nomMut    = 0.10;
pNLP      = 0.30;
maxIterations = 300;
patience = 80;
feasTol = 1e-5;
stagnationRelTol = 1e-8;

% Three reef-size configurations; no other parameter is changed.
configs = struct( ...
 'label', {'Reef_60','Nominal','Reef_240'}, ...
 'parameter', {'ReefSize','Nominal','ReefSize'}, ...
 'value', {60,NaN,240}, ...
 'reef', {60,nomReef,240}, ...
 'bleach', {nomBleach,nomBleach,nomBleach}, ...
 'mut', {nomMut,nomMut,nomMut});

outRuns = 'CORAL_R1_step6B_reefsize_confirmation_runs.csv';
outSummary = 'CORAL_R1_step6B_reefsize_confirmation_summary.csv';
outMat = 'CORAL_R1_step6B_reefsize_confirmation.mat';

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

fprintf('\nCORAL-R1 Phase 1 Step 6B - reef-size confirmation\n');
fprintf('=========================================================\n');
fprintf('Reef-size settings    : %d\n',numel(configs));
fprintf('New seeds/config      : %d (12006-12010)\n',numel(seeds));
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

% If the original Step 6 screening file is in the same folder, also create a
% combined 10-seed reef-size table for immediate use in Step 7.
combinedRunsFile = 'CORAL_R1_step6_reefsize_10seed_runs.csv';
combinedSummaryFile = 'CORAL_R1_step6_reefsize_10seed_summary.csv';
step6RunsFile = 'CORAL_R1_step6_parameter_sensitivity_runs.csv';
if isfile(step6RunsFile)
    T0 = readtable(step6RunsFile,'TextType','string');
    keep = ismember(T0.Configuration,["Reef_60","Nominal","Reef_240"]) & T0.Seed <= 12005;
    TC = [T0(keep,:); T];
    TC = sortrows(TC,{'Configuration','Seed'});
    writetable(TC,combinedRunsFile);

    SC = S;
    for jc=1:numel(configs)
        Cj=configs(jc);
        A=TC(TC.Configuration==string(Cj.label),:);
        SC.n(jc)=height(A);
        SC.FeasibleRate(jc)=mean(A.Feasible);
        SC.TopologyRecoveryRate(jc)=mean(A.TopologyMatch);
        SC.MedianObjective(jc)=median(A.Objective);
        SC.MedianAbsGapPercent(jc)=median(A.AbsGapPercent);
        SC.MedianOracleCalls(jc)=median(A.OracleCalls);
        SC.IQROracleCalls(jc)=iqr(A.OracleCalls);
        SC.MedianLocalNLPCalls(jc)=median(A.LocalNLPCalls);
        SC.MedianIterations(jc)=median(A.Iterations);
        SC.MedianRuntime(jc)=median(A.Runtime);
        SC.IQRRuntime(jc)=iqr(A.Runtime);
    end
    writetable(SC,combinedSummaryFile);
    fprintf('\nCombined 10-seed reef-size summary (Step 6 + 6B):\n');
    disp(SC);
    fprintf('Combined runs    : %s\n',combinedRunsFile);
    fprintf('Combined summary : %s\n',combinedSummaryFile);
else
    fprintf('\nNOTE: %s not found in current folder.\n',step6RunsFile);
    fprintf('Step 6B results are complete, but no combined 10-seed file was generated.\n');
end

fprintf('\n============================================================\n');
fprintf('STEP 6B REEF-SIZE CONFIRMATION SUMMARY\n');
fprintf('============================================================\n');
disp(S);
fprintf('Runs    : %s\n',outRuns);
fprintf('Summary : %s\n',outSummary);
fprintf('MAT     : %s\n',outMat);
fprintf('============================================================\n');
