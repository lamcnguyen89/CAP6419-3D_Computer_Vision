%% create - Main panorama creation function
%
% DESCRIPTION:
%   Orchestrates the complete panorama creation pipeline. Takes a sequence of
%   planar images and produces a single panoramic image by:
%   1. Cylindrical warping (for rotation-only camera motion)
%   2. Feature detection and matching (SIFT + RANSAC)
%   3. Computing cumulative transformations
%   4. Handling end-to-end drift for 360° panoramas
%   5. Blending images with alpha feathering
%
% INPUTS:
%   imgs - 4D array of input images (height x width x channels x numImages)
%   f - Focal length in pixels (controls cylindrical projection curvature)
%   full360 - Boolean flag (1 if creating a 360° panorama, 0 otherwise)
%
% OUTPUTS:
%   newImg - Final panoramic image
%
% PIPELINE STAGES:
%   Stage 1: Cylindrical Warping - Transform images to cylindrical coordinates
%   Stage 2: Feature Matching - Find correspondences between adjacent images
%   Stage 3: Alignment - Compute cumulative transformations
%   Stage 4: Drift Correction - For 360° panoramas, distribute accumulated error
%   Stage 5: Blending - Merge images with smooth transitions
%
% TIMING:
%   The function prints execution time for each major stage to help identify
%   performance bottlenecks.
%
function [ newImg ] = create( imgs, f, full360)

%% Handle 360° panoramas by duplicating first image at end
% This allows the last image to align with the first, closing the loop
if full360
    imgs(:, :, :, end + 1) = imgs(:, :, :, 1);
end

nImgs = size(imgs, 4);  % Number of images in sequence

%% Stage 1: Apply cylindrical warping to all images
% This "unwraps" images taken from a rotating camera onto a cylinder
cylindricalimages = zeros(size(imgs), 'like', imgs);

t=cputime;
for i = 1 : nImgs
    cylindricalimages(:, :, :, i) = warp(imgs(:, :, :, i), f);
end
disp(['warping:',int2str(cputime-t),' sec']);

%% Stage 2: Compute pairwise translations between adjacent images
% Uses SIFT feature detection + RANSAC for robust matching
t=cputime;
translations = computeTrans(cylindricalimages);
disp(['SIFT & RANSAC: ',int2str(cputime-t),' sec']);

%% Stage 3: Compute cumulative transformations relative to first image
% Chain together pairwise translations: T_total = T1 * T2 * T3 * ...
t=cputime;
absoluteTrans = zeros(size(translations));
absoluteTrans(:, :, 1) = translations(:, :, 1);  % First image is reference (identity)

for i = 2 : nImgs
    % Multiply previous cumulative transform by current pairwise transform
    absoluteTrans(:, :, i) = absoluteTrans(:, :, i - 1) * translations(:, :, i);
end

%% Stage 4: Compute panorama dimensions and handle drift correction
width = size(cylindricalimages, 2);
height = size(cylindricalimages, 1);

if full360
    %% 360° Panorama: Correct end-to-end drift
    % When stitching a full circle, the last image should align with first
    % Any accumulated error (drift) must be distributed across all images
    
    panorama_w = abs(round(absoluteTrans(2, 3, end))) + width;
    
    % Compute drift slope (vertical drift per horizontal pixel)
    % This represents how much the panorama "curves" vertically
    driftSlope = absoluteTrans(1, 3, end) / absoluteTrans(2, 3, end);
    
    panorama_h = height;
    
    % Shift all images if ending position is negative
    if absoluteTrans(2, 3, end) < 0
        absoluteTrans(2, 3, :) = absoluteTrans(2, 3, :) - absoluteTrans(2, 3, end);
        absoluteTrans(1, 3, :) = absoluteTrans(1, 3, :) - absoluteTrans(1, 3, end);
    end
    
    % Create drift correction matrix to gradually adjust vertical position
    % This distributes the vertical error evenly across the panorama
    driftMatrix = [1 -driftSlope driftSlope; 0 1 0; 0 0 1];
    for i = 1 : nImgs
        absoluteTrans(:, :, i) = driftMatrix * absoluteTrans(:, :, i);
    end
else
    %% Standard Panorama: Compute bounding box for all images
    % Find minimum and maximum extents to determine canvas size
    
    maxY = height;
    minY = 1;
    minX = 1;
    maxX = width;
    
    % Check position of each image after transformation
    for i = 2 : nImgs 
        maxY = max(maxY, absoluteTrans(1,3,i)+height);  % Bottom edge
        maxX = max(maxX, absoluteTrans(2,3,i)+width);   % Right edge
        minY = min(minY, absoluteTrans(1,3,i));         % Top edge
        minX = min(minX, absoluteTrans(2,3,i));         % Left edge
    end
    
    % Calculate canvas size to fit all images
    panorama_h = ceil(maxY) - floor(minY) + 1;
    panorama_w = ceil(maxX) - floor(minX) + 1;
    
    % Adjust transformations to account for canvas offset
    % This ensures all images fit within positive coordinates
    absoluteTrans(2, 3, :) = absoluteTrans(2, 3, :) - floor(minX);
    absoluteTrans(1, 3, :) = absoluteTrans(1, 3, :) - floor(minY);
end

disp(['end2end alignment:',int2str(cputime-t),' sec']);

%% Stage 5: Merge all images into final panorama using alpha blending
t=cputime;
newImg = merge(cylindricalimages, absoluteTrans , panorama_h, panorama_w, f);
disp(['alpha merging:',int2str(cputime-t),' sec']);

end

