%% Code to Generate a Panorama from Multiple Images
% This script implements a panoramic image stitching pipeline that:
% - Reads multiple images from a sequence
% - Detects and matches feature points between adjacent images
% - Estimates homographies using RANSAC
% - Warps images to a common reference frame
% - Composites them into a single panoramic image
%
% ASSIGNMENT REQUIREMENTS:
%
% 1. IMAGE SEQUENCE ACQUISITION
%    - Obtain an image sequence where the camera projection center does not
%      change (or changes minimally) during the entire sequence
%    - Adjacent pairs of images must significantly overlap each other
%    - You may use provided sequences or capture your own images
%    - Required: Test on at least one self-captured image set
%    - Minimum: Mosaic at least 4 images together per data set
%    - Apply method to at least 3 different sequences
%    - All results must be reproducible
%
% 2. FEATURE POINT CORRESPONDENCE
%    - Use a feature point correspondence algorithm (e.g., SIFT with RANSAC)
%      to automatically track point correspondences
%    - Set number of features to track as appropriate (e.g., 100 features)
%    - Document and justify any parameter changes from default settings
%    - Run the algorithm on your image sequence to create point correspondences
%    - Note: Manual point correspondence is also allowed but tedious
%
% 3. HOMOGRAPHY COMPUTATION
%    - Compute the infinite homography between each pair of adjacent frames
%    - Implement forward or backward homography mapping for each candidate
%      set of point correspondences
%    - Use RANSAC to ensure best fit in the presence of outliers (when using SIFT)
%    - Reference: Normalized GOLD standard algorithm and robust version
%      using RANSAC (see textbook)
%
% 4. IMAGE WARPING
%    - Warp each image via the infinite homography associated with one reference
%      frame (ideally one in the middle of the sequence)
%    - Use backward mapping method with bilinear interpolation for pixel resampling
%    - Note: MATLAB image transformation functions are allowed, or use functions
%      from Assignment 2
%
% 5. IMAGE COMPOSITING
%    - Composite all images into a single panoramic image
%    - Optional: Implement feathering algorithm using bilinear weighting function
%      for all pixels contributing at a given point
%    - Reference: Equation (9) in Szeliski, R. "Video mosaics for virtual 
%      environments," IEEE Computer Graphics and Applications 16(2), 22-30, 1996
%    - Feathering reduces noticeable seams in the result image

%% Clear workspace and close figures
clear;
close all;
clc;

%% Configuration Parameters
% Adjust these parameters based on your image sequence
% Get the directory where this script is located
scriptDir = fileparts(mfilename('fullpath'));
imageFolder = fullfile(scriptDir, 'images/');  % Folder containing your image sequence
imagePrefix = 'img';       % Prefix for image filenames
imageExt = '.jpg';         % Image file extension
numImages = 4;             % Number of images to stitch (minimum 4)
referenceIdx = 2;          % Index of reference image (ideally in the middle)

% Feature detection and matching parameters
numFeatures = 1000;        % Number of SURF/SIFT features to detect (increased)
matchThreshold = 20.0;     % Matching threshold (higher = more matches, less strict)
maxRatio = 0.8;            % Lowe's ratio test threshold (higher = more permissive)

% RANSAC parameters
confidence = 90.0;         % RANSAC confidence level (%) - reduced for more flexibility
maxDistance = 5.0;         % Maximum distance for inliers (pixels) - increased tolerance

%% Step 1: Load Images
fprintf('=== Loading Images ===\n');
images = cell(1, numImages);
for i = 1:numImages
    % Construct filename (adjust naming pattern as needed)
    filename = sprintf('%s%s%d%s', imageFolder, imagePrefix, i, imageExt);
    
    % Check if file exists
    if ~exist(filename, 'file')
        error('Image file not found: %s', filename);
    end
    
    % Read image
    images{i} = imread(filename);
    fprintf('Loaded image %d: %s (size: %dx%d)\n', i, filename, ...
        size(images{i}, 1), size(images{i}, 2));
end

%% Step 2: Detect and Match Features Between Adjacent Images
fprintf('\n=== Detecting and Matching Features ===\n');

% Store homographies between adjacent images
homographies = cell(1, numImages-1);

