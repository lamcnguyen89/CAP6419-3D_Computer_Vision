%% getSIFTFeatures - Extract SIFT feature points and descriptors from an image
%
% DESCRIPTION:
%   Uses the VLFeat library to detect Scale-Invariant Feature Transform (SIFT)
%   keypoints in an image and compute their descriptors. SIFT features are
%   robust to rotation, scale changes, and illumination variations, making
%   them ideal for image matching in panorama stitching.
%
% INPUTS:
%   image - Input image (can be RGB or grayscale)
%   edgeThresh - Edge threshold parameter for SIFT detection
%                Lower values detect more features (including edge-like features)
%                Higher values detect fewer, more corner-like features
%                Typical range: 5-10 (default in VLFeat is 10)
%
% OUTPUTS:
%   f - 4xN array of feature locations and properties:
%       f(1,:) = x-coordinate of feature center
%       f(2,:) = y-coordinate of feature center
%       f(3,:) = scale (sigma) of the feature
%       f(4,:) = orientation (angle in radians)
%   d - 128xN array of SIFT descriptors (one 128-dimensional descriptor per feature)
%       Each descriptor is a normalized histogram of gradient orientations
%
% NOTES:
%   - Requires VLFeat library to be installed and in MATLAB path
%   - SIFT features are detected at multiple scales and orientations
%   - Descriptors are normalized to be invariant to illumination changes
%
function [f, d] = getSIFTFeatures(image, edgeThresh)

% Convert RGB images to grayscale (SIFT operates on intensity images)
if (size(image, 3) == 3)
    Im = single(rgb2gray(image));
else
    Im = single(image);
end

% Extract SIFT features and descriptors using VLFeat library
% 'EdgeThresh' controls the sensitivity to edge-like features
% Lower threshold = more features detected (including edges)
% Higher threshold = fewer features detected (mostly corners)
[f, d] = vl_sift(Im, 'EdgeThresh', edgeThresh);

end