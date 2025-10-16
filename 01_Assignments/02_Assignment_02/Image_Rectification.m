% Image Rectification Script

% CAP6419: 3D Computer Vision
% Assignment 02: Chapter 3 of Textbook: Multiple View Geometry in Computer Vision (2nd Edition)


%% ASSIGNMENT PARAMETERS
% Submit your matlab codes and results on the test images together with a report in a
% word document explaining how your program works (i.e. the steps involved). What were the
% problems that you noticed, if any? Your report should be written like a technical paper, and
% should also include a conclusion section at the end (including your reflections and thoughts, what
% worked and what went wrong if any).
% For your convenience, I have also provided some test images and a short Matlab code for fitting
% a conic to a set of 5 or more points based on the method discussed in the class (page 31 of your
% textbook).
% Grading: 10% data collection (camera pictures, or online images), 20% coding for affine
% rectification, 20% coding for metric rectification, 30% thorough testing on several images for
% both rectifications, 20% report. Again, your report must contain the procedures, input test
% images, output images after rectification, and your conclusions and reflections on the problem
% and the results.
% ______________________________________________________________________
% Suggestion for taking test images: You may want to take a picture of the main lobby of the
% student union, with the encircled Pegasus in the middle that can be used for metric rectification.
% Make sure you can identify parallel lines and/or cross-ratios in your pictures. Also make sure that
% the pictures have enough projective distortion (i.e. taken at an angle).
% Reminder : The intersection of a line l and a conic C can be determined as follows: let m1 and
% m2 be two points on the line l, then any arbitrary point m on the line can be specified
% parametrically by m =m1 +λm2 . Point m is on the intersection of the line with the conic C, iff
% mTCm =(m1 +λm2 )T C(m1 +λm2 ) =0.
% This yields the following quadratic equation in terms of λ
% λ2 m2TCm2 2 +λ m2TCm1 + m1TC m1 0 =
% from which we get the two values λ1 and λ2 , and hence the two intersection points m1 +λ1m2 and
% m1 +λ2m2 . Note that in general a line intersects a conic at two points, which may be distinct or
% not and real or complex


% Other files that this references:
        % capture_quad.m
        % plot_vanishing_line.m
        % proj2metric_square.m
        % proj2affine.m
        % affine2metric_orthos.m

% Key Points for Implementation:
    % 1. Data Collection: Take images with clear parallel lines and circular objects
    % 2. Point Selection: Use ginput() for manual point selection or implement automatic detection
    % 3. Conic Fitting: Implement the algorithm from textbook page 31
    % 4. Homography Computation: Handle the mathematical transformations carefully
    % 5. Testing: Test on multiple images with different perspective distortions

% The most challenging part is computing the metric rectification, which requires identifying the absolute conic or circular points in the image.


function Image_Rectification(filename)
    % Generate timestamp for output files
    timestamp = string(datetime('now', 'Format', 'yyyyMMdd-HHmm'));
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