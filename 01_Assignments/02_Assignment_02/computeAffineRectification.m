function H = computeAffineRectification(vanishing_point)
    % Compute homography that sends vanishing point to infinity
    % This is a simplified version - you may need to handle multiple vanishing points
    
    vp = vanishing_point(1:2) / vanishing_point(3);
    
    % Simple transformation that moves vanishing point to infinity
    H = [1, 0, 0;
         0, 1, 0;
         vp(1)/1000, vp(2)/1000, 1]; % Scale factors may need adjustment
end