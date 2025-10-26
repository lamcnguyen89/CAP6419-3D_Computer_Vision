function T = proj2affine(coords)
    T = eye(3);
    
    if size(coords, 2) < 4
        npoints = size(coords, 2);
        fprintf(1, 'Insufficient points (%d): provide at least 4 points for affine rectification\n', npoints); 
    else
        % Assume rectification using parallel line set
        l1 = cross(coords(:,1), coords(:,2));
        l2 = cross(coords(:,2), coords(:,3));
        l3 = cross(coords(:,3), coords(:,4));
        l4 = cross(coords(:,4), coords(:,1));
    
        % Find the vanishing points
        v = [cross(l1, l3) cross(l2, l4)];

        % Find the line at infinity and scale it down to prevent overflow
        l_inf = cross(v(:,1), v(:,2));
        l_inf = l_inf / l_inf(3);
        T(3,:) = l_inf';
    end
end
