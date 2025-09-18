function line_params = fitLine(points)
    % Fit line to points using least squares
    % points: [x, y, 1] homogeneous coordinates
    % Returns: line parameters [a, b, c] where ax + by + c = 0
    
    A = points(:, 1:2);
    b = -ones(size(points, 1), 1);
    line_params = [A \ b; 1];
    line_params = line_params / norm(line_params(1:2));
end