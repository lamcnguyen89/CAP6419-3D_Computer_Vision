function outim = stitch2images(im1, im2, H)
%
% This function stitches together im1 and im2 given the homography H that
% transforms im1 to match im2
%
%

T = projective2d(double(H));
[xlim, ylim] = outputLimits(T, [1 size(im1,2)], [1 size(im1,1)]);
xdata = [xlim(1) xlim(2)];
ydata = [ylim(1) ylim(2)];

Outxdata=[min(1,xdata(1)) max(size(im2,2), xdata(2))];
outydata=[min(1,ydata(1)) max(size(im2,1), ydata(2))];

Rout = imref2d([diff(outydata) diff(Outxdata)], Outxdata, outydata);
warpedim1 = imwarp(im1, T, 'OutputView', Rout);
T2 = affine2d(eye(3));
warpedim2 = imwarp(im2, T2, 'OutputView', Rout);
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
