%% Phase 1 - Step 5A: conventional GA baseline + fixed-topology NLP polish
% CORAL-R1 major revision, 8-process benchmark.
%
% Purpose
% -------
% Add one recognizable population-based baseline requested by Reviewer 2.
% A conventional MATLAB genetic algorithm searches a decoded mixed
% chromosome [8 topology genes, 25 continuous variables]. The first eight
% genes are thresholded at 0.5 and projected with the SAME exact topology
% repair used by CORAL-R1. The process equalities/inequalities are supplied
% explicitly to GA. After GA terminates, the topology selected by GA is
% polished once with constrained fmincon, using the remaining oracle budget.
%
% IMPORTANT
% ---------
% * CORAL-R1 core/model/constraints are NOT modified.
% * Same 10 seeds as Steps 3/4.
% * Same maximum useful-oracle budget: 1,500,000 calls/run.
% * Objective + nonlinear-constraint evaluations both count as oracle calls.
% * The final fixed-topology fmincon polish is INCLUDED in that budget.
% * This is a conventional GA baseline, not a claim that GA is optimally tuned.
% * Restart safe: completed rows are saved and skipped.
%
% Requires MATLAB Global Optimization Toolbox ('ga') and Optimization
% Toolbox ('fmincon').

clear; clc;

if exist('ga','file') ~= 2
    error(['MATLAB function ga was not found. Step 5A requires the Global ' ...
           'Optimization Toolbox.']);
end
if exist('fmincon','file') ~= 2
    error('MATLAB function fmincon was not found.');
end

referenceObjective = 68.009744051065;
referenceTopology  = [0 1 0 1 0 1 0 1];
[lbX,ubX] = eight_process_bounds();

seeds = 12001:12010;
oracleBudget = 1500000;
popSize = 120;                 % same population scale as CORAL reef size
maxGenerations = 300;
feasTol = 1e-5;

