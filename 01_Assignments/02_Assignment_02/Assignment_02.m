% CAP6419: 3D Computer Vision
% Assignment 02: Chapter 3 of Textbook: Multiple View Geometry in Computer Vision (2nd Edition)

%% HOW TO USE THIS CODE:
%
% This script performs affine and metric rectification on an image.
% 
% BEFORE RUNNING:
% 1. Make sure you are in the correct directory:
%    d:\SoftwareDev\CAP6419-3D_Computer_Vision\01_Assignments\02_Assignment_02\
% 2. Ensure you have the required functions in the same directory:
%    - fitLine.m
%    - applyHomography.m
%    - computeAffineRectification.m
%    - computeMetricRectification.m
%    - fitConic.m
%
% WHEN RUNNING:
% 1. The script will display an image and prompt you to select points
% 2. DO NOT CLOSE THE FIGURE WINDOW during point selection
% 3. Follow the on-screen instructions carefully
% 4. Click points with your mouse, then press ENTER when done
% 5. If you make a mistake, stop the script (Ctrl+C) and run it again
%
% POINT SELECTION GUIDE:
% - Parallel Lines: Select points along lines that are parallel in real world
%   but appear to converge in the image (e.g., building edges, table sides)
% - Circular Object: Select 5+ points around the circumference of a circle
%   that appears as an ellipse in the image (e.g., Pegasus logo, clock)
%
% TROUBLESHOOTING:
% - If you get "Interrupted by figure deletion" error: Keep figure window open
% - If you get "Index exceeds matrix dimensions": Select enough points
% - If results look wrong: Try selecting different/better points
%


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

%% IMAGE SELECTION - Change this variable to test different images
% Available images: 'Building.jpg', 'Crop_Circle.jpg', 'desk.jpg', 'UCF SU.jpg'
IMAGE_NAME = 'Lam_Image.jpg';  % Change this to use a different image

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
    img_path = fullfile(script_dir, 'Homework 2_Materials', IMAGE_NAME);
catch
    % Fallback for older MATLAB versions - assume relative path
    img_path = fullfile('Homework 2_Materials', IMAGE_NAME);
end

if ~exist(img_path, 'file')
    error('Image file not found: %s\nAvailable images in Homework 2_Materials:\n- Building.jpg\n- Crop_Circle.jpg\n- desk.jpg\n- UCF SU.jpg\n\nMake sure you are running the script from: d:\\SoftwareDev\\CAP6419-3D_Computer_Vision\\01_Assignments\\02_Assignment_02\\\nAnd check that IMAGE_NAME variable is set to a valid filename.', img_path);
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

disp('=================================================================');
disp('AFFINE RECTIFICATION - Step 1: Select Parallel Lines');
disp('=================================================================');
disp('You will now select points on two parallel lines in the image.');
disp('These lines should appear to converge due to perspective distortion.');
disp('For example, you can select points along:');
disp('- Sides of a rectangular building');
disp('- Edges of a table or desk');
disp('- Parallel lines on the floor');
disp(' ');
disp('Tips for selecting good parallel lines:');
disp('- Choose lines that clearly converge in the image (due to perspective)');
disp('- Avoid lines that are nearly parallel in the image (they should meet somewhere)');
disp('- Good examples: building edges, table sides, road edges, fence lines');
disp('- Make sure lines are actually parallel in the real world');
disp(' ');
disp('IMPORTANT: DO NOT close the figure window during point selection!');
disp('Press any key to continue...');
pause;

% Step 1.2: Find vanishing point of parallel lines
% Method 1: Manual point selection
fprintf('\n=== SELECT FIRST PARALLEL LINE ===\n');
fprintf('Select points on first parallel line (at least 2 points)\n');
fprintf('1. Click on the image to select points along the first line\n');
fprintf('2. Select at least 2 points (more points = better accuracy)\n');
fprintf('3. Press ENTER when you are done selecting points\n');
fprintf('4. DO NOT close the figure window!\n\n');

% Ensure figure is active and visible
figure(1);
[x1, y1] = ginput(); % Let user select points

% Validate first line points
if length(x1) < 2
    error('You must select at least 2 points for the first line');
end

line1 = [x1, y1, ones(length(x1), 1)]; % Convert to homogeneous coordinates

% Plot selected points on first line
hold on;
plot(x1, y1, 'ro-', 'LineWidth', 2, 'MarkerSize', 8);
text(x1(1), y1(1)-20, 'Line 1', 'Color', 'red', 'FontSize', 12, 'FontWeight', 'bold');

