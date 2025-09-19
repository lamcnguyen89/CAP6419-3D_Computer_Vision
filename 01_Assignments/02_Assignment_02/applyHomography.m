function img_out = applyHomography(img, H)
    % Apply homography to image
    % This implementation works with older MATLAB versions
    
    % Check for reasonable homography
    if rcond(H) < 1e-12
        warning('Homography matrix is poorly conditioned. Results may be unreliable.');
    end
    
    % Check if transformation will create extreme distortion
    corners = [1, 1, size(img,2), size(img,2); 
               1, size(img,1), 1, size(img,1); 
               1, 1, 1, 1];
    transformed_corners = H * corners;
    
    % Normalize homogeneous coordinates (divide by the third row)
    % Use bsxfun for compatibility with older MATLAB versions
    transformed_corners = bsxfun(@rdivide, transformed_corners, transformed_corners(3,:));
    
    % Check for reasonable bounds
    % Compatible with older MATLAB versions - get max of all elements
    coord_matrix = abs(transformed_corners(1:2,:));
    max_coord = max(coord_matrix(:));
    if max_coord > 10 * max(size(img))
        warning('Transformation will create very large output image. Consider checking vanishing point calculation.');
        fprintf('Maximum coordinate after transformation: %.0f\n', max_coord);
    end
    
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
        
        % Limit output size to prevent memory issues
        max_size = 5000; % Maximum dimension
        width = maxx - minx;
        height = maxy - miny;
        if width > max_size || height > max_size
            warning('Output image would be very large. Limiting size to %dx%d', max_size, max_size);
            if width > height
                scale = max_size / width;
                width = max_size;
                height = height * scale;
            else
                scale = max_size / height;
                height = max_size;
                width = width * scale;
            end
        end
        
        img_out = imtransform(img, tform, 'XData', [minx maxx], 'YData', [miny maxy], ...
                             'Size', [round(height), round(width)]);
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