function [c, ceq, details] = eight_process_constraints(y,x)
% Explicit constraints for a fixed 8-process topology.
% MATLAB convention: c <= 0, ceq = 0.

    y = double(y(:)' > 0.5);
    x = x(:)';

    ceq = [
        x(13)-x(19)-x(21)
        x(17)-x(9)-x(16)-x(25)
        x(11)-x(12)-x(15)
        x(3)+x(5)-x(6)-x(11)
        x(6)-x(7)-x(8)
        x(23)-x(20)-x(22)
        x(23)-x(14)-x(24)
        x(1)-x(2)-x(4)
    ];

    c = [
        x(10)-0.8*x(17)
        0.4*x(17)-x(10)
        x(12)-5.0*x(14)
        2.0*x(14)-x(12)
    ];

    if y(1)
        ceq(end+1,1)=exp(x(3))-1-x(2);
    else
        ceq(end+1:end+2,1)=[x(2);x(3)];
    end

    if y(2)
        ceq(end+1,1)=exp(x(5)/1.2)-1-x(4);
    else
        ceq(end+1:end+2,1)=[x(4);x(5)];
    end

    if y(3)
        ceq(end+1,1)=1.5*x(9)+x(10)-x(8);
    else
        ceq(end+1,1)=x(9);
    end

    if y(4)
        ceq(end+1,1)=1.25*(x(12)+x(14))-x(13);
    else
        ceq(end+1:end+3,1)=[x(12);x(13);x(14)];
    end

    if y(5)
        ceq(end+1,1)=x(15)-2*x(16);
    else
        ceq(end+1:end+2,1)=[x(15);x(16)];
    end

    if y(6)
        ceq(end+1,1)=exp(x(20)/1.5)-1-x(19);
    else
        ceq(end+1:end+2,1)=[x(19);x(20)];
    end

    if y(7)
        ceq(end+1,1)=exp(x(22))-1-x(21);
    else
        ceq(end+1:end+2,1)=[x(21);x(22)];
    end

    if y(8)
        ceq(end+1,1)=exp(x(18))-1-x(10)-x(17);
    else
        ceq(end+1:end+4,1)=[x(10);x(17);x(18);x(25)];
    end

    details.maxInequalityViolation=max([0;c]);
    details.maxEqualityResidual=max(abs(ceq));
end