% Chromosome z = [8 topology genes, 25 continuous variables].
% Topology genes are continuous in GA but decoded by threshold + exact repair.
nvars = 33;
lb = [zeros(1,8), lbX(:)'];
ub = [ones(1,8),  ubX(:)'];

outRuns = 'CORAL_R1_step5A_GA_NLP_runs.csv';
outSummary = 'CORAL_R1_step5A_GA_NLP_summary.csv';
outMat = 'CORAL_R1_step5A_GA_NLP.mat';

vars = {'Configuration','Seed','OracleBudget','BudgetOracleCalls','BudgetHit', ...
    'GAObjective','PolishedObjective','SignedGapPercent','AbsGapPercent', ...
    'Feasible','TopologyMatch','GAGenerations','GAFunctionCount', ...
    'PolishPerformed','PolishExitflag','Runtime'};
types = {'string','double','double','double','logical', ...
    'double','double','double','double','logical','logical','double','double', ...
    'logical','double','double'};

if isfile(outRuns)
    T = readtable(outRuns,'TextType','string');
    fprintf('Resuming from %s (%d completed rows).\n',outRuns,height(T));
else
    T = table('Size',[0 numel(vars)],'VariableTypes',types,'VariableNames',vars);
end

fprintf('\nCORAL-R1 Phase 1 Step 5A - GA + NLP baseline\n');
fprintf('================================================\n');
fprintf('Matched seeds          : %d\n',numel(seeds));
fprintf('Population size        : %d\n',popSize);
fprintf('Maximum generations    : %d\n',maxGenerations);
fprintf('Useful oracle budget   : %d calls/run\n\n',oracleBudget);

for seed = seeds
    already = any(T.Configuration == "GA_NLP" & T.Seed == seed & ...
                  T.OracleBudget == oracleBudget);
    if already
        fprintf('GA_NLP seed=%d already complete; skipping.\n',seed);
        continue;
    end

    rng(seed,'twister');
    resetBudget5A(oracleBudget);
    tStart = tic;

    % Random but reproducible initial population. Topology genes are binary
    % initially; continuous genes span their physical bounds.
    init = zeros(popSize,nvars);
    init(:,1:8) = double(rand(popSize,8) > 0.5);
    init(:,9:end) = lbX + rand(popSize,25).*(ubX-lbX);

    gaOpts = optimoptions('ga', ...
        'PopulationSize',popSize, ...
        'MaxGenerations',maxGenerations, ...
        'InitialPopulationMatrix',init, ...
        'ConstraintTolerance',feasTol, ...
        'FunctionTolerance',1e-10, ...
        'MaxStallGenerations',80, ...
        'Display','off', ...
        'UseParallel',false, ...
        'OutputFcn',@gaBudgetStop5A);

    [zGA,fGA,~,gaOutput] = ga(@gaObjective5A,nvars,[],[],[],[],lb,ub, ...
                              @gaConstraints5A,gaOpts);

    [yGA,xGA] = decode5A(zGA);

    % One deterministic fixed-topology constrained NLP polish, using the
    % REMAINING budget. This makes the comparison focus on whether GA found
    % a useful topology rather than on residual continuous-variable error.
    polishPerformed = false;
    polishExitflag = NaN;
    xFinal = xGA;
    fFinal = fGA;

    [usedBeforePolish,~] = budgetState5A();
    if usedBeforePolish < oracleBudget
        polishPerformed = true;
        fopts = optimoptions('fmincon', ...
            'Algorithm','sqp', ...
            'Display','off', ...
            'MaxIterations',300, ...
            'MaxFunctionEvaluations',10000, ...
            'ConstraintTolerance',1e-8, ...
            'OptimalityTolerance',1e-10, ...
            'StepTolerance',1e-12);
        try
            [xP,fP,polishExitflag] = fmincon( ...
                @(x) fixedObjective5A(yGA,x),xGA,[],[],[],[],lbX,ubX, ...
                @(x) fixedConstraints5A(yGA,x),fopts);
            if isfinite(fP)
                xFinal = xP;
                fFinal = fP;
            end
        catch ME
            warning('Step5A:PolishFailed','Polish failed for seed %d: %s',seed,ME.message);
        end
    end

    runtime = toc(tStart);
    [used,budgetHit] = budgetState5A();

    % Diagnostic checks OUTSIDE the experimental budget.
    [c,ceq] = eight_process_constraints(yGA,xFinal);
    feasible = eight_process_logic_feasible(yGA) && ...
               max(abs(ceq)) <= feasTol && max([0;c]) <= feasTol;
    topmatch = isequal(yGA,referenceTopology);
    signedGap = 100*(fFinal-referenceObjective)/abs(referenceObjective);
    absGap = abs(signedGap);

    row = {"GA_NLP",seed,oracleBudget,used,budgetHit,fGA,fFinal, ...
        signedGap,absGap,feasible,topmatch,gaOutput.generations, ...
        gaOutput.funccount,polishPerformed,polishExitflag,runtime};
    T = [T; cell2table(row,'VariableNames',vars)]; %#ok<AGROW>
    writetable(T,outRuns);

    fprintf(['GA_NLP seed=%d | GA=%11.6f | final=%11.7f | top=%d | feas=%d | ' ...
             'used=%8d/%8d | gen=%3d | polish=%d | %7.1fs\n'], ...
        seed,fGA,fFinal,topmatch,feasible,used,oracleBudget, ...
        gaOutput.generations,polishPerformed,runtime);
end

A = T(T.Configuration=="GA_NLP" & T.OracleBudget==oracleBudget,:);
S = table("GA_NLP",height(A),mean(A.BudgetHit),mean(A.Feasible), ...
    mean(A.TopologyMatch),median(A.PolishedObjective),median(A.AbsGapPercent), ...
    median(A.BudgetOracleCalls),median(A.GAGenerations),median(A.Runtime), ...
    'VariableNames',{'Configuration','n','BudgetHitRate','FeasibleRate', ...
    'TopologyRecoveryRate','MedianPolishedObjective','MedianAbsGapPercent', ...
    'MedianBudgetOracleCalls','MedianGAGenerations','MedianRuntime'});

writetable(S,outSummary);
save(outMat,'T','S','seeds','oracleBudget','popSize','maxGenerations', ...
    'referenceObjective','referenceTopology','feasTol');

fprintf('\n============================================================\n');
fprintf('STEP 5A GA + NLP SUMMARY\n');
fprintf('============================================================\n');
disp(S);
fprintf('Runs    : %s\n',outRuns);
fprintf('Summary : %s\n',outSummary);
fprintf('MAT     : %s\n',outMat);
fprintf('============================================================\n');

%% ------------------------------------------------------------------------
% Local functions
function [y,x] = decode5A(z)
    y0 = double(z(1:8) >= 0.5);
    y = eight_process_topology_repair(y0);
    x = z(9:end);
end

function f = gaObjective5A(z)
    [y,x] = decode5A(z);
    if consume5A()
        [f,~,~] = eight_process_model(y,x);
    else
        f = 1e12;
    end
end

function [c,ceq] = gaConstraints5A(z)
    [y,x] = decode5A(z);
    if consume5A()
        [c,ceq0] = eight_process_constraints(y,x);
        ceq = padEqualityConstraints5A(ceq0);
    else
        % GA requires a fixed number of nonlinear constraints for every
        % chromosome. The 8-process model has topology-dependent equality
        % counts, so always return the fixed padded size here.
        c = 1e6*ones(4,1);
        ceq = 1e6*ones(26,1);
    end
end

function f = fixedObjective5A(y,x)
    if consume5A()
        [f,~,~] = eight_process_model(y,x);
    else
        f = 1e12;
    end
end

function [c,ceq] = fixedConstraints5A(y,x)
    if consume5A()
        [c,ceq] = eight_process_constraints(y,x);
    else
        % Here y is fixed during a single fmincon call, so the native
        % topology-dependent constraint dimension is valid.
        [c0,ceq0] = eight_process_constraints(y,x);
        c = 1e6*ones(size(c0));
        ceq = 1e6*ones(size(ceq0));
    end
end

function ceq = padEqualityConstraints5A(ceq0)
    % GA's augmented-Lagrangian implementation requires the nonlinear
    % constraint vector to have identical dimensions for every population
    % member. eight_process_constraints legitimately returns a different
    % number of equalities for different topologies (inactive units add
    % zero-flow equalities). Pad with exact zeros to the maximum possible
    % count. Zero padding does not alter the feasible set.
    nEqMax = 26;
    ceq0 = ceq0(:);
    if numel(ceq0) > nEqMax
        error('Step5A:ConstraintDimension', ...
              'Unexpected equality-constraint count %d > %d.',numel(ceq0),nEqMax);
    end
    ceq = [ceq0; zeros(nEqMax-numel(ceq0),1)];
end

function resetBudget5A(limit)
    global STEP5A_LIMIT STEP5A_USED STEP5A_HIT
    STEP5A_LIMIT = limit;
    STEP5A_USED = 0;
    STEP5A_HIT = false;
end

function ok = consume5A()
    global STEP5A_LIMIT STEP5A_USED STEP5A_HIT
    if STEP5A_USED < STEP5A_LIMIT
        STEP5A_USED = STEP5A_USED + 1;
        ok = true;
    else
        STEP5A_HIT = true;
        ok = false;
    end
end

function [used,hit] = budgetState5A()
    global STEP5A_USED STEP5A_HIT
    used = STEP5A_USED;
    hit = STEP5A_HIT;
end

function [state,options,optchanged] = gaBudgetStop5A(options,state,flag)
    optchanged = false;
    [used,~] = budgetState5A();
    global STEP5A_LIMIT STEP5A_HIT
    if used >= STEP5A_LIMIT
        state.StopFlag = 'Oracle budget reached';
        STEP5A_HIT = true;
    end
end
