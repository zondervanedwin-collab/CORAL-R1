function [lb, ub] = eight_process_bounds()
% Bounds for the 25 continuous variables in the 8-process benchmark.

    lb = zeros(1,25);
    ub = 20*ones(1,25);

    ub(3)  = 2.0;
    ub(5)  = 2.0;
    ub(9)  = 2.0;
    ub(10) = 1.0;
    ub(14) = 1.0;
    ub(17) = 2.0;
    ub(19) = 2.0;
    ub(21) = 2.0;
    ub(25) = 3.0;
end
