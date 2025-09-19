function lines = capture_lines(n, format)
    % Set default format if not provided
    if nargin < 2
        format = '-gx';
    end
    
    lines = [];
    x = [];
    y = [];
    coords = [];
    
    for k = 1:n+1
        [i,j] = ginput(1);
        plot(i, j, format);
        p = [i j 1]';
        
        if k > 1
            plot([x(k-1) i], [y(k-1) j], format);
            lines = [lines cross(coords(:,k-1), p)];
        end
        
        x = [x; i];
        y = [y; j];
        coords = [coords p];
    end

    lines = lines ./ repmat(lines(3,:), [3 1]);
end
