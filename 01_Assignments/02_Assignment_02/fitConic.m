function conic = fitConic(points)
    % Fit conic to 5 or more points
    % Based on the method from textbook page 31
    
    x = points(:, 1);
    y = points(:, 2);
    
    % Design matrix for conic: ax^2 + bxy + cy^2 + dx + ey + f = 0
    A = [x.^2, x.*y, y.^2, x, y, ones(length(x), 1)];
    
    % Solve homogeneous system using SVD
    [~, ~, V] = svd(A);
    conic_vec = V(:, end);
    
    % Reshape to matrix form
    conic = [conic_vec(1), conic_vec(2)/2, conic_vec(4)/2;
             conic_vec(2)/2, conic_vec(3), conic_vec(5)/2;
             conic_vec(4)/2, conic_vec(5)/2, conic_vec(6)];
end