for i = 1:numImages-1
    fprintf('\nProcessing pair: Image %d -> Image %d\n', i, i+1);
    
    % Convert images to grayscale if needed
    if size(images{i}, 3) == 3
        img1_gray = rgb2gray(images{i});
    else
        img1_gray = images{i};
    end
    
    if size(images{i+1}, 3) == 3
        img2_gray = rgb2gray(images{i+1});
    else
        img2_gray = images{i+1};
    end
    
    % Detect SURF features (or SIFT if available)
    points1 = detectSURFFeatures(img1_gray);
    points2 = detectSURFFeatures(img2_gray);
    
    % Select strongest features
    points1 = points1.selectStrongest(numFeatures);
    points2 = points2.selectStrongest(numFeatures);
    
    fprintf('  Detected %d features in image %d\n', length(points1), i);
    fprintf('  Detected %d features in image %d\n', length(points2), i+1);
    
    % Extract feature descriptors
    [features1, valid_points1] = extractFeatures(img1_gray, points1);
    [features2, valid_points2] = extractFeatures(img2_gray, points2);
    
    % Match features using Lowe's ratio test
    indexPairs = matchFeatures(features1, features2, 'MaxRatio', maxRatio, ...
        'MatchThreshold', matchThreshold);
    
    fprintf('  Found %d putative matches\n', size(indexPairs, 1));
    
    % Retrieve matched points
    matchedPoints1 = valid_points1(indexPairs(:, 1), :);
    matchedPoints2 = valid_points2(indexPairs(:, 2), :);
    
    % Check if we have enough matches
    if size(indexPairs, 1) < 4
        fprintf('  ERROR: Not enough matches (%d found, need at least 4)\n', size(indexPairs, 1));
        fprintf('  Try: 1) Ensure images overlap significantly (30-50%%)\n');
        fprintf('       2) Increase matchThreshold (currently %.2f)\n', matchThreshold);
        fprintf('       3) Increase maxRatio (currently %.2f)\n', maxRatio);
        error('Cannot compute homography with fewer than 4 matches.');
    end
    
    % Estimate homography using RANSAC
    try
        [tform, inlierIdx] = estimateGeometricTransform(matchedPoints1, matchedPoints2, ...
            'projective', 'Confidence', confidence, 'MaxDistance', maxDistance, ...
            'MaxNumTrials', 5000);
        
        % Check if RANSAC succeeded
        if isempty(tform)
            error('RANSAC failed to find a valid homography');
        end
        
        % Handle different return types for inlierIdx
        if islogical(inlierIdx)
            numInliers = sum(inlierIdx);
        elseif isnumeric(inlierIdx)
            numInliers = length(inlierIdx);
            % Convert indices to logical array
            temp = false(size(matchedPoints1, 1), 1);
            temp(inlierIdx) = true;
            inlierIdx = temp;
        else
            error('Unexpected inlierIdx type: %s', class(inlierIdx));
        end
        
        if numInliers < 4
            error('Too few inliers (%d found, need at least 4)', numInliers);
        end
        
        % Extract homography matrix from transform object
        homographies{i} = tform.T';  % Transpose for correct format
        
        fprintf('  RANSAC found %d inliers out of %d matches (%.1f%%)\n', ...
            numInliers, length(inlierIdx), 100*numInliers/length(inlierIdx));
    catch ME
        fprintf('  ERROR: Failed to estimate homography between images %d and %d\n', i, i+1);
        fprintf('  Reason: %s\n', ME.message);
        fprintf('\n  TROUBLESHOOTING:\n');
        fprintf('  1) Ensure images overlap significantly (30-50%%)\n');
        fprintf('  2) Camera should only ROTATE, not move sideways\n');
        fprintf('  3) Try increasing maxDistance to 5.0 or higher\n');
        fprintf('  4) Try decreasing confidence to 90.0 or lower\n');
        fprintf('  5) Check that images are in correct order (left to right)\n');
        fprintf('  6) Verify images are not too blurry or low quality\n');
        error('Cannot proceed without valid homography. Please check your images.');
    end
    
    % Visualize matches (optional - set to true to debug matching issues)
    if true  % Enable to see feature matches
        figure('Name', sprintf('Matches: Image %d to %d', i, i+1));
        showMatchedFeatures(images{i}, images{i+1}, ...
            matchedPoints1(inlierIdx), matchedPoints2(inlierIdx), 'montage');
        title(sprintf('Matched Features: Image %d to Image %d (%d inliers)', i, i+1, numInliers));
        drawnow;
    end
end

