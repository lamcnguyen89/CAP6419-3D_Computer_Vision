function coords = capture_quad(format)
    % Set default format if not provided
    if nargin < 1
        format = '-g';
    end
    
    x = [];
    y = [];
    for k = 1:4
        [i,j] = ginput(1);
        plot(i, j, 'gx', 'MarkerSize', 10);  % Green x markers

        if k > 1
            plot([x(k-1) i], [y(k-1) j], format);
        end
        
        x = [x; i];
        y = [y; j];
    end
    plot([x(4) x(1)], [y(4), y(1)], format);
    coords = [x'; y'; ones(1, numel(x))];
end
