function Image_Rectification(filename)
    % Generate timestamp for output files
    timestamp = datestr(now, 'yyyymmdd-HHMM');
    % Use descriptive name for output files
    funcname = 'proj2metric_square';
    prefix = sprintf('%s_%s_%s', filename, funcname, timestamp);
    
    % Load and prepare image
    I = imread(filename);
    img = I;
        
    if size(img, 3) == 3  % Check if RGB
        img = rgb2gray(img);
    end

    % Create fullscreen figure
    fullscreen = get(0, 'ScreenSize');
    fig = figure('Position', [0 -50 fullscreen(3) fullscreen(4)]);
    clf;
    
    % Display image and capture square coordinates
    imshow(img);
    hold on;
    title('Click 4 points that make a square in the real world, in order:');
    coords = capture_quad();
    title('Original Image');
    plot_vanishing_line([coords coords(:,1)]);   
    print(fig, '-dpng', sprintf('%s_original.png', prefix));
    close(fig);

    % Apply rectification transformation
    T = proj2metric_square(coords);    
    
    % Apply perspective transformation using MATLAB's imwarp
    tform = projective2d(T');
    I_T = imwarp(I, tform, 'bilinear', 'OutputView', imref2d(size(I)));
        
    % Display and save rectified image
    fig = figure('Position', [0 -50 fullscreen(3) fullscreen(4)]);
    if size(I_T, 3) == 3
        imshow(rgb2gray(I_T));
    else
        imshow(I_T);
    end
    hold on;
    title('Rectified Image');    
    coords_transformed = T * coords;
    plot_vanishing_line([coords_transformed coords_transformed(:,1)]);
    print(fig, '-dpng', sprintf('%s_rectified.png', prefix));
    close(fig);
    imwrite(I_T, sprintf('%s_rectified.png', prefix));
end