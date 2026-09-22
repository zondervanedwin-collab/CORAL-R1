function yRepair = eight_process_topology_repair(y)
% Projects an arbitrary 8-bit topology to the nearest logically feasible one.

    y = double(y(:)' > 0.5);

    persistent feasibleTopologies
    if isempty(feasibleTopologies)
        feasibleTopologies = zeros(0,8);
        for n = 0:255
            bits = bitget(uint16(n),1:8);
            if eight_process_logic_feasible(bits)
                feasibleTopologies(end+1,:) = bits; %#ok<AGROW>
            end
        end
    end

    d = sum(feasibleTopologies ~= y,2);
    candidates = find(d == min(d));
    yRepair = feasibleTopologies(candidates(randi(numel(candidates))),:);
end
