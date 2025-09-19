function conic = fitConic(points)
    % Fit conic to 5 or more points
    % For circular objects, use direct circle fitting then convert to conic
    % This is more robust than general conic fitting for metric rectification
    
    x = points(:, 1);
    y = points(:, 2);
    
    fprintf('Attempting direct circle fitting for better numerical stability...\n');
    
    % Method 1: Direct circle fitting (x-h)^2 + (y-k)^2 = r^2
    % Rearrange to: x^2 + y^2 - 2hx - 2ky + (h^2 + k^2 - r^2) = 0
    % Linear system: Ax = b where x = [h; k; (h^2 + k^2 - r^2)]
    
    % Normalize coordinates for better conditioning
    x_mean = mean(x);
    y_mean = mean(y);
    x_scale = std(x);
    y_scale = std(y);
    
    if x_scale < 1, x_scale = 1; end
    if y_scale < 1, y_scale = 1; end
    
    x_norm = (x - x_mean) / x_scale;
    y_norm = (y - y_mean) / y_scale;
    
    fprintf('Circle fitting normalization: center=[%.1f,%.1f], scale=[%.1f,%.1f]\n', ...
            x_mean, y_mean, x_scale, y_scale);
    
    % Set up linear system for circle fitting
    A_circle = [2*x_norm, 2*y_norm, ones(length(x_norm), 1)];
    b_circle = x_norm.^2 + y_norm.^2;
    
    % Solve for circle parameters
    circle_params = A_circle \ b_circle;
    h_norm = circle_params(1);
    k_norm = circle_params(2);
    c_norm = circle_params(3);
    
    % Transform back to original coordinates
    h = h_norm * x_scale + x_mean;
    k = k_norm * y_scale + y_mean;
    r_squared = h_norm^2 * x_scale^2 + k_norm^2 * y_scale^2 + c_norm * x_scale * y_scale;
    
    if r_squared <= 0
        warning('Circle fitting produced negative radius squared. Using fallback method.');
        % Fall back to general conic
        conic = fitConicGeneral(points);
        return;
    end
    
    r = sqrt(r_squared);
    fprintf('Fitted circle: center=[%.1f,%.1f], radius=%.1f\n', h, k, r);
    
    % Convert circle to conic matrix form
    % Circle: (x-h)^2 + (y-k)^2 = r^2
    % Expanded: x^2 + y^2 - 2hx - 2ky + (h^2 + k^2 - r^2) = 0
    % Conic matrix: [1, 0, -h; 0, 1, -k; -h, -k, (h^2 + k^2 - r^2)]
    
    conic = [1, 0, -h;
             0, 1, -k;
             -h, -k, h^2 + k^2 - r^2];
    
    % Normalize the matrix
    max_element = max(abs(conic(:)));
    if max_element > 0
        conic = conic / max_element;
    end
    
    % Verify this is a valid ellipse/circle
    A_quad = conic(1:2, 1:2);
    det_A = det(A_quad);
    trace_A = trace(A_quad);
    
    fprintf('Circle conic validation: det(A)=%.2e, trace(A)=%.2e\n', det_A, trace_A);
    
    if det_A > 0 && trace_A > 0
        fprintf('Successfully fitted circle as ellipse conic\n');
    else
        warning('Circle conic validation failed. Using fallback method.');
        conic = fitConicGeneral(points);
        return;
    end
    
    fprintf('Final circle-based conic condition number: %.2e\n', cond(conic));
end

function conic = fitConicGeneral(points)
    % Fallback general conic fitting method
    fprintf('Using general conic fitting method...\n');
    
    x = points(:, 1);
    y = points(:, 2);
    
    % Simple normalization
    x_mean = mean(x);
    y_mean = mean(y);
    scale = max(max(abs(x-x_mean)), max(abs(y-y_mean)));
    if scale < 1, scale = 1; end
    
    x_norm = (x - x_mean) / scale;
    y_norm = (y - y_mean) / scale;
    
    % Design matrix for general conic
    A = [x_norm.^2, x_norm.*y_norm, y_norm.^2, x_norm, y_norm, ones(length(x_norm), 1)];
    
    % SVD solution
    [~, ~, V] = svd(A);
    conic_vec = V(:, end);
    
    % Convert to matrix form
    conic_norm = [conic_vec(1), conic_vec(2)/2, conic_vec(4)/2;
                  conic_vec(2)/2, conic_vec(3), conic_vec(5)/2;
                  conic_vec(4)/2, conic_vec(5)/2, conic_vec(6)];
    
    % Transform back to original coordinates
    T = [1/scale, 0, -x_mean/scale;
         0, 1/scale, -y_mean/scale;
         0, 0, 1];
    
    conic = T' * conic_norm * T;
    
    % Normalize
    max_element = max(abs(conic(:)));
    if max_element > 0
        conic = conic / max_element;
    end
    
    fprintf('General conic condition number: %.2e\n', cond(conic));
end