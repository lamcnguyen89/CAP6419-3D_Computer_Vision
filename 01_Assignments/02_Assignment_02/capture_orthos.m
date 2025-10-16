function [lines_out, m] = capture_orthos(n)
    lines_out = [];
    m = [];
    
    for k = 1:n
        mode = mod(k,6);
        lines = capture_lines(2, sprintf('-@%d%d', mode, mode));
        lines_out = [lines_out lines(:,1)];
        m = [m lines(:,2)];      
    end
end
