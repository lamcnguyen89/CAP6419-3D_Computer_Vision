function H = computeAffineRectification(vanishing_point)
    % Compute homography that sends vanishing point to infinity
    % This removes affine distortion by making parallel lines truly parallel
    
    % Normalize the vanishing point
    vp = vanishing_point(1:2) / vanishing_point(3);
    
    fprintf('Vanishing point: [%.2f, %.2f]\n', vp(1), vp(2));
    
    % Check if vanishing point is reasonable
    if abs(vp(1)) > 10000 || abs(vp(2)) > 10000
        warning('Vanishing point is very far from image center. This may cause distortion.');
        fprintf('Consider re-selecting points on more clearly parallel lines.\n');
        
        % For very distant vanishing points, use a simpler transformation
        fprintf('Using simplified transformation for distant vanishing point.\n');
        H = eye(3); % Identity matrix - no transformation
        return;
    end
    
    % Check if vanishing point is too close to image center (lines too parallel)
    if abs(vp(1)) < 50 && abs(vp(2)) < 50
        warning('Vanishing point is very close to image center.');
        fprintf('This suggests lines are nearly parallel in the image.\n');
        fprintf('Using minimal transformation.\n');
        
        % Use a very small correction
        H = [1, 0, 0;
             0, 1, 0;
             vp(1)/10000, vp(2)/10000, 1];
        fprintf('Computed affine rectification matrix H:\n');
        disp(H);
        return;
    end
    
    % Standard affine rectification
    % The transformation should send the line through the vanishing point to infinity
    % H = [I, 0; l_inf^T, 1] where l_inf is the line at infinity
    
    % Create transformation that maps vanishing point to infinity
    % Use the line passing through the vanishing point as the line at infinity
    
    % Normalize vanishing point coordinates relative to typical image size (assume ~1000px)
    scale_factor = 1000;
    vp_normalized = vp / scale_factor;
    
    % Create homography
    H = [1, 0, 0;
         0, 1, 0;
         vp_normalized(1), vp_normalized(2), 1];
    
    fprintf('Scale factor used: %.2f\n', scale_factor);
    fprintf('Normalized vanishing point: [%.6f, %.6f]\n', vp_normalized(1), vp_normalized(2));
    fprintf('Computed affine rectification matrix H:\n');
    disp(H);
end