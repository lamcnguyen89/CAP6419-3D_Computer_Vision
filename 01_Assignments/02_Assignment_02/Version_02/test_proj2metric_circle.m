function test_proj2metric_circle(filename)
    timestamp = datestr(now, 'yyyymmdd-HHMM');
    funcname = mfilename;
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
    title('Click 5 points that exist on a real-world circle:');
    coords = capture_points(5);    
    title('Click the center of the real-world circle:');
    center = capture_points(1);
    title('Original Image');
    print(fig, '-dpng', sprintf('%s_original.png', prefix));
    close(fig);

    T = proj2metric_circle(coords, center);
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
    print(fig, '-dpng', sprintf('%s_rectified.png', prefix));
    close(fig);
    imwrite(I_T, sprintf('%s_rectified.png', prefix));
end
