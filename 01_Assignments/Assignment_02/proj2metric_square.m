function T = proj2metric_square(coords)
    % Get the affine rectification transformation and apply it to the input coords
    H_P = proj2affine(coords); 
    affine_coords = H_P * coords;
    
    % Create two non-parallel pairs of orthogonal lines
    % One pair on a corner of the square: lines(:,1) and lines(:,2)
    % One pair from the diagonal and transversal of the square: lines(:,3) and lines(:,4)
    lines = [cross(affine_coords(:,1), affine_coords(:,2))';
             cross(affine_coords(:,2), affine_coords(:,3))';
             cross(affine_coords(:,1), affine_coords(:,3))';
             cross(affine_coords(:,2), affine_coords(:,4))']';
    
    % Normalize the lines
    lines = lines ./ repmat(lines(3,:), [3 1]);
    
    % Get the affine-to-metric rectification from the ortho pairs 
    H_A = affine2metric_orthos(lines(:,1), lines(:,2), lines(:,3), lines(:,4));
    
    % Return the product of the rectification matrices
    T = H_P * H_A;
end