%% Step 3: Compute Cumulative Homographies Relative to Reference Image
fprintf('\n=== Computing Cumulative Homographies ===\n');

% Initialize cumulative homographies
cumulativeH = cell(1, numImages);
cumulativeH{referenceIdx} = eye(3);  % Reference image has identity transform

% Compute homographies for images to the right of reference
for i = referenceIdx+1:numImages
    cumulativeH{i} = cumulativeH{i-1} * homographies{i-1};
    fprintf('Homography for image %d relative to reference:\n', i);
    disp(cumulativeH{i});
end

% Compute homographies for images to the left of reference
for i = referenceIdx-1:-1:1
    % Use inverse of homography from i to i+1
    % Solve: homographies{i} * cumulativeH{i} = cumulativeH{i+1}
    cumulativeH{i} = homographies{i} \ cumulativeH{i+1};
    fprintf('Homography for image %d relative to reference:\n', i);
    disp(cumulativeH{i});
end

%% Step 4: Warp All Images to Reference Frame and Composite
fprintf('\n=== Warping All Images to Reference Frame ===\n');

% First, determine the size of the output panorama by finding bounds
% of all transformed images
minX = inf; maxX = -inf;
minY = inf; maxY = -inf;

for i = 1:numImages
    if i == referenceIdx
        % Reference image bounds
        minX = min(minX, 1);
        maxX = max(maxX, size(images{i}, 2));
        minY = min(minY, 1);
        maxY = max(maxY, size(images{i}, 1));
    else
        % Get bounds for transformed image
        tform = projective2d(cumulativeH{i});
        [~, xdata, ydata] = outputLimits(tform, [1 size(images{i},2)], [1 size(images{i},1)]);
        minX = min(minX, xdata(1));
        maxX = max(maxX, xdata(2));
        minY = min(minY, ydata(1));
        maxY = max(maxY, ydata(2));
    end
end

fprintf('Panorama bounds: X[%.2f, %.2f], Y[%.2f, %.2f]\n', minX, maxX, minY, maxY);

% Create output view for the entire panorama
width = round(maxX - minX);
height = round(maxY - minY);
xLimits = [minX, maxX];
yLimits = [minY, maxY];
panoramaView = imref2d([height, width], xLimits, yLimits);

fprintf('Panorama size: %dx%d pixels\n', height, width);

%% Warp all images and composite
fprintf('\n=== Compositing Panorama ===\n');

% Initialize panorama as double for blending
panorama = zeros(height, width, size(images{1}, 3), 'double');
weightMap = zeros(height, width, 'double');

for i = 1:numImages
    fprintf('Processing image %d...\n', i);
    
    img_double = im2double(images{i});
    
    if i == referenceIdx
        % Reference image: apply translation to account for panorama offset
        xOffset = 1 - minX;
        yOffset = 1 - minY;
        tform = affine2d([1 0 0; 0 1 0; xOffset yOffset 1]);
        warpedImg = imwarp(img_double, tform, 'OutputView', panoramaView);
    else
        % Other images: apply cumulative homography
        tform = projective2d(cumulativeH{i});
        warpedImg = imwarp(img_double, tform, 'OutputView', panoramaView);
    end
    
    % Create mask for this image
    mask = any(warpedImg > 1e-6, 3);
    
    % Accumulate using simple averaging (can be improved with feathering)
    for c = 1:size(panorama, 3)
        panorama(:,:,c) = panorama(:,:,c) + warpedImg(:,:,c) .* double(mask);
    end
    weightMap = weightMap + double(mask);
end

% Normalize by weight map to get average
for c = 1:size(panorama, 3)
    panorama(:,:,c) = panorama(:,:,c) ./ max(weightMap, 1);
end

% Convert back to uint8 for display/saving
panorama = im2uint8(panorama);

%% Step 5: Display and Save Result
fprintf('\n=== Displaying Result ===\n');
figure('Name', 'Panorama Result', 'NumberTitle', 'off');
imshow(panorama);
title(sprintf('Panorama from %d Images', numImages));

% Save result
outputFilename = sprintf('panorama_%d_images.jpg', numImages);
imwrite(panorama, outputFilename);
fprintf('Panorama saved as: %s\n', outputFilename);
fprintf('Panorama size: %dx%d\n', size(panorama, 1), size(panorama, 2));

fprintf('\n=== Panorama Generation Complete ===\n');