fprintf('\n=== SELECT SECOND PARALLEL LINE ===\n');
fprintf('Select points on second parallel line (at least 2 points)\n');
fprintf('1. Click on the image to select points along the second line\n');
fprintf('2. This line should be parallel to the first line in the real world\n');
fprintf('3. Select at least 2 points (more points = better accuracy)\n');
fprintf('4. Press ENTER when you are done selecting points\n');
fprintf('5. DO NOT close the figure window!\n\n');

% Ensure figure is still active
figure(1);
[x2, y2] = ginput();

% Validate second line points
if length(x2) < 2
    error('You must select at least 2 points for the second line');
end

line2 = [x2, y2, ones(length(x2), 1)];

% Plot selected points on second line
plot(x2, y2, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
text(x2(1), y2(1)-20, 'Line 2', 'Color', 'blue', 'FontSize', 12, 'FontWeight', 'bold');

fprintf('Great! You selected %d points on line 1 and %d points on line 2.\n\n', length(x1), length(x2));

% Fit lines using least squares
L1 = fitLine(line1); % You'll need to implement this function
L2 = fitLine(line2);

fprintf('Line 1 parameters: [%.4f, %.4f, %.4f]\n', L1(1), L1(2), L1(3));
fprintf('Line 2 parameters: [%.4f, %.4f, %.4f]\n', L2(1), L2(2), L2(3));

% Find vanishing point (intersection of the two lines)
vanishing_point = cross(L1, L2);
vanishing_point = vanishing_point / vanishing_point(3); % Normalize

fprintf('Raw vanishing point: [%.2f, %.2f, %.2f]\n', vanishing_point(1), vanishing_point(2), vanishing_point(3));

% Check if lines are nearly parallel (which would give a vanishing point at infinity)
line_angle = abs(atan2(L1(2), L1(1)) - atan2(L2(2), L2(1))) * 180/pi;
if line_angle > 90
    line_angle = 180 - line_angle; % Take acute angle
end
fprintf('Angle between lines: %.2f degrees\n', line_angle);

if line_angle < 5
    warning('Lines are nearly parallel (angle < 5 degrees). This may cause numerical instability.');
    fprintf('Consider selecting points on lines that converge more clearly in the image.\n');
end

% Step 1.3: Find the line at infinity
% The line at infinity passes through all vanishing points of parallel lines
% For affine rectification, we need at least one vanishing point

% Step 1.4: Compute affine transformation
% Move the line at infinity to its canonical position [0 0 1]
% This requires identifying the line at infinity in the image

% Homography for affine rectification
H_affine = computeAffineRectification(vanishing_point);

fprintf('\nDEBUG: Affine rectification homography H_affine:\n');
disp(H_affine);

% Check the condition number of the homography
cond_num = cond(H_affine);
fprintf('Condition number of H_affine: %.2e\n', cond_num);
if cond_num > 1e12
    warning('Homography is poorly conditioned. Results may be unreliable.');
end

% Step 1.5: Apply transformation
fprintf('\nApplying affine transformation...\n');
% Option 1: Use the updated applyHomography function (works with older MATLAB)
img_affine = applyHomography(img, H_affine);

fprintf('Original image size: %d x %d\n', size(img, 1), size(img, 2));
fprintf('Transformed image size: %d x %d\n', size(img_affine, 1), size(img_affine, 2));
fprintf('Transformed image data type: %s\n', class(img_affine));
fprintf('Transformed image range: [%d, %d]\n', min(img_affine(:)), max(img_affine(:)));

% Check if we got a black image
if max(img_affine(:)) == 0
    warning('Transformed image is completely black! Trying alternative approach...');
    
    % Try using the provided TransformImage function instead
    fprintf('Trying TransformImage function...\n');
    try
        img_affine = TransformImage(img, H_affine);
        fprintf('TransformImage succeeded. New image range: [%d, %d]\n', min(img_affine(:)), max(img_affine(:)));
    catch ME
        fprintf('TransformImage also failed: %s\n', ME.message);
        
        % Last resort: try with identity matrix (no transformation)
        fprintf('Using identity transformation as fallback...\n');
        img_affine = img;
    end
end

% Option 2: Use the provided TransformImage function directly
% img_affine = TransformImage(img, H_affine);

figure(2);
imshow(img_affine);
title('After Affine Rectification');


%% METRIC RECTIFICATION:

disp('=================================================================');
disp('METRIC RECTIFICATION - Step 2: Select Orthogonal Lines or Circles');
disp('=================================================================');
disp('Now you will perform metric rectification to remove similarity transformation.');
disp('You have two options:');
disp('1. Select points on two orthogonal (perpendicular) lines');
disp('2. Select points on a circular object (recommended)');
disp(' ');
disp('For the circle method (recommended):');
disp('- Look for circular objects in the image (like the Pegasus logo)');
disp('- Select at least 5 points around the circumference');
disp('- Try to distribute points evenly around the circle');
disp(' ');
disp('IMPORTANT: DO NOT close the figure window during point selection!');
disp('Press any key to continue...');
pause;

% Step 2.1: Identify orthogonal line pairs or circular objects
% Method 1: Using orthogonal lines
fprintf('\n=== METHOD 1: ORTHOGONAL LINES (Optional) ===\n');
fprintf('Select points on first orthogonal line (or press ENTER to skip)\n');
fprintf('These should be lines that are perpendicular in the real world\n');

% Ensure figure 2 is active
figure(2);
[x_orth1, y_orth1] = ginput();

if ~isempty(x_orth1)
    fprintf('Select points on second orthogonal line\n');
    fprintf('This line should be perpendicular to the first line in the real world\n');
    figure(2);
    [x_orth2, y_orth2] = ginput();
end

% Method 2: Using circular objects (recommended for the Pegasus example)
fprintf('\n=== METHOD 2: CIRCULAR OBJECT (Recommended) ===\n');
fprintf('Select points on circular object (at least 5 points)\n');
fprintf('1. Look for a circular object in the affine-rectified image\n');
fprintf('2. Click points around the circumference of the circle\n');
fprintf('3. Try to select at least 5 points distributed evenly\n');
fprintf('4. Press ENTER when done\n');
fprintf('5. DO NOT close the figure window!\n\n');

% Ensure figure 2 is active
figure(2);
try
    [x_circle, y_circle] = ginput();
catch ME
    if contains(ME.message, 'Interrupted by figure deletion')
        error('Figure was closed during point selection. Please run the script again and keep the figure window open.');
    else
        rethrow(ME);
    end
end

% Validate circle points
if length(x_circle) < 5
    warning('Fewer than 5 points selected for the circle. This may result in poor fitting.');
    if length(x_circle) < 3
        error('You must select at least 3 points to fit a conic (circle)');
    end
end

% Plot selected circle points
hold on;
plot(x_circle, y_circle, 'go', 'MarkerSize', 8, 'LineWidth', 2);
text(x_circle(1), y_circle(1)-20, 'Circle Points', 'Color', 'green', 'FontSize', 12, 'FontWeight', 'bold');

fprintf('Great! You selected %d points on the circular object.\n\n', length(x_circle));

% Step 2.2: Find the circular points (for Method 2)
% Fit a conic to the circular object
conic_matrix = fitConic([x_circle, y_circle]);

% The image of the circular points are the intersection of the line at infinity
% with the image of the absolute conic

% Step 2.3: Compute metric rectification homography
% This removes the remaining similarity transformation after affine rectification
H_metric = computeMetricRectification(conic_matrix, H_affine);

fprintf('\nDEBUG: Metric rectification homography H_metric:\n');
disp(H_metric);

% Step 2.4: Apply complete transformation
H_complete = H_metric * H_affine;

fprintf('DEBUG: Complete transformation homography H_complete:\n');
disp(H_complete);

% Check condition number of complete transformation
cond_complete = cond(H_complete);
fprintf('Condition number of H_complete: %.2e\n', cond_complete);

if cond_complete > 1e12
    warning('Complete transformation is poorly conditioned. Results may be unreliable.');
    fprintf('Trying metric rectification on the affine-corrected image instead...\n');
    
    % Alternative approach: apply metric rectification to the already affine-corrected image
    img_metric = applyHomography(img_affine, H_metric);
else
    fprintf('Applying complete transformation to original image...\n');
    img_metric = applyHomography(img, H_complete);
end

fprintf('Final image size: %d x %d\n', size(img_metric, 1), size(img_metric, 2));
fprintf('Final image range: [%d, %d]\n', min(img_metric(:)), max(img_metric(:)));

% Check if image is too large and resize if necessary
max_display_size = 1500; % Maximum dimension for display
if size(img_metric, 1) > max_display_size || size(img_metric, 2) > max_display_size
    fprintf('Image is very large (%dx%d). Resizing for display...\n', size(img_metric, 1), size(img_metric, 2));
    
    % Calculate resize factor
    scale_factor = max_display_size / max(size(img_metric, 1), size(img_metric, 2));
    img_metric_display = imresize(img_metric, scale_factor);
    
    fprintf('Resized to: %dx%d (scale factor: %.3f)\n', size(img_metric_display, 1), size(img_metric_display, 2), scale_factor);
    
    figure(3);
    imshow(img_metric_display);
    title(sprintf('After Metric Rectification (Resized to %.1f%% for display)', scale_factor*100));
else
    figure(3);
    imshow(img_metric);
    title('After Metric Rectification');
end

