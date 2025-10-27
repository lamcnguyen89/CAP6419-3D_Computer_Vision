function outim = TransformImage(im, H)
% This function takes as input an image im and a 3x3 homography H to return
% the transformed image outim
%

% Modern MATLAB uses projective2d instead of maketform
tform = projective2d(H);
% Get the output limits of the transformed image
[xlim, ylim] = outputLimits(tform, [1 size(im,2)], [1 size(im,1)]);
% Find the minimum and maximum x and y coordinates of the bounding box
minx = xlim(1); maxx = xlim(2);
miny = ylim(1); maxy = ylim(2);
% Create output reference object
width = round(size(im,1)*(maxx-minx)/(maxy-miny));
height = size(im,1);
Rout = imref2d([height width], [minx maxx], [miny maxy]);
% Transform the input image using imwarp
outim = imwarp(im, tform, 'OutputView', Rout);

end