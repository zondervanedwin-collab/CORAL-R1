function tf = eight_process_logic_feasible(y)
% Logical feasibility for the classic 8-process synthesis benchmark.

    y = logical(y(:)');

    if numel(y) ~= 8
        error('Topology vector y must contain 8 binary variables.');
    end

    tf = xor(y(1),y(2)) && xor(y(4),y(5)) && xor(y(6),y(7));
    if ~tf, return; end

    tf = tf && (~y(1) || (y(3) || y(4) || y(5)));
    tf = tf && (~y(2) || (y(3) || y(4) || y(5)));
    tf = tf && (~y(3) || y(8));
    tf = tf && (~y(3) || (y(1) || y(2)));
    tf = tf && (~y(4) || (y(1) || y(2)));
    tf = tf && (~y(4) || (y(6) || y(7)));
    tf = tf && (~y(5) || (y(1) || y(2)));
    tf = tf && (~y(5) || y(8));
    tf = tf && (~y(6) || y(4));
    tf = tf && (~y(7) || y(4));
end
