%% computeTrans - Compute pairwise translation transformations between adjacent images
%
% DESCRIPTION:
%   This function computes the translation (shift) between each pair of adjacent
%   cylindrically-warped images. It uses SIFT feature detection and RANSAC to
%   robustly estimate the 2D translation that aligns consecutive images.
%
% INPUTS:
%   imgs - 4D array of cylindrically warped images (height x width x channels x numImages)
%
% OUTPUTS:
%   T - 3x3xN array of transformation matrices, where T(:,:,i) represents the
%       translation from image i-1 to image i. T(:,:,1) is identity matrix.
%
% ALGORITHM:
%   1. Extract SIFT features from each image
%   2. Match features between adjacent image pairs
%   3. Use RANSAC to robustly estimate translation, filtering outliers
%   4. Return translation matrices in homogeneous coordinates
%
% PARAMETERS:
%   Thresh - Edge threshold for SIFT detection (10 = detect more features)
%   confidence - RANSAC confidence level (0.99 = 99% probability of success)
%   inlierRatio - Expected ratio of inliers to total matches (0.3 = 30%)
%   epsilon - Distance threshold for inliers in pixels (1.5 pixels)
%
function [ T ] = computeTrans( imgs )
Thresh = 10;           % SIFT edge threshold (lower = more features detected)
confidence = 0.99;     % RANSAC confidence (probability of finding good model)
inlierRatio = 0.3;     % Expected percentage of correct matches
epsilon = 1.5;         % Maximum error for a match to be considered an inlier

nImgs = size(imgs, 4); % Number of images in the sequence

% Initialize transformation matrices
T = zeros(3, 3, nImgs);
T(:, :, 1) = eye(3);   % First image has identity transform (reference)

% Extract SIFT features from first image
[f2, d2] = getSIFTFeatures(imgs(:, :, :, 1), Thresh);

% Process each adjacent pair of images
for i = 2 : nImgs
    % Shift features: previous image becomes current reference
    f1 = f2;
    d1 = d2;
    
    % Extract SIFT features from next image
    [f2, d2] = getSIFTFeatures(imgs(:, :, :, i), Thresh);
    
    % Find matching feature points between the two images
    [matches, ~] = getMatches(f1, d1, f2, d2);
    
    % Use RANSAC to robustly estimate translation from matches
    % Npairs=1 means we only need 1 point pair to compute a translation
    [T(:, :, i),~] = RANSAC(confidence, inlierRatio, 1, matches, epsilon);
end
end

