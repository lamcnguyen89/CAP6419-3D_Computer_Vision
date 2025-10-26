function test_proj2metric_square(filename)
    timestamp = datestr(now, 'yyyymmdd-HHMM');
    funcname = mfilename;
    if length(funcname) > 5 && strcmp(funcname(1:5), 'test_')
        funcname = funcname(6:end);  % Remove 'test_' prefix
    end
    prefix = sprintf('%s_%s_%s', filename, funcname, timestamp);
    
    I = imread(filename);
    img = I;
        
    if size(img, 3) == 3  % Check if RGB
        img = rgb2gray(img);
    end

    fullscreen = get(0, 'ScreenSize');
    fig = figure('Position', [0 -50 fullscreen(3) fullscreen(4)]);
    clf;
    
    imshow(img);
    hold on;
    title('Click 4 points that make a square in the real world, in order:');
    coords = capture_quad();
    title('Original Image');
    plot_vanishing_line([coords coords(:,1)]);   
    print(fig, '-dpng', sprintf('%s_original.png', prefix));
    close(fig);

    T = proj2metric_square(coords);    
    tform = projective2d(T');
    I_T = imwarp(I, tform, 'bilinear', 'OutputView', imref2d(size(I)));
        
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
