% 3D Reconstruction using MATLAB's triangulate function
% This script performs stereo triangulation from two calibrated images

clear; close all; clc;

% Change to the Input_Images directory
cd('Input_Images');

% Run calibration file to load parameters
calib;

% Display loaded parameters
fprintf('Loaded calibration parameters:\n');
fprintf('Camera 1 intrinsic matrix:\n');
disp(cam1);
fprintf('Camera 2 intrinsic matrix:\n');
disp(cam2);
fprintf('Baseline: %.3f mm\n', baseline);
fprintf('Image size: %d x %d\n', width, height);

%% Step 1: Detect features in both images
fprintf('\nDetecting SURF features in both images...\n');

% Convert to grayscale if needed
if size(im1, 3) == 3
    gray1 = rgb2gray(im1);
else
    gray1 = im1;
end

if size(im2, 3) == 3
    gray2 = rgb2gray(im2);
else
    gray2 = im2;
end

% Detect SURF features
points1 = detectSURFFeatures(gray1);
points2 = detectSURFFeatures(gray2);

% Extract feature descriptors
[features1, validPoints1] = extractFeatures(gray1, points1);
[features2, validPoints2] = extractFeatures(gray2, points2);

fprintf('Detected %d features in image 1\n', validPoints1.Count);
fprintf('Detected %d features in image 2\n', validPoints2.Count);

%% Step 2: Match features between images
fprintf('\nMatching features...\n');
indexPairs = matchFeatures(features1, features2, 'MaxRatio', 0.6);

% Get matched points
matchedPoints1 = validPoints1(indexPairs(:, 1));
matchedPoints2 = validPoints2(indexPairs(:, 2));

fprintf('Found %d matched feature pairs\n', size(indexPairs, 1));

%% Step 3: Visualize matches
figure('Name', 'Feature Matches');
showMatchedFeatures(im1, im2, matchedPoints1, matchedPoints2);
title('Matched Features Between Stereo Pair');
legend('Matched points 1', 'Matched points 2');

%% Step 4: Set up camera parameters for triangulation
% Extract matched point locations
points1_loc = matchedPoints1.Location;
points2_loc = matchedPoints2.Location;

% Create cameraIntrinsics objects from the intrinsic matrices
% Extract parameters from cam1 and cam2
fx1 = cam1(1,1);
fy1 = cam1(2,2);
cx1 = cam1(1,3);
cy1 = cam1(2,3);

fx2 = cam2(1,1);
fy2 = cam2(2,2);
cx2 = cam2(1,3);
cy2 = cam2(2,3);

% Create cameraIntrinsics objects
intrinsics1 = cameraIntrinsics([fx1 fy1], [cx1 cy1], [height width]);
intrinsics2 = cameraIntrinsics([fx2 fy2], [cx2 cy2], [height width]);

% Create camera matrices (projection matrices)
% Camera 1 is at the origin [I | 0]
R1 = eye(3);
t1 = [0; 0; 0];

% Camera 2 is translated along x-axis by baseline
R2 = eye(3);
t2 = [baseline; 0; 0];  % baseline in mm

% Create camera projection matrices using cameraIntrinsics objects
camMatrix1 = cameraMatrix(intrinsics1, R1, t1);
camMatrix2 = cameraMatrix(intrinsics2, R2, t2);

fprintf('\nCamera projection matrices created\n');

%% Step 5: Triangulate 3D points
fprintf('Triangulating 3D points...\n');

% Use MATLAB's triangulate function
% points3D will be in world coordinates (mm)
points3D = triangulate(points1_loc, points2_loc, camMatrix1', camMatrix2');

fprintf('Triangulated %d 3D points\n', size(points3D, 1));

% Check the range of triangulated points
fprintf('Raw 3D point statistics:\n');
fprintf('  X range: [%.2f, %.2f]\n', min(points3D(:,1)), max(points3D(:,1)));
fprintf('  Y range: [%.2f, %.2f]\n', min(points3D(:,2)), max(points3D(:,2)));
fprintf('  Z range: [%.2f, %.2f]\n', min(points3D(:,3)), max(points3D(:,3)));

%% Step 6: Filter out invalid points (minimal filtering)
% Remove points with NaN or Inf values only
validIdx = all(isfinite(points3D), 2);
fprintf('Points after removing NaN/Inf: %d\n', sum(validIdx));

