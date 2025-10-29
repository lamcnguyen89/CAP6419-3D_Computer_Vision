%% warp - Apply cylindrical projection to an image
%
% DESCRIPTION:
%   Transforms an image to cylindrical coordinates. This is essential for
%   panorama stitching when the camera rotates around its optical center.
%   The cylindrical projection "unwraps" the scene onto a cylinder, making
%   it easier to align images taken from a rotating camera.
%
% INPUTS:
%   i - Input image (grayscale or color, any size)
%   f - Focal length in pixels (affects the curvature of the projection)
%
% OUTPUTS:
%   output - Cylindrically warped image (same size as input)
%
% ALGORITHM:
%   For each pixel in the cylindrical image:
%   1. Map cylindrical coordinates back to planar coordinates:
%      x_planar = f * tan(x_cylindrical / f)
%      y_planar = y_cylindrical * sqrt(x_cylindrical^2 + f^2) / f
%   2. Sample the original image at these planar coordinates
%   3. Place the sampled value in the cylindrical image
%
% MATHEMATICAL BACKGROUND:
%   Cylindrical projection formulas:
%   - Horizontal: x' = f * arctan(x/f)  [wraps horizontally around cylinder]
%   - Vertical:   y' = f * y / sqrt(x^2 + f^2)  [adjusts vertical stretch]
%   where (x,y) are centered coordinates and f is focal length
%
function [output]=warp(i,f)
    % Initialize output image with same size and type as input
    output=zeros(size(i),'like',i);
    
    % Determine number of color channels (1=grayscale, 3=RGB)
    if length(size(i))==2
        Layers=1;
    else
        Layers=size(i,3);
    end
    
    % Process each color channel independently
    for layer=1:Layers
        % Calculate image center (origin for cylindrical projection)
        x_center=size(i,2)/2;
        y_center=size(i,1)/2;
        
        % Create coordinate grids centered at image center
        x=(1:size(i,2))-x_center;  % Horizontal coordinates (centered)
        y=(1:size(i,1))-y_center;  % Vertical coordinates (centered)
        [xx,yy]=meshgrid(x,y);
        
        % Apply inverse cylindrical projection (cylindrical -> planar)
        % This maps where each output pixel should sample from input
        yy=f*yy./sqrt(xx.^2+double(f)^2)+y_center;  % Vertical mapping
        xx=f*atan(xx/double(f))+x_center;           % Horizontal mapping
        
        % Round to nearest integer pixel coordinates
        xx=floor(xx+.5);
        yy=floor(yy+.5);

        % Convert 2D coordinates to linear indices for array access
        idx=sub2ind([size(i,1),size(i,2)], yy, xx);
      
        % Create cylindrical image by resampling original image
        cylinder=zeros(size(i,1),size(i,2),'like',i);
        cylinder(idx)=i(:,:,layer);  % Place original pixels at cylindrical positions

        output(:,:,layer)=cylinder;
    end
end