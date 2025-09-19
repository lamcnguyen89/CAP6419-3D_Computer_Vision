function coords = capture_points(n, format)
    % Set default format if not provided
    if nargin < 2
        format = 'gx';
    end
    
    x = [];
    y = [];
    for idx = 1:n
        [i,j] = ginput(1);
        plot(i, j, format, 'MarkerSize', 8);
        x = [x; i];
        y = [y; j];
    end
    coords = [x'; y'; ones(1, numel(x))];
end
