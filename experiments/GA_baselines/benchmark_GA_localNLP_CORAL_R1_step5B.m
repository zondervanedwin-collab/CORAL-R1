%% Phase 1 - Step 5B: GA topology search + embedded constrained local NLP
% CORAL-R1 major revision, classic 8-process benchmark.
%
% PURPOSE
% -------
% Provide a genuinely hybrid GA+NLP baseline. Unlike Step 5A, the GA does
% NOT try to satisfy the thin continuous equality-constrained manifold by
% itself. GA searches the discrete topology. Every decoded topology is
% evaluated by the SAME fixed-topology constrained SQP/fmincon used for
% local refinement in CORAL-R1. Thus local NLP is integrated DURING the
% search rather than being reserved for a final polish.
%
% FAIRNESS / INTERPRETATION
% -------------------------
% * Same exact topology repair as CORAL-R1.
% * Same 10 matched seeds (12001:12010).
% * Same maximum useful oracle budget: 1,500,000 objective + nonlinear-
%   constraint calls per run.
% * Local solver calls are fully included in that budget.
% * No change to CORAL-R1, the process model, or process constraints.
% * This is intentionally a topology-search GA+NLP baseline; it is not the
%   direct mixed continuous/discrete GA of Step 5A.
% * Restart safe: completed rows are saved and skipped.
%
% Requires Global Optimization Toolbox (ga) and Optimization Toolbox
% (fmincon).

clear; clc;

if exist('ga','file') ~= 2
    error('Step 5B requires MATLAB Global Optimization Toolbox (ga).');
end
if exist('fmincon','file') ~= 2
    error('Step 5B requires Optimization Toolbox (fmincon).');
end

referenceObjective = 68.009744051065;
referenceTopology  = [0 1 0 1 0 1 0 1];
[lbX,ubX] = eight_process_bounds();
lbX = lbX(:)'; ubX = ubX(:)';

seeds = 12001:12010;
oracleBudget = 1500000;
popSize = 120;
maxGenerations = 300;
feasTol = 1e-5;

% GA searches only the 8 binary structural genes. Exact repair projects any
% chromosome to one of the 12 admissible process structures.
nvars = 8;
IntCon = 1:8;
lbY = zeros(1,8);
ubY = ones(1,8);

outRuns = 'CORAL_R1_step5B_GA_localNLP_runs.csv';
outSummary = 'CORAL_R1_step5B_GA_localNLP_summary.csv';
outMat = 'CORAL_R1_step5B_GA_localNLP.mat';

vars = {'Configuration','Seed','OracleBudget','BudgetOracleCalls','BudgetHit', ...
    'Objective','SignedGapPercent','AbsGapPercent','Feasible','TopologyMatch', ...
    'GAGenerations','GAFunctionCount','LocalNLPCalls','SuccessfulLocalNLPCalls', ...
    'BestTopologyCode','Runtime'};
types = {'string','double','double','double','logical','double','double','double', ...
    'logical','logical','double','double','double','double','double','double'};

if isfile(outRuns)
    T = readtable(outRuns,'TextType','string');
    fprintf('Resuming from %s (%d completed rows).\n',outRuns,height(T));
else
    T = table('Size',[0 numel(vars)],'VariableTypes',types,'VariableNames',vars);
end

fprintf('\nCORAL-R1 Phase 1 Step 5B - GA topology search + local NLP\n');
fprintf('===========================================================\n');
fprintf('Matched seeds          : %d\n',numel(seeds));
fprintf('GA population size     : %d\n',popSize);
fprintf('Maximum generations    : %d\n',maxGenerations);
fprintf('Useful oracle budget   : %d calls/run\n',oracleBudget);
fprintf('Local NLP              : constrained SQP for every topology evaluation\n\n');

