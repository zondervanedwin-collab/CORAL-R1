%% Phase 1 - Step 4B: equal-oracle-budget comparison for CORAL-R1
% Reviewer-facing comparison of the two relevant hybrid methods:
%   1) CRO-like + constrained NLP
%   2) Full topology-aware CORAL + constrained NLP
%
% Both methods receive EXACTLY the same useful oracle-call budget.
% The frozen CORAL-R1 class is NOT modified. Budget enforcement is done by
% wrapper functions below. Once the budget is exhausted, wrappers return
% deliberately noncompetitive values; therefore the incumbent best solution
% at the budget boundary is preserved while CORAL exits by stagnation.
%
% IMPORTANT: the reported BudgetOracleCalls is the external budget counter,
% not result.counters.totalOracleCalls (which includes post-budget dummy calls).
% Final feasibility checking is diagnostic and is performed outside the budget.
%
% Restart safe: completed rows are saved and skipped on rerun.

clear; clc;

referenceObjective = 68.009744051065;
referenceTopology  = [0 1 0 1 0 1 0 1];
[lb,ub] = eight_process_bounds();
xBounds = [lb(:),ub(:)];

seeds = 12001:12010;
oracleBudget = 1500000;       % identical for both methods
reefSize = 120;
maxIterations = 300;
patience = 80;
pNLP = 0.30;                  % frozen from Step 3
feasTol = 1e-5;
stagnationRelTol = 1e-8;

TA_bleachThreshold = 0.12;
TA_bleachFraction  = 0.20;
TA_diversityWeight = 0.15;

configs = struct( ...
    'name', {'CRO_like_NLP','CORAL_full'}, ...
    'adaptive', {false,true}, ...
    'divWeight', {0,TA_diversityWeight}, ...
    'bleachThreshold', {0,TA_bleachThreshold}, ...
    'bleachFraction', {TA_bleachFraction,TA_bleachFraction});

outRuns = 'CORAL_R1_step4B_equal_oracle_runs.csv';
outSummary = 'CORAL_R1_step4B_equal_oracle_summary.csv';
outMat = 'CORAL_R1_step4B_equal_oracle.mat';

vars = {'Configuration','Seed','OracleBudget','BudgetOracleCalls','BudgetHit', ...
    'RawObjective','SignedGapPercent','AbsGapPercent','Feasible','TopologyMatch', ...
    'Iterations','InternalOracleCalls','LocalNLPCalls','TopologyRepairs','Runtime'};
types = {'string','double','double','double','logical', ...
    'double','double','double','logical','logical', ...
    'double','double','double','double','double'};

if isfile(outRuns)
    T = readtable(outRuns,'TextType','string');
    fprintf('Resuming from %s (%d completed rows).\n',outRuns,height(T));
else
    T = table('Size',[0 numel(vars)],'VariableTypes',types,'VariableNames',vars);
end

fprintf('\nCORAL-R1 Phase 1 Step 4B - equal-oracle-budget comparison\n');
fprintf('==========================================================\n');
fprintf('Matched seeds/configuration : %d\n',numel(seeds));
fprintf('Useful oracle budget/run    : %,d\n',oracleBudget);
fprintf('p_NLP                       : %.2f\n\n',pNLP);

