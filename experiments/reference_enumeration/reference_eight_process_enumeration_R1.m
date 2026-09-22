function reference=reference_eight_process_enumeration_R1(varargin)
% Deterministic reference for the classic 8-process synthesis benchmark.
% Enumerates all logically feasible topologies and applies multistart SQP.
% CORAL-R1 revision version also reports objective/constraint call counts
% and wall-clock runtime for reviewer budget comparisons.

    p=inputParser;
    addParameter(p,'MultiStartN',20);
    addParameter(p,'Seed',321);
    addParameter(p,'Display',true);
    addParameter(p,'FeasibilityTolerance',1e-5);
    parse(p,varargin{:});

    rng(p.Results.Seed,'twister');
    nStarts=p.Results.MultiStartN;
    tol=p.Results.FeasibilityTolerance;

    if exist('fmincon','file')~=2
        error('Optimization Toolbox / fmincon is required.');
    end

    [lb,ub]=eight_process_bounds;

    feasibleY=zeros(0,8);
    for n=0:255
        y=bitget(uint16(n),1:8);
        if eight_process_logic_feasible(y)
            feasibleY(end+1,:)=y; %#ok<AGROW>
        end
    end

    opts=optimoptions('fmincon','Display','off','Algorithm','sqp', ...
        'MaxIterations',1000,'MaxFunctionEvaluations',20000, ...
        'OptimalityTolerance',1e-10,'ConstraintTolerance',1e-9, ...
        'StepTolerance',1e-12);

    results=repmat(struct('y',[],'x',[],'f',inf,'feasible',false, ...
        'maxEq',inf,'maxIneq',inf,'objectiveCalls',0,'constraintCalls',0, ...
        'runtime',0,'successfulStarts',0),size(feasibleY,1),1);

    totalObjectiveCalls=0;
    totalConstraintCalls=0;
    totalSuccessfulStarts=0;
    tAll=tic;

    for k=1:size(feasibleY,1)
        y=feasibleY(k,:);
        bestF=inf; bestX=[]; bestEq=inf; bestIneq=inf;
        objCallsThis=0; conCallsThis=0; successfulStarts=0;

        starts=zeros(nStarts,25);
        starts(1,:)=0.05*(ub-lb);
        for s=2:nStarts
            starts(s,:)=lb+rand(1,25).*(ub-lb);
        end

        tTopology=tic;
        for s=1:nStarts
            try
                [xopt,fopt]=fmincon(@objwrap,starts(s,:), ...
                    [],[],[],[],lb,ub,@conwrap,opts);

                [c,ceq]=eight_process_constraints(y,xopt);
                conCallsThis=conCallsThis+1;
                eq=max(abs(ceq));
                iq=max([0;c]);

                if eq<=tol && iq<=tol
                    successfulStarts=successfulStarts+1;
                    if fopt<bestF
                        bestF=fopt; bestX=xopt; bestEq=eq; bestIneq=iq;
                    end
                end
            catch
                % Failed starts are retained implicitly in call counts.
            end
        end

        results(k).y=y;
        results(k).x=bestX;
        results(k).f=bestF;
        results(k).feasible=~isempty(bestX);
        results(k).maxEq=bestEq;
        results(k).maxIneq=bestIneq;
        results(k).objectiveCalls=objCallsThis;
        results(k).constraintCalls=conCallsThis;
        results(k).runtime=toc(tTopology);
        results(k).successfulStarts=successfulStarts;

        totalObjectiveCalls=totalObjectiveCalls+objCallsThis;
        totalConstraintCalls=totalConstraintCalls+conCallsThis;
        totalSuccessfulStarts=totalSuccessfulStarts+successfulStarts;

        if p.Results.Display
            fprintf(['Topology %2d/%2d: f=%12.6f, feasible=%d, starts=%2d/%2d, ' ...
                     'obj=%7d, con=%7d, time=%7.2fs, y=['], ...
                k,size(feasibleY,1),bestF,results(k).feasible, ...
                successfulStarts,nStarts,objCallsThis,conCallsThis,results(k).runtime);
            fprintf('%d',y);
            fprintf(']\n');
        end
    end

    totalRuntime=toc(tAll);
    mask=[results.feasible];
    vals=[results.f];
    vals(~mask)=inf;
    [~,idx]=min(vals);

    reference.best=results(idx);
    reference.all=results;
    reference.feasibleTopologies=feasibleY;
    reference.nFeasibleTopologies=size(feasibleY,1);
    reference.multiStartN=nStarts;
    reference.totalStarts=nStarts*size(feasibleY,1);
    reference.successfulStarts=totalSuccessfulStarts;
    reference.objectiveCalls=totalObjectiveCalls;
    reference.constraintCalls=totalConstraintCalls;
    reference.totalOracleCalls=totalObjectiveCalls+totalConstraintCalls;
    reference.runtime=totalRuntime;
    reference.seed=p.Results.Seed;
    reference.feasibilityTolerance=tol;

    if p.Results.Display
        fprintf('\nBest MATLAB reference objective: %.12f\n',reference.best.f);
        fprintf('Selected processes: ');
        fprintf('%d ',find(reference.best.y));
        fprintf('\nFeasible topologies: %d\n',reference.nFeasibleTopologies);
        fprintf('Total SQP starts: %d\n',reference.totalStarts);
        fprintf('Objective calls: %d\n',reference.objectiveCalls);
        fprintf('Constraint calls: %d\n',reference.constraintCalls);
        fprintf('Total oracle calls: %d\n',reference.totalOracleCalls);
        fprintf('Runtime: %.3f s\n',reference.runtime);
        fprintf('Literature: Z* ~= 68.01, processes 2 4 6 8\n');
    end

    function f=objwrap(x)
        objCallsThis=objCallsThis+1;
        [f,~,~]=eight_process_model(y,x);
    end

    function [c,ceq]=conwrap(x)
        conCallsThis=conCallsThis+1;
        [c,ceq]=eight_process_constraints(y,x);
    end
end