for seed = seeds
    already = any(T.Configuration == "GA_localNLP" & T.Seed == seed & ...
                  T.OracleBudget == oracleBudget);
    if already
        fprintf('GA_localNLP seed=%d already complete; skipping.\n',seed);
        continue;
    end

    rng(seed,'twister');
    resetState5B(oracleBudget,lbX,ubX,feasTol);
    tStart = tic;

    % Binary initial population. Repair inside the fitness evaluator ensures
    % the same 12-topology admissible search space used by CORAL-R1.
    init = double(rand(popSize,nvars) > 0.5);

    gaOpts = optimoptions('ga', ...
        'PopulationSize',popSize, ...
        'MaxGenerations',maxGenerations, ...
        'InitialPopulationMatrix',init, ...
        'FunctionTolerance',1e-10, ...
        'MaxStallGenerations',80, ...
        'Display','off', ...
        'UseParallel',false, ...
        'OutputFcn',@gaBudgetStop5B);

    % No GA nonlinear constraints are needed: each fitness value is the
    % result of a constrained fixed-topology NLP.
    [zGA,~,~,gaOutput] = ga(@gaTopologyFitness5B,nvars,[],[],[],[], ...
                             lbY,ubY,[],IntCon,gaOpts);

    yGA = eight_process_topology_repair(double(zGA(:)' >= 0.5));

    % Retrieve the best already-computed NLP result for the selected topology.
    % If the exact topology was not retained in the state for any reason,
    % evaluate it once, subject to the SAME remaining budget.
    [fFinal,xFinal,haveBest] = retrieveTopology5B(yGA);
    if ~haveBest
        [fFinal,xFinal] = solveTopology5B(yGA);
    end

    runtime = toc(tStart);
    [used,budgetHit,nLocal,nSuccess] = stateCounts5B();

    % Diagnostics outside experimental budget.
    [c,ceq] = eight_process_constraints(yGA,xFinal);
    feasible = isfinite(fFinal) && eight_process_logic_feasible(yGA) && ...
               max(abs(ceq)) <= feasTol && max([0;c(:)]) <= feasTol;
    topmatch = isequal(yGA,referenceTopology);
    signedGap = 100*(fFinal-referenceObjective)/abs(referenceObjective);
    absGap = abs(signedGap);
    topoCode = sum(yGA .* 2.^(0:7));

    row = {"GA_localNLP",seed,oracleBudget,used,budgetHit,fFinal,signedGap,absGap, ...
        feasible,topmatch,gaOutput.generations,gaOutput.funccount,nLocal,nSuccess, ...
        topoCode,runtime};
    T = [T; cell2table(row,'VariableNames',vars)]; %#ok<AGROW>
    writetable(T,outRuns);

    fprintf(['GA_localNLP seed=%d | obj=%11.7f | top=%d | feas=%d | ' ...
             'used=%8d/%8d | hit=%d | GAeval=%4d | NLP=%4d | gen=%3d | %7.1fs\n'], ...
        seed,fFinal,topmatch,feasible,used,oracleBudget,budgetHit, ...
        gaOutput.funccount,nLocal,gaOutput.generations,runtime);
end

A = T(T.Configuration=="GA_localNLP" & T.OracleBudget==oracleBudget,:);
S = table("GA_localNLP",height(A),mean(A.BudgetHit),mean(A.Feasible), ...
    mean(A.TopologyMatch),median(A.Objective),median(A.AbsGapPercent), ...
    median(A.BudgetOracleCalls),median(A.GAGenerations), ...
    median(A.LocalNLPCalls),median(A.Runtime), ...
    'VariableNames',{'Configuration','n','BudgetHitRate','FeasibleRate', ...
    'TopologyRecoveryRate','MedianObjective','MedianAbsGapPercent', ...
    'MedianBudgetOracleCalls','MedianGAGenerations','MedianLocalNLPCalls', ...
    'MedianRuntime'});

writetable(S,outSummary);
save(outMat,'T','S','seeds','oracleBudget','popSize','maxGenerations', ...
    'referenceObjective','referenceTopology','feasTol');

fprintf('\n============================================================\n');
fprintf('STEP 5B GA + LOCAL NLP SUMMARY\n');
fprintf('============================================================\n');
disp(S);
fprintf('Runs    : %s\n',outRuns);
fprintf('Summary : %s\n',outSummary);
fprintf('MAT     : %s\n',outMat);
fprintf('============================================================\n');

%% ========================================================================
% Local functions
function f = gaTopologyFitness5B(z)
    y = eight_process_topology_repair(double(z(:)' >= 0.5));
    [f,~] = solveTopology5B(y);
    if ~isfinite(f), f = 1e12; end
end

function [fBest,xBest] = solveTopology5B(y)
    global STEP5B_LIMIT STEP5B_USED STEP5B_LBX STEP5B_UBX STEP5B_FEASTOL
    global STEP5B_NLOCAL STEP5B_NSUCCESS STEP5B_BESTF STEP5B_BESTX

    STEP5B_NLOCAL = STEP5B_NLOCAL + 1;
    code = topologyCode5B(y);

    if STEP5B_USED >= STEP5B_LIMIT
        fBest = 1e12; xBest = (STEP5B_LBX+STEP5B_UBX)/2; return;
    end

    % Deterministic common starting point for a given fixed topology. This
    % prevents stochastic fitness noise inside GA and makes repeated visits
    % to a topology comparable. The local solver itself is not cached: every
    % GA evaluation pays its full NLP cost, as CORAL pays for local refinement.
    x0 = (STEP5B_LBX + STEP5B_UBX)/2;

    opts = optimoptions('fmincon', ...
        'Algorithm','sqp','Display','off', ...
        'MaxIterations',300,'MaxFunctionEvaluations',10000, ...
        'ConstraintTolerance',1e-8,'OptimalityTolerance',1e-10, ...
        'StepTolerance',1e-12);

    try
        [x,f,exitflag] = fmincon(@(x)obj5B(y,x),x0,[],[],[],[], ...
            STEP5B_LBX,STEP5B_UBX,@(x)con5B(y,x),opts);
    catch
        x = x0; f = 1e12; exitflag = -999;
    end

    % Check the returned point without charging extra budget (diagnostic).
    [c,ceq] = eight_process_constraints(y,x);
    good = isfinite(f) && max(abs(ceq)) <= STEP5B_FEASTOL && ...
           max([0;c(:)]) <= STEP5B_FEASTOL && eight_process_logic_feasible(y);
    if good
        STEP5B_NSUCCESS = STEP5B_NSUCCESS + 1;
        fBest = f; xBest = x;
        if f < STEP5B_BESTF(code+1)
            STEP5B_BESTF(code+1) = f;
            STEP5B_BESTX{code+1} = x;
        end
    else
        % Feasibility-first penalty for GA. Do not allow an infeasible low
        % objective to dominate a feasible topology.
        violation = max([max(abs(ceq)); max([0;c(:)])]);
        fBest = 1e8 + 1e6*violation + max(0,f);
        xBest = x;
    end

    if exitflag == -999 && STEP5B_USED >= STEP5B_LIMIT
        fBest = 1e12;
    end
end

function f = obj5B(y,x)
    if consume5B()
        [f,~,~] = eight_process_model(y,x);
    else
        f = 1e12;
    end
end

function [c,ceq] = con5B(y,x)
    if consume5B()
        [c,ceq] = eight_process_constraints(y,x);
    else
        [c0,ceq0] = eight_process_constraints(y,x);
        c = 1e6*ones(size(c0));
        ceq = 1e6*ones(size(ceq0));
    end
end

function [f,x,ok] = retrieveTopology5B(y)
    global STEP5B_BESTF STEP5B_BESTX STEP5B_LBX STEP5B_UBX
    code = topologyCode5B(y);
    f = STEP5B_BESTF(code+1);
    ok = isfinite(f);
    if ok
        x = STEP5B_BESTX{code+1};
    else
        x = (STEP5B_LBX+STEP5B_UBX)/2;
    end
end

function code = topologyCode5B(y)
    y = double(y(:)' > 0.5);
    code = sum(y .* 2.^(0:7));
end

function resetState5B(limit,lbX,ubX,feasTol)
    global STEP5B_LIMIT STEP5B_USED STEP5B_HIT STEP5B_LBX STEP5B_UBX
    global STEP5B_FEASTOL STEP5B_NLOCAL STEP5B_NSUCCESS STEP5B_BESTF STEP5B_BESTX
    STEP5B_LIMIT = limit; STEP5B_USED = 0; STEP5B_HIT = false;
    STEP5B_LBX = lbX; STEP5B_UBX = ubX; STEP5B_FEASTOL = feasTol;
    STEP5B_NLOCAL = 0; STEP5B_NSUCCESS = 0;
    STEP5B_BESTF = inf(256,1); STEP5B_BESTX = cell(256,1);
end

function ok = consume5B()
    global STEP5B_LIMIT STEP5B_USED STEP5B_HIT
    if STEP5B_USED < STEP5B_LIMIT
        STEP5B_USED = STEP5B_USED + 1; ok = true;
    else
        STEP5B_HIT = true; ok = false;
    end
end

function [used,hit,nLocal,nSuccess] = stateCounts5B()
    global STEP5B_USED STEP5B_HIT STEP5B_NLOCAL STEP5B_NSUCCESS
    used=STEP5B_USED; hit=STEP5B_HIT; nLocal=STEP5B_NLOCAL; nSuccess=STEP5B_NSUCCESS;
end

function [state,options,optchanged] = gaBudgetStop5B(options,state,flag) %#ok<INUSD>
    optchanged = false;
    global STEP5B_LIMIT STEP5B_USED STEP5B_HIT
    if STEP5B_USED >= STEP5B_LIMIT
        state.StopFlag = 'Oracle budget reached';
        STEP5B_HIT = true;
    end
end
