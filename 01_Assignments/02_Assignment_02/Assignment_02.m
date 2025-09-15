% CAP6419: 3D Computer Vision
% Assignment 02: Chapter 3 of Textbook: Multiple View Geometry in Computer Vision (2nd Edition)


% In this assignment, you are expected to take your own test images and work with them. Write Matlab code to perform:

    % 1. Affine rectification of an imaged planar surface
    % 2. Metric rectification of an imaged planar surface

%% ASSIGNMENT PARAMETERS
% Submit your matlab codes and results on the test images together with a report in a
% word document explaining how your program works (i.e. the steps involved). What were the
% problems that you noticed, if any? Your report should be written like a technical paper, and
% should also include a conclusion section at the end (including your reflections and thoughts, what
% worked and what went wrong if any).
% For your convenience, I have also provided some test images and a short Matlab code for fitting
% a conic to a set of 5 or more points based on the method discussed in the class (page 31 of your
% textbook).
% Grading: 10% data collection (camera pictures, or online images), 20% coding for affine
% rectification, 20% coding for metric rectification, 30% thorough testing on several images for
% both rectifications, 20% report. Again, your report must contain the procedures, input test
% images, output images after rectification, and your conclusions and reflections on the problem
% and the results.
% ______________________________________________________________________
% Suggestion for taking test images: You may want to take a picture of the main lobby of the
% student union, with the encircled Pegasus in the middle that can be used for metric rectification.
% Make sure you can identify parallel lines and/or cross-ratios in your pictures. Also make sure that
% the pictures have enough projective distortion (i.e. taken at an angle).
% Reminder : The intersection of a line l and a conic C can be determined as follows: let m1 and
% m2 be two points on the line l, then any arbitrary point m on the line can be specified
% parametrically by m =m1 +λm2 . Point m is on the intersection of the line with the conic C, iff
% mTCm =(m1 +λm2 )T C(m1 +λm2 ) =0.
% This yields the following quadratic equation in terms of λ
% λ2 m2TCm2 2 +λ m2TCm1 + m1TC m1 0 =
% from which we get the two values λ1 and λ2 , and hence the two intersection points m1 +λ1m2 and
% m1 +λ2m2 . Note that in general a line intersects a conic at two points, which may be distinct or
% not and real or complex


clc, clearvars



% Key Points for Implementation:
    % 1. Data Collection: Take images with clear parallel lines and circular objects
    % 2. Point Selection: Use ginput() for manual point selection or implement automatic detection
    % 3. Conic Fitting: Implement the algorithm from textbook page 31
    % 4. Homography Computation: Handle the mathematical transformations carefully
    % 5. Testing: Test on multiple images with different perspective distortions

% The most challenging part is computing the metric rectification, which requires identifying the absolute conic or circular points in the image.


%% SETUP:

%% REQUIRED PACKAGES AND SETUP
% Add Computer Vision Toolbox functions
if ~license('test', 'Video_and_Image_Blockset')
    warning('Computer Vision Toolbox recommended for enhanced functionality');
end

% Image processing functions
addpath(genpath('.')); % Add current directory and subdirectories

%% IMAGE IMPORT AND PREPROCESSING
% Load test image
img_path = 'path/to/your/image.jpg'; % Replace with actual path
img = imread(img_path);

% Convert to grayscale if needed
if size(img, 3) == 3
    img_gray = rgb2gray(img);
else
    img_gray = img;
end

% Display original image
figure(1);
imshow(img);
title('Original Image');
hold on;


%% AFFINE RECTIFICATION:

% Step 1.1: Identify parallel lines in the scene
% You need to manually select or detect parallel lines that appear as 
% intersecting lines in the image due to perspective distortion

% Step 1.2: Find vanishing point of parallel lines
% Method 1: Manual point selection
fprintf('Select points on first parallel line (at least 2 points)\n');
[x1, y1] = ginput(); % Let user select points
line1 = [x1, y1, ones(length(x1), 1)]; % Convert to homogeneous coordinates

fprintf('Select points on second parallel line (at least 2 points)\n');
[x2, y2] = ginput();
line2 = [x2, y2, ones(length(x2), 1)];

