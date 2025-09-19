function T = proj2metric_orthos(lines, m)
    T = eye(3);
    % Build the 5x6 constraints matrix from each orthogonal line pair lines,m
    M = [ lines(1,:).*m(1,:);
         (lines(1,:).*m(2,:) + lines(2,:).*m(1,:))/2 ; 
          lines(2,:).*m(2,:) ; 
         (lines(1,:).*m(3,:) + lines(3,:).*m(1,:))/2 ; 
         (lines(2,:).*m(3,:) + lines(3,:).*m(2,:))/2 ; 
          lines(2,:).*m(2,:)]';
    
    % Compute the degenerate dual conic by finding the null space of M
    c = null(M)(:,1);
    Cstarinf = [c(1) c(2)/2 c(4)/2; c(2)/2 c(3) c(5)/2; c(4)/2 c(5)/2 c(6)];
    [U, lambda] = eig(Cstarinf);
    U_T = U';
    ss = [sqrt(lambda(1)) 0; 0 sqrt(lambda(2))];
    U_T = ss*U_T;
    U = U_T';
    T = inv(U);
end
