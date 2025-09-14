function outim = TransformImage(im, H)
% This function takes as input an image im and a 3x3 homography H to return
% the transformed image outim
%

% Matlab function imtransform assumes transpose of H as input
tform = maketform('projective',H');
% Next line returns the x and y coordinates of the bounding box of the 
% transformed image through H
[boxx, boxy]=tformfwd(tform, [1 1 size(im,2) size(im,2)], [1 size(im,1) 1 size(im,1)]);
% Find the minimum and maximum x and y coordinates of the bounding box
minx=min(boxx); maxx=max(boxx);
miny=min(boxy); maxy=max(boxy);
% Transform the input image
outim =imtransform(im,tform,'XData',[minx maxx],'YData',[miny maxy],'Size',[size(im,1),round(size(im,1)*(maxx-minx)/(maxy-miny))]);

end