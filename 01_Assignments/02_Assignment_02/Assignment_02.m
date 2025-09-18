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

% Source for explaining Affine and Metric Rectification: https://medium.com/antaeus-ar/undoing-perspective-affine-and-metric-rectification-of-images-stratification-part-1-238323171839

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
% Try to get the directory where this script is located (works in newer MATLAB versions)
try
    script_dir = fileparts(mfilename('fullpath'));
    img_path = fullfile(script_dir, 'Homework 2_Materials', 'Crop_Circle.jpg');
catch
    % Fallback for older MATLAB versions - assume relative path
    img_path = fullfile('Homework 2_Materials', 'Crop_Circle.jpg');
end

if ~exist(img_path, 'file')
    error('Image file not found: %s\nAvailable images in Homework 2_Materials:\n- Building.jpg\n- Crop_Circle.jpg\n- desk.jpg\n- UCF SU.jpg\n\nMake sure you are running the script from: d:\\SoftwareDev\\CAP6419-3D_Computer_Vision\\01_Assignments\\02_Assignment_02\\', img_path);
end
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

