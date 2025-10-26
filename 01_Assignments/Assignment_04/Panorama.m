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
clear all;
close all;
clc;

%% Configuration Parameters
% Adjust these parameters based on your image sequence
imageFolder = 'images/';  % Folder containing your image sequence
imagePrefix = 'img';       % Prefix for image filenames
imageExt = '.jpg';         % Image file extension
numImages = 4;             % Number of images to stitch (minimum 4)
referenceIdx = 2;          % Index of reference image (ideally in the middle)

% Feature detection and matching parameters
numFeatures = 500;         % Number of SURF/SIFT features to detect
matchThreshold = 10.0;     % Matching threshold (lower = more strict)
maxRatio = 0.7;            % Lowe's ratio test threshold

% RANSAC parameters
confidence = 99.9;         % RANSAC confidence level (%)
maxDistance = 1.5;         % Maximum distance for inliers (pixels)

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
    
    % Estimate homography using RANSAC
    [H, inlierIdx] = estimateGeometricTransform(matchedPoints1, matchedPoints2, ...
        'projective', 'Confidence', confidence, 'MaxDistance', maxDistance);
    
    homographies{i} = H.T';  % Store transposed homography matrix
    
    fprintf('  RANSAC found %d inliers out of %d matches\n', ...
        sum(inlierIdx), length(inlierIdx));
    
    % Visualize matches (optional)
    if false  % Set to true to visualize matches
        figure;
        showMatchedFeatures(images{i}, images{i+1}, ...
            matchedPoints1(inlierIdx), matchedPoints2(inlierIdx), 'montage');
        title(sprintf('Matched Features: Image %d to Image %d', i, i+1));
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
    H_inv = inv(homographies{i});
    cumulativeH{i} = cumulativeH{i+1} * H_inv;
    fprintf('Homography for image %d relative to reference:\n', i);
    disp(cumulativeH{i});
end

%% Step 4: Stitch Images Together
fprintf('\n=== Stitching Images ===\n');

% Start with the reference image
panorama = images{referenceIdx};
fprintf('Starting with reference image %d\n', referenceIdx);

% Stitch images to the right of reference
for i = referenceIdx+1:numImages
    fprintf('Stitching image %d...\n', i);
    H_relative = cumulativeH{i} * inv(cumulativeH{referenceIdx});
    panorama = stitch2images(images{i}, panorama, H_relative);
end

% Stitch images to the left of reference
for i = referenceIdx-1:-1:1
    fprintf('Stitching image %d...\n', i);
    H_relative = cumulativeH{i} * inv(cumulativeH{referenceIdx});
    panorama = stitch2images(images{i}, panorama, H_relative);
end

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