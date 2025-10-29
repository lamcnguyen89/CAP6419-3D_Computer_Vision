%% getMatches - Find matching SIFT features between two images
%
% DESCRIPTION:
%   Matches SIFT feature descriptors between two images using the VLFeat
%   UBC (University of British Columbia) matching algorithm. This function
%   identifies corresponding points between images by comparing their
%   128-dimensional SIFT descriptors.
%
% INPUTS:
%   f1 - 4xN1 array of feature locations from first image (from getSIFTFeatures)
%   d1 - 128xN1 array of SIFT descriptors from first image
%   f2 - 4xN2 array of feature locations from second image
%   d2 - 128xN2 array of SIFT descriptors from second image
%
% OUTPUTS:
%   potential_matches - Nx3x2 array of matched point pairs in homogeneous coordinates:
%                       potential_matches(:,:,1) = [x1, y1, 1] coordinates in image 1
%                       potential_matches(:,:,2) = [x2, y2, 1] coordinates in image 2
%                       Each row represents one matched pair
%   scores - Nx1 array of match quality scores (lower = better match)
%
% ALGORITHM:
%   1. Uses vl_ubcmatch to find nearest neighbor matches between descriptors
%   2. Lowe's ratio test is applied internally (threshold typically ~0.8)
%   3. Converts matched feature indices to (x,y) coordinates
%   4. Formats as homogeneous coordinates [x, y, 1] for transformation matrices
%
% NOTES:
%   - vl_ubcmatch uses Euclidean distance between 128D descriptors
%   - Typically produces 10-1000 matches depending on image overlap and features
%   - Many matches may be outliers, requiring RANSAC for robust estimation
%
function [potential_matches, scores] = getMatches(f1, d1, f2, d2)

% Find matching features using VLFeat's UBC matching algorithm
% Returns indices of matched features and their similarity scores
[matches, scores] = vl_ubcmatch(d1, d2);

% Extract matched feature coordinates and convert to homogeneous form
numMatches = size(matches,2);
pairs = nan(numMatches, 3, 2);

% Extract coordinates for matches in image 1
% Note: f(1,:) is y-coordinate, f(2,:) is x-coordinate in VLFeat format
% We store as [x, y, 1] in homogeneous coordinates
pairs(:,:,1)=[f1(2,matches(1,:));    % x-coordinates from image 1
              f1(1,matches(1,:));    % y-coordinates from image 1
              ones(1,numMatches)]';  % homogeneous coordinate

% Extract coordinates for matches in image 2
pairs(:,:,2)=[f2(2,matches(2,:));    % x-coordinates from image 2
              f2(1,matches(2,:));    % y-coordinates from image 2
              ones(1,numMatches)]';  % homogeneous coordinate

potential_matches = pairs;

end