for ic = 1:numel(configs)
    C = configs(ic);
    fprintf('\n------------------------------------------------------------\n%s\n------------------------------------------------------------\n',C.name);

    for seed = seeds
        already = any(T.Configuration == string(C.name) & T.Seed == seed & ...
                      T.OracleBudget == oracleBudget);
        if already
            fprintf('%s seed=%d already complete; skipping.\n',C.name,seed);
            continue;
        end

        resetOracleBudget(oracleBudget);

        opt = CORALSuperstructureOptimizer_R1( ...
            @budgeted_eight_process_model,8,xBounds, ...
            'ReefSize',reefSize, ...
            'Seed',seed, ...
            'TopologyRepairFcn',@eight_process_topology_repair, ...
            'NonlinearConstraintFcn',@budgeted_eight_process_constraints, ...
            'LocalRefinement',true, ...
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
        [used,budgetHit] = getOracleBudgetState();

        % Diagnostic feasibility check outside the experimental budget.
        [c,ceq] = eight_process_constraints(b.y,b.x);
        maxEq = max(abs(ceq));
        maxIneq = max([0;c]);
        feasible = maxEq <= feasTol && maxIneq <= feasTol && eight_process_logic_feasible(b.y);
        topmatch = isequal(b.y,referenceTopology);
        signedGap = 100*(b.f-referenceObjective)/abs(referenceObjective);
        absGap = abs(signedGap);

        row = {string(C.name),seed,oracleBudget,used,budgetHit, ...
            b.f,signedGap,absGap,feasible,topmatch,R.iterations, ...
            R.counters.totalOracleCalls,R.counters.localNLPCalls, ...
            R.counters.topologyRepairChanges,R.runtime};
        T = [T; cell2table(row,'VariableNames',vars)]; %#ok<AGROW>
        writetable(T,outRuns);

        fprintf('%-13s seed=%d | obj=%11.7f | top=%d | feas=%d | used=%8d/%8d | hit=%d | NLP=%5d | %7.1fs\n', ...
            C.name,seed,b.f,topmatch,feasible,used,oracleBudget,budgetHit, ...
            R.counters.localNLPCalls,R.runtime);
    end
end

% Summary
S = table('Size',[numel(configs) 10], ...
    'VariableTypes',{'string','double','double','double','double','double','double','double','double','double'}, ...
    'VariableNames',{'Configuration','n','BudgetHitRate','FeasibleRate', ...
    'TopologyRecoveryRate','MedianRawObjective','MedianAbsGapPercent', ...
    'MedianBudgetOracleCalls','MedianRuntime','MedianLocalNLPCalls'});

for ic=1:numel(configs)
    idx = T.Configuration == string(configs(ic).name) & T.OracleBudget == oracleBudget;
    A = T(idx,:);
    S.Configuration(ic)=string(configs(ic).name);
    S.n(ic)=height(A);
    S.BudgetHitRate(ic)=mean(A.BudgetHit);
    S.FeasibleRate(ic)=mean(A.Feasible);
    S.TopologyRecoveryRate(ic)=mean(A.TopologyMatch);
    S.MedianRawObjective(ic)=median(A.RawObjective);
    S.MedianAbsGapPercent(ic)=median(A.AbsGapPercent);
    S.MedianBudgetOracleCalls(ic)=median(A.BudgetOracleCalls);
    S.MedianRuntime(ic)=median(A.Runtime);
    S.MedianLocalNLPCalls(ic)=median(A.LocalNLPCalls);
end

writetable(S,outSummary);
save(outMat,'T','S','configs','seeds','referenceObjective','referenceTopology', ...
    'oracleBudget','reefSize','maxIterations','patience','pNLP','feasTol');

fprintf('\n============================================================\n');
fprintf('STEP 4B EQUAL-ORACLE-BUDGET SUMMARY\n');
fprintf('============================================================\n');
disp(S);
fprintf('Runs    : %s\n',outRuns);
fprintf('Summary : %s\n',outSummary);
fprintf('MAT     : %s\n',outMat);
fprintf('NOTE: use BudgetOracleCalls, not InternalOracleCalls, for the fair-budget comparison.\n');
fprintf('============================================================\n');

%% ---- Budget wrappers ---------------------------------------------------
function resetOracleBudget(limit)
    global CORAL_R1_BUDGET_LIMIT CORAL_R1_BUDGET_USED CORAL_R1_BUDGET_HIT
    CORAL_R1_BUDGET_LIMIT = limit;
    CORAL_R1_BUDGET_USED = 0;
    CORAL_R1_BUDGET_HIT = false;
end

function [used,hit] = getOracleBudgetState()
    global CORAL_R1_BUDGET_USED CORAL_R1_BUDGET_HIT
    used = CORAL_R1_BUDGET_USED;
    hit = CORAL_R1_BUDGET_HIT;
end

function [f,v,info] = budgeted_eight_process_model(y,x)
    global CORAL_R1_BUDGET_LIMIT CORAL_R1_BUDGET_USED CORAL_R1_BUDGET_HIT
    if CORAL_R1_BUDGET_USED < CORAL_R1_BUDGET_LIMIT
        CORAL_R1_BUDGET_USED = CORAL_R1_BUDGET_USED + 1;
        [f,v,info] = eight_process_model(y,x);
    else
        CORAL_R1_BUDGET_HIT = true;
        f = 1e12;
        v = 1e12;
        info = struct('budgetExceeded',true);
    end
end

function [c,ceq] = budgeted_eight_process_constraints(y,x)
    global CORAL_R1_BUDGET_LIMIT CORAL_R1_BUDGET_USED CORAL_R1_BUDGET_HIT
    if CORAL_R1_BUDGET_USED < CORAL_R1_BUDGET_LIMIT
        CORAL_R1_BUDGET_USED = CORAL_R1_BUDGET_USED + 1;
        [c,ceq] = eight_process_constraints(y,x);
    else
        CORAL_R1_BUDGET_HIT = true;
        % Deliberately infeasible dummy values. Constraint dimension is
        % evaluated consistently for the fixed topology of each NLP call.
        [c0,ceq0] = eight_process_constraints(y,x);
        c = ones(size(c0))*1e6;
        ceq = ones(size(ceq0))*1e6;
    end
end
