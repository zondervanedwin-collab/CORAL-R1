function [obj, violation, info] = eight_process_model(y,x)
% Objective and feasibility evaluator for the classic 8-process benchmark.
%
% Literature reference:
% global optimum Z* ~= 68.01
% selected processes = 2, 4, 6, 8

    y=double(y(:)'>0.5);
    x=x(:)';

    fixedCost=[5 8 6 10 6 7 4 5];

    cv=zeros(1,25);
    cv(3)=-10; cv(5)=-15; cv(9)=-40; cv(19)=25;
    cv(21)=35; cv(25)=-35; cv(17)=80; cv(14)=15;
    cv(10)=15; cv(2)=1; cv(4)=1; cv(18)=-65;
    cv(20)=-60; cv(22)=-80;

    obj=122 + fixedCost*y' + cv*x';

    [c,ceq,details]=eight_process_constraints(y,x);

    logicPenalty=double(~eight_process_logic_feasible(y));
    violation=logicPenalty + sum(abs(ceq))/10 + sum(max(0,c))/10;

    info.selectedProcesses=find(y);
    info.logicFeasible=eight_process_logic_feasible(y);
    info.maxEqualityResidual=details.maxEqualityResidual;
    info.maxInequalityViolation=details.maxInequalityViolation;
    info.fixedCost=fixedCost*y';
    info.variableContribution=cv*x';
end
