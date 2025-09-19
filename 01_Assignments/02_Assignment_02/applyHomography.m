function img_out = applyHomography(img, H)
    % Apply homography to image
    % This implementation works with older MATLAB versions
    
    % Check if newer functions are available
    if exist('projective2d', 'file') == 2
        % Use newer MATLAB functions (R2013a and later)
        tform = projective2d(H');
        img_out = imwarp(img, tform);
    elseif exist('maketform', 'file') == 2
        % Use older MATLAB functions (compatible with older versions)
        tform = maketform('projective', H');
        [boxx, boxy] = tformfwd(tform, [1 1 size(img,2) size(img,2)], [1 size(img,1) 1 size(img,1)]);
        minx = min(boxx); maxx = max(boxx);
        miny = min(boxy); maxy = max(boxy);
        img_out = imtransform(img, tform, 'XData', [minx maxx], 'YData', [miny maxy], ...
                             'Size', [size(img,1), round(size(img,1)*(maxx-minx)/(maxy-miny))]);
    else
        % Manual implementation for very basic MATLAB installations
        img_out = applyHomographyManual(img, H);
    end
end

function img_out = applyHomographyManual(img, H)
    % Manual implementation of homography transformation
    [rows, cols, channels] = size(img);
    
    % Create coordinate grids
    [X, Y] = meshgrid(1:cols, 1:rows);
    coords_homog = [X(:)'; Y(:)'; ones(1, rows*cols)];
    
    % Apply inverse homography to find source coordinates
    H_inv = inv(H);
    transformed_coords = H_inv * coords_homog;
    
    % Convert back from homogeneous coordinates
    x_src = transformed_coords(1,:) ./ transformed_coords(3,:);
    y_src = transformed_coords(2,:) ./ transformed_coords(3,:);
    
    % Reshape back to image dimensions
    x_src = reshape(x_src, rows, cols);
    y_src = reshape(y_src, rows, cols);
    
    % Initialize output image
    img_out = zeros(size(img));
    
    % Bilinear interpolation
    for c = 1:channels
        img_out(:,:,c) = interp2(double(img(:,:,c)), x_src, y_src, 'linear', 0);
    end
    
    % Convert back to original data type
    img_out = cast(img_out, class(img));
end