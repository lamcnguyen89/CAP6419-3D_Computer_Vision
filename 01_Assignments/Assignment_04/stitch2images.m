function outim = stitch2images(im1, im2, H)
%
% This function stitches together im1 and im2 given the homography H that
% transforms im1 to match im2
%
%

T = maketform('projective',double(H'));
[~, xdata, ydata] = imtransform(im1,T);

Outxdata=[min(1,xdata(1)) max(size(im2,2), xdata(2))];
outydata=[min(1,ydata(1)) max(size(im2,1), ydata(2))];

warpedim1 = imtransform(im1, maketform('projective',double(H')),...
    'XData',Outxdata,'YData',outydata);
warpedim2 = imtransform(im2, maketform('affine',eye(3)),...
    'XData',Outxdata,'YData',outydata);
outim = warpedim1 + warpedim2;
overlap = (warpedim1 > 0.0) & (warpedim2 > 0.0);

% We could either set the overlaping regions using pixel values from first
% image or the max value of the two images.
% I found the max working better.
overlapim = max(warpedim1, warpedim2); 
% overlapim = (warpedim1);

% We could also average the overlaping regions
% overlapim = (warpedim1/2 + warpedim2/2); 
    
outim(overlap) = overlapim(overlap);
end
