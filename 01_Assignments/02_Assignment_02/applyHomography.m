function img_out = applyHomography(img, H)
    % Apply homography to image
    tform = projective2d(H');
    img_out = imwarp(img, tform);
end