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
for i=1:11
    panorama=main(i);
    figure
    imshow(panorama);
end