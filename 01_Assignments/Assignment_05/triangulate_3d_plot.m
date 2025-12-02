% 3D Reconstruction using MATLAB's triangulate function
% This script loads two images and their calibration data, then creates
% a 3D scatter plot of triangulated points

clear; clc; close all;

% Load calibration data and images
run('Input_Images/calib.m');

% Display images
figure('Name', 'Input Images');
subplot(1,2,1); imshow(im1); title('Image 1');
subplot(1,2,2); imshow(im2); title('Image 2');

% Convert to grayscale if needed
if size(im1, 3) == 3
    im1_gray = rgb2gray(im1);
else
    im1_gray = im1;
end

if size(im2, 3) == 3
    im2_gray = rgb2gray(im2);
else
    im2_gray = im2;
end

% Detect SURF features in both images
fprintf('Detecting features...\n');
points1 = detectSURFFeatures(im1_gray);
points2 = detectSURFFeatures(im2_gray);

% Extract feature descriptors
[features1, valid_points1] = extractFeatures(im1_gray, points1);
[features2, valid_points2] = extractFeatures(im2_gray, points2);

% Match features between images
fprintf('Matching features...\n');
indexPairs = matchFeatures(features1, features2, 'Unique', true);

% Get matched points
matchedPoints1 = valid_points1(indexPairs(:, 1), :);
matchedPoints2 = valid_points2(indexPairs(:, 2), :);

fprintf('Found %d matched points\n', size(matchedPoints1, 1));

% Visualize matched features
figure('Name', 'Matched Features');
showMatchedFeatures(im1, im2, matchedPoints1, matchedPoints2, 'montage');
title(sprintf('Matched Features (%d pairs)', size(matchedPoints1, 1)));

% Create camera parameters objects
intrinsics1 = cameraIntrinsics([cam1(1,1), cam1(2,2)], ...
                               [cam1(1,3), cam1(2,3)], ...
                               [height, width]);
                               
intrinsics2 = cameraIntrinsics([cam2(1,1), cam2(2,2)], ...
                               [cam2(1,3), cam2(2,3)], ...
                               [height, width]);

% Set up camera poses
% Camera 1 is at the origin
camMatrix1 = cameraMatrix(intrinsics1, eye(3), [0 0 0]);

% Camera 2 is translated along the X-axis by the baseline
% (assuming a stereo rig with horizontal baseline)
R2 = eye(3);  % No rotation
t2 = [baseline, 0, 0];  % Translation by baseline
camMatrix2 = cameraMatrix(intrinsics2, R2, t2);

% Triangulate 3D points using MATLAB's built-in function
fprintf('Triangulating points...\n');
points3D = triangulate(matchedPoints1, matchedPoints2, camMatrix1, camMatrix2);

% Remove points that are too far or have negative depth
valid_idx = points3D(:,3) > 0 & points3D(:,3) < 5000 & ...
            abs(points3D(:,1)) < 5000 & abs(points3D(:,2)) < 5000;
points3D_filtered = points3D(valid_idx, :);
matchedPoints1_filtered = matchedPoints1(valid_idx, :);

fprintf('Triangulated %d valid 3D points\n', size(points3D_filtered, 1));

% Get colors from the first image for visualization
colors = zeros(size(points3D_filtered, 1), 3);
for i = 1:size(points3D_filtered, 1)
    x = round(matchedPoints1_filtered.Location(i, 1));
    y = round(matchedPoints1_filtered.Location(i, 2));
    
    % Ensure coordinates are within image bounds
    x = max(1, min(width, x));
    y = max(1, min(height, y));
    
    if size(im1, 3) == 3
        colors(i, :) = double(im1(y, x, :)) / 255;
    else
        gray_val = double(im1(y, x)) / 255;
        colors(i, :) = [gray_val, gray_val, gray_val];
    end
end

% Create 3D scatter plot
figure('Name', '3D Reconstruction');
scatter3(points3D_filtered(:,1), points3D_filtered(:,2), points3D_filtered(:,3), ...
         10, colors, 'filled');
xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');
title(sprintf('3D Reconstruction (%d points)', size(points3D_filtered, 1)));
grid on;
axis equal;
view(3);
rotate3d on;

% Display statistics
fprintf('\n3D Point Statistics:\n');
fprintf('X range: [%.2f, %.2f] mm\n', min(points3D_filtered(:,1)), max(points3D_filtered(:,1)));
fprintf('Y range: [%.2f, %.2f] mm\n', min(points3D_filtered(:,2)), max(points3D_filtered(:,2)));
fprintf('Z range: [%.2f, %.2f] mm\n', min(points3D_filtered(:,3)), max(points3D_filtered(:,3)));

fprintf('\nScript completed successfully!\n');
