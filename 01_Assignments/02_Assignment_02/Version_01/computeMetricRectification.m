function H_metric = computeMetricRectification(conic, H_affine)
    % Compute metric rectification using the dual absolute conic
    % This removes the remaining similarity transformation after affine rectification
    
    fprintf('Computing metric rectification...\n');
    fprintf('Input conic matrix:\n');
    disp(conic);
    
    % Check if conic is valid
    if rcond(conic) < 1e-12
        warning('Conic matrix is poorly conditioned. Using identity transformation.');
        H_metric = eye(3);
        return;
    end
    
    % Transform the conic using the affine rectification
    % C' = H_affine^-T * C * H_affine^-1
    H_affine_inv = inv(H_affine);
    conic_transformed = H_affine_inv' * conic * H_affine_inv;
    
    fprintf('Transformed conic matrix:\n');
    disp(conic_transformed);
    
    % For a circle, after affine rectification, we need to find the transformation
    % that makes the conic into a circle (removes remaining similarity distortion)
    
    % Extract the 2x2 upper-left part of the conic (ignoring translation)
    A = conic_transformed(1:2, 1:2);
    
    % For a circle, we want A to be proportional to the identity matrix
    % Use SVD to find the similarity transformation
    [U, S, V] = svd(A);
    
    % Check if the conic is reasonable
    if min(S(S > 0)) / max(S(S > 0)) < 0.1
        warning('Conic is very elongated. Metric rectification may not work well.');
        fprintf('Using simplified transformation.\n');
        H_metric = eye(3);
        return;
    end
    
    % Compute the similarity transformation to make the conic circular
    % This involves equalizing the eigenvalues while preserving orientation
    sqrt_S = sqrt(diag(S));
    scale_matrix = diag([sqrt_S(2)/sqrt_S(1), 1]); % Make aspect ratio 1:1
    
    % Construct the metric rectification homography
    % This is a simplified approach - more sophisticated methods exist
    similarity_transform = U * scale_matrix * V';
    
    H_metric = [similarity_transform, [0; 0]; 0, 0, 1];
    
    % Ensure the transformation is reasonable
    if rcond(H_metric) < 1e-12
        warning('Computed metric transformation is poorly conditioned. Using identity.');
        H_metric = eye(3);
        return;
    end
    
    fprintf('Computed metric rectification matrix:\n');
    disp(H_metric);
    
    % Additional safety check - limit the transformation magnitude
    max_element = max(abs(H_metric(:)));
    if max_element > 100
        warning('Metric transformation has very large elements. Scaling down for stability.');
        H_metric = H_metric / max_element * 10;
        fprintf('Scaled metric rectification matrix:\n');
        disp(H_metric);
    end
end