%% merge - Blend multiple cylindrical images into a single panorama
%
% DESCRIPTION:
%   Combines multiple cylindrically-warped images into a single panoramic image
%   using distance-based alpha blending (feathering). This function places each
%   image at its computed position and smoothly blends overlapping regions to
%   minimize visible seams.
%
% INPUTS:
%   imgs - 4D array of cylindrically warped images (height x width x channels x numImages)
%   transforms - 3x3xN array of transformation matrices specifying where to place each image
%   newHeight - Height of the output panorama canvas
%   newWidth - Width of the output panorama canvas
%   f - Focal length (used for computing blending weights)
%
% OUTPUTS:
%   newImg - Final panoramic image (newHeight x newWidth x channels)
%
% ALGORITHM:
%   1. Create distance-based weight mask (pixels near image center get higher weight)
%   2. Compute bounds to center the panorama properly
%   3. Place each image at its transformed position
%   4. Blend overlapping regions using weighted averaging
%   5. Normalize by accumulated weights to get final pixel values
%
% BLENDING STRATEGY:
%   Uses distance transform to create smooth alpha blending weights:
%   - Pixels near the center of each image get full weight (1.0)
%   - Pixels near the edges get lower weights (approaching 0)
%   - In overlap regions, contributions are weighted by distance from edge
%   - This creates seamless transitions and reduces visible seams
%
function [ newImg ] = merge( imgs, transforms, newHeight, newWidth ,f)

% Convert to double precision for accurate blending calculations
imgs=im2double(imgs);

height = size(imgs, 1);      % Height of individual images
width = size(imgs, 2);       % Width of individual images
nChannels = size(imgs, 3);   % Number of color channels (3 for RGB)
nImgs = size(imgs, 4);       % Number of images to merge

%% Create distance-based blending weight mask
% This mask gives higher weight to pixels near image center, lower near edges
mask = ones(height, width);
mask = warp(mask, f);                    % Apply cylindrical warp to mask
mask = imcomplement(mask);               % Invert so edges are black
mask = bwdist(mask, 'euclidean');        % Distance transform (distance to nearest edge)

% Normalize mask so maximum value is 1.0
mask = mask ./ max(max(mask));

% Replicate mask across all color channels
m=ones([height,width,nChannels],'like',imgs);
for i=1:nChannels
    m(:,:,i)=mask;
end
mask=m;

%% Compute bounds of transformed images to properly center panorama
% Find the minimum and maximum extents of all transformed images
max_h=0;
min_h=0;
max_w=0;
min_w=0;
for i=1:nImgs
    % Transform corner point [1,1,1] to find image position
    p_prime=transforms(:,:,i)*[1;1;1];
    p_prime=p_prime./p_prime(3);        % Convert from homogeneous coordinates
    base_h=floor(p_prime(1));           % Vertical position
    base_w=floor(p_prime(2));           % Horizontal position
    
    % Update bounding box
    if base_h>max_h
        max_h=base_h;
    end
    if base_h<min_h
        min_h=bash_h;  % Note: This appears to be a typo (should be base_h)
    end
    if base_w>max_w
        max_w=base_w;
    end
    if base_w<min_w
        min_w=base_w;
    end
end

%% Initialize output panorama and weight accumulator
% Add padding to handle edge cases
newImg = zeros([newHeight+20,newWidth+20,nChannels], 'like',imgs);
denominator = zeros([newHeight+20,newWidth+20,nChannels], 'like',imgs);

%% Place and blend each image into the panorama
for i=1:nImgs
    % Compute position for this image (with offset to center panorama)
    p_prime=transforms(:,:,i)*[min_h+10;min_w+10;1];
    p_prime=p_prime./p_prime(3);        % Convert from homogeneous coordinates
    base_h=floor(p_prime(1));           % Starting row
    base_w=floor(p_prime(2));           % Starting column
    
    % Ensure indices are valid (minimum of 1)
    if base_h==0
        base_h=1;
    end
    if base_w==0
        base_w=1;
    end

    % Accumulate weighted image contribution
    % Multiply image by its mask (higher weight in center, lower at edges)
    newImg(base_h:base_h+height-1,base_w:base_w+width-1,:)=...
        newImg(base_h:base_h+height-1,base_w:base_w+width-1,:)+...
        imgs(:,:,:,i).*mask;
    
    % Accumulate weights (for normalization)
    denominator(base_h:base_h+height-1,base_w:base_w+width-1,:)=...
        denominator(base_h:base_h+height-1,base_w:base_w+width-1,:)+...
        mask;
end

%% Normalize by accumulated weights to get final pixel values
% This performs weighted average: final_pixel = sum(weighted_pixels) / sum(weights)
newImg=newImg./denominator;

end