% Fit lines using least squares
L1 = fitLine(line1); % You'll need to implement this function
L2 = fitLine(line2);

% Find vanishing point (intersection of the two lines)
vanishing_point = cross(L1, L2);
vanishing_point = vanishing_point / vanishing_point(3); % Normalize

% Step 1.3: Find the line at infinity
% The line at infinity passes through all vanishing points of parallel lines
% For affine rectification, we need at least one vanishing point

% Step 1.4: Compute affine transformation
% Move the line at infinity to its canonical position [0 0 1]
% This requires identifying the line at infinity in the image

% Homography for affine rectification
H_affine = computeAffineRectification(vanishing_point);

% Step 1.5: Apply transformation
img_affine = applyHomography(img, H_affine);

figure(2);
imshow(img_affine);
title('After Affine Rectification');


%% METRIC RECTIFICATION:

% Step 2.1: Identify orthogonal line pairs or circular objects
% Method 1: Using orthogonal lines
fprintf('Select points on first orthogonal line\n');
[x_orth1, y_orth1] = ginput();
fprintf('Select points on second orthogonal line\n');
[x_orth2, y_orth2] = ginput();

% Method 2: Using circular objects (recommended for the Pegasus example)
fprintf('Select points on circular object (at least 5 points)\n');
[x_circle, y_circle] = ginput();

% Step 2.2: Find the circular points (for Method 2)
% Fit a conic to the circular object
conic_matrix = fitConic([x_circle, y_circle]);

% The image of the circular points are the intersection of the line at infinity
% with the image of the absolute conic

% Step 2.3: Compute metric rectification homography
% This removes the remaining similarity transformation after affine rectification
H_metric = computeMetricRectification(conic_matrix, H_affine);

% Step 2.4: Apply complete transformation
H_complete = H_metric * H_affine;
img_metric = applyHomography(img, H_complete);

figure(3);
imshow(img_metric);
title('After Metric Rectification');



%% HELPER FUNCTIONS:


function line_params = fitLine(points)
    % Fit line to points using least squares
    % points: [x, y, 1] homogeneous coordinates
    % Returns: line parameters [a, b, c] where ax + by + c = 0
    
    A = points(:, 1:2);
    b = -ones(size(points, 1), 1);
    line_params = [A \ b; 1];
    line_params = line_params / norm(line_params(1:2));
end

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

function H = computeAffineRectification(vanishing_point)
    % Compute homography that sends vanishing point to infinity
    % This is a simplified version - you may need to handle multiple vanishing points
    
    vp = vanishing_point(1:2) / vanishing_point(3);
    
    % Simple transformation that moves vanishing point to infinity
    H = [1, 0, 0;
         0, 1, 0;
         vp(1)/1000, vp(2)/1000, 1]; % Scale factors may need adjustment
end

function H_metric = computeMetricRectification(conic, H_affine)
    % Compute metric rectification using the dual absolute conic
    % This is the most complex part and requires careful implementation
    
    % Transform the conic using the affine rectification
    conic_transformed = H_affine' * conic * H_affine;
    
    % Extract the image of the absolute conic
    % and compute the remaining similarity transformation
    
    % Simplified placeholder - actual implementation requires
    % solving for the circular points and orthogonal constraints
    H_metric = eye(3); % Placeholder
end

function img_out = applyHomography(img, H)
    % Apply homography to image
    tform = projective2d(H');
    img_out = imwarp(img, tform);
end


%% IMPLEMENT WORKFLOW:

function runRectification()
    % Load image
    img = imread('your_test_image.jpg');
    
    % Display for point selection
    figure; imshow(img); title('Select points for rectification');
    
    % Perform affine rectification
    img_affine = performAffineRectification(img);
    
    % Perform metric rectification
    img_metric = performMetricRectification(img_affine);
    
    % Display results
    figure;
    subplot(1,3,1); imshow(img); title('Original');
    subplot(1,3,2); imshow(img_affine); title('Affine Rectified');
    subplot(1,3,3); imshow(img_metric); title('Metric Rectified');
end