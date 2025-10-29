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

clear; clc; close all;

%% Automatically find and process all image folders
imgs_path = 'imagesets';

% Get all subdirectories in the imagesets folder
imgsFolderContents = dir(imgs_path);
imgsFolderContents = imgsFolderContents([imgsFolderContents.isdir]); % Keep only directories
imgsFolderContents = imgsFolderContents(~ismember({imgsFolderContents.name},{'.','..'})); % Remove . and ..

numDatasets = length(imgsFolderContents);
fprintf('Found %d image folders in "%s" directory:\n', numDatasets, imgs_path);
for i = 1:numDatasets
    fprintf('  %d. %s\n', i, imgsFolderContents(i).name);
end
fprintf('\n');

% Process each dataset
for i = 1:numDatasets
    try
        fprintf('========================================\n');
        fprintf('Processing dataset %d of %d: %s\n', i, numDatasets, imgsFolderContents(i).name);
        fprintf('========================================\n');
        
        panorama = main(i);
        
        figure('Name', sprintf('Panorama %d: %s', i, imgsFolderContents(i).name));
        imshow(panorama);
        title(sprintf('%s', imgsFolderContents(i).name), 'Interpreter', 'none');
        
        fprintf('Successfully created panorama for %s\n\n', imgsFolderContents(i).name);
    catch ME
        fprintf('ERROR processing %s:\n', imgsFolderContents(i).name);
        fprintf('  %s\n\n', ME.message);
        % Continue to next dataset instead of stopping
        continue;
    end
end

fprintf('========================================\n');
fprintf('Completed processing all datasets\n');
fprintf('========================================\n');