% Use all finite points - no depth filtering
points3D_filtered = points3D(validIdx, :);

fprintf('After filtering: %d valid 3D points (all finite points kept)\n', size(points3D_filtered, 1));

%% Step 7: Get color information from image
% Use the first image for color mapping
colors = zeros(size(points3D_filtered, 1), 3);
validIndices = find(validIdx);

for i = 1:size(points3D_filtered, 1)
    % Get the original index
    origIdx = validIndices(i);
    
    % Get pixel location from first image
    x = round(points1_loc(origIdx, 1));
    y = round(points1_loc(origIdx, 2));
    
    % Ensure coordinates are within bounds
    x = max(1, min(x, width));
    y = max(1, min(y, height));
    
    % Get RGB color
    if size(im1, 3) == 3
        colors(i, :) = double(im1(y, x, :)) / 255;
    else
        grayVal = double(im1(y, x)) / 255;
        colors(i, :) = [grayVal, grayVal, grayVal];
    end
end

fprintf('Color mapping complete\n');

%% Step 8: Create 3D scatter plot
figure('Name', '3D Reconstruction');
scatter3(points3D_filtered(:, 1), points3D_filtered(:, 2), points3D_filtered(:, 3), ...
    10, colors, 'filled');

xlabel('X (mm)');
ylabel('Y (mm)');
zlabel('Z (mm)');
title('3D Reconstruction from Stereo Triangulation');
grid on;

% Calculate ranges for custom axis scaling
xRange = max(points3D_filtered(:,1)) - min(points3D_filtered(:,1));
yRange = max(points3D_filtered(:,2)) - min(points3D_filtered(:,2));
zRange = max(points3D_filtered(:,3)) - min(points3D_filtered(:,3));

% Make x and y axes 3x larger relative to their data range
xlim([min(points3D_filtered(:,1)) - xRange, max(points3D_filtered(:,1)) + xRange]);
ylim([min(points3D_filtered(:,2)) - yRange, max(points3D_filtered(:,2)) + yRange]);
zlim([min(points3D_filtered(:,3)), max(points3D_filtered(:,3))]);

% Set viewing angle
view(45, 30);

% Add colorbar if grayscale
if size(im1, 3) == 1
    colorbar;
    colormap gray;
end

fprintf('\n3D reconstruction complete!\n');
fprintf('Point cloud statistics:\n');
fprintf('  X range: [%.2f, %.2f] mm\n', min(points3D_filtered(:,1)), max(points3D_filtered(:,1)));
fprintf('  Y range: [%.2f, %.2f] mm\n', min(points3D_filtered(:,2)), max(points3D_filtered(:,2)));
fprintf('  Z range: [%.2f, %.2f] mm\n', min(points3D_filtered(:,3)), max(points3D_filtered(:,3)));

%% Step 9: Additional visualization - Top view
figure('Name', '3D Reconstruction - Top View');
scatter3(points3D_filtered(:, 1), points3D_filtered(:, 2), points3D_filtered(:, 3), ...
    10, colors, 'filled');
xlabel('X (mm)');
ylabel('Y (mm)');
zlabel('Z (mm)');
title('3D Reconstruction - Top View');
grid on;

% Set custom axis limits
xlim([min(points3D_filtered(:,1)) - xRange, max(points3D_filtered(:,1)) + xRange]);
ylim([min(points3D_filtered(:,2)) - yRange, max(points3D_filtered(:,2)) + yRange]);
zlim([min(points3D_filtered(:,3)), max(points3D_filtered(:,3))]);

view(0, 90);  % Top view

%% Step 10: Side view
figure('Name', '3D Reconstruction - Side View');
scatter3(points3D_filtered(:, 1), points3D_filtered(:, 2), points3D_filtered(:, 3), ...
    10, colors, 'filled');
xlabel('X (mm)');
ylabel('Y (mm)');
zlabel('Z (mm)');
title('3D Reconstruction - Side View');
grid on;

% Set custom axis limits
xlim([min(points3D_filtered(:,1)) - xRange, max(points3D_filtered(:,1)) + xRange]);
ylim([min(points3D_filtered(:,2)) - yRange, max(points3D_filtered(:,2)) + yRange]);
zlim([min(points3D_filtered(:,3)), max(points3D_filtered(:,3))]);

view(90, 0);  % Side view

% Return to original directory
cd('..');
