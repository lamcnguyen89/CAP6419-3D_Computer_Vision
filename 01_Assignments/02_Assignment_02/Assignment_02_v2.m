
%% Main demonstration script
% Run this to see how to use the proj2metric function
function main()
    fprintf('=== Projective to Metric Rectification Demo ===\n\n');
    
    fprintf('Choose an option:\n');
    fprintf('1. Interactive rectification (click on image)\n');
    fprintf('2. Automatic rectification with predefined coordinates\n');
    choice = input('Enter your choice (1 or 2): ');
    
    switch choice
        case 1
            demo_proj2metric_rectification();
        case 2
            demo_proj2metric_automatic();
        otherwise
            fprintf('Invalid choice. Running interactive demo...\n');
            demo_proj2metric_rectification();
    end
end

% Function that performs both affine and metric rectification on an image
function T = proj2metric_square(coords)
    % Get the affine rectification transformation and apply it to the input coords
    H_P = proj2affine(coords); 
    affine_coords = H_P * coords;
    
    % Create two non-parallel pairs of orthogonal lines
    % One pair on a corner of the square: l(:,1) and l(:,2)
    % One pair from the diagonal and transversal of the square: l(:,3) and l(:,4)
    l = [cross(affine_coords(:,1), affine_coords(:,2))'
         cross(affine_coords(:,2), affine_coords(:,3))'
         cross(affine_coords(:,1), affine_coords(:,3))'
         cross(affine_coords(:,2), affine_coords(:,4))']';
    
    % Normalize the lines
    l ./= repmat(l(3,:), [3 1]);
    
    % Get the affine-to-metric rectification from the ortho pairs 
    H_A = affine2metric_orthos(l(:,1), l(:,2), l(:,3), l(:,4));
    
    % Return the product of the rectification matrices
    T = H_P*H_A;
endfunction

% Function to perform affine rectification
function T = proj2affine(coords)
    T = eye(3);
    
    if (length(coords) < 4)
        fprintf(1, "Insufficient points (%d): " \\
            "provide at least 4 points for affine rectification", npoints); 
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
        l_inf ./= l_inf(3);
        T(3,:) = l_inf';
    endif
endfunction

% Function to perform metric rectification
function T = affine2metric_orthos(l1, m1, l2, m2)
    T = eye(3);
    
    % Refer to Hartley and Zisserman, Multiple View Geometry, 2nd Ed. (pp 55-56)
    % Find S = K K-transpose
    
    % Set up the constraints from the orthogonal line pairs
    ortho_constraints = [l1(1)*m1(1), l1(1)*m1(2)+l1(2)*m1(1), l1(2)*m1(2)
                         l2(1)*m2(1), l2(1)*m2(2)+l2(2)*m2(1), l2(2)*m2(2)];
    
    % Find s and S from the null space of the constraints matrix
    s = null(ortho_constraints);
    S = [s(1) s(2); s(2) s(3)]

    % Produces "error: chol: matrix not positive definite" on some cases
    % Get K from the Cholesky decomposition of S
    %K = chol(S);

    % Recover K using SVD of S    
    [u, sigma, v] = svd(S)
    K = u*sqrt(sigma)*u'
    T(1:2,1:2) = K;
    T = inv(T);
endfunction

%% Example usage of proj2metric function for image rectification
function demo_proj2metric_rectification()
    % Load an image (replace with your image path)
    img = imread('Crop_Circle.jpg'); % Using the crop circle image from your materials
    
    % Display the original image
    figure(1);
    imshow(img);
    title('Original Image - Click 4 corners of a square/rectangle');
    
    % Get 4 corner points of a square/rectangle from user input
    fprintf('Click on 4 corners of a square or rectangle in clockwise order:\n');
    [x, y] = ginput(4);
    
    % Convert to homogeneous coordinates (3xN matrix)
    coords = [x'; y'; ones(1,4)];
    
    % Get the projective-to-metric transformation matrix
    T = proj2metric_square(coords);
    
    % Apply the transformation to rectify the image
    tform = projective2d(T');  % MATLAB expects transposed matrix
    
    % Create output view that preserves the full rectified image
    [height, width, ~] = size(img);
    
    % Transform the corner points to see the output bounds
    corners_orig = [1 width width 1; 1 1 height height; 1 1 1 1];
    corners_transformed = T * corners_orig;
    corners_transformed = corners_transformed ./ corners_transformed(3,:);
    
    % Define output bounds
    x_min = min(corners_transformed(1,:));
    x_max = max(corners_transformed(1,:));
    y_min = min(corners_transformed(2,:));
    y_max = max(corners_transformed(2,:));
    
    % Create output reference
    outputView = imref2d([ceil(y_max-y_min), ceil(x_max-x_min)], ...
                        [x_min, x_max], [y_min, y_max]);
    
    % Apply the transformation
    rectified_img = imwarp(img, tform, 'OutputView', outputView);
    
    % Display the rectified image
    figure(2);
    imshow(rectified_img);
    title('Rectified Image (Affine + Metric Rectification)');
    
    % Show both images side by side for comparison
    figure(3);
    subplot(1,2,1);
    imshow(img);
    title('Original Image');
    hold on;
    plot([x; x(1)], [y; y(1)], 'r-', 'LineWidth', 2);
    plot(x, y, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    
    subplot(1,2,2);
    imshow(rectified_img);
    title('Rectified Image');
    
    fprintf('Rectification complete!\n');
    fprintf('Transformation matrix T:\n');
    disp(T);
end

%% Alternative function for automatic rectification using predefined coordinates
function demo_proj2metric_automatic()
    % Load an image
    img = imread('Crop_Circle.jpg');
    
    % Define coordinates of a quadrilateral that should be a square
    % (you would measure these from your specific image)
    % Example coordinates - adjust these for your actual image
    coords = [100, 300, 300, 100;   % x coordinates
              100, 100, 300, 300;   % y coordinates
              1,   1,   1,   1];     % homogeneous coordinates
    
    % Get the transformation matrix
    T = proj2metric_square(coords);
    
    % Apply transformation and display results
    tform = projective2d(T');
    rectified_img = imwarp(img, tform);
    
    figure;
    subplot(1,2,1);
    imshow(img);
    title('Original');
    
    subplot(1,2,2);
    imshow(rectified_img);
    title('Rectified');
    
    fprintf('Automatic rectification complete!\n');
end
