% 3D Reconstruction using MATLAB's triangulate function
% This script loops through multiple folders, loads images and calibration data,
% then creates and saves 3D scatter plots of triangulated points

clear; clc; close all;

% Define folders to process
folders = {'globe', 'Newkuba', 'Piano', 'Playroom'};

% Loop through each folder
for folder_idx = 1:length(folders)
    folder_name = folders{folder_idx};
    fprintf('\n========================================\n');
    fprintf('Processing folder: %s\n', folder_name);
    fprintf('========================================\n');
    
    % Clear variables from previous iteration
    clearvars -except folders folder_idx folder_name

    % If calibration data exists from previous runs, clear it
    clear im1 im2 cam1 cam2 doffs baseline width height ndisp
    
    % Load calibration data and images from the current folder
    run(sprintf('%s/calib.m', folder_name));

    
    % Display images
    figure('Name', sprintf('%s - Input Images', folder_name));
    subplot(1,2,1); imshow(im1); title('Image 1');
    subplot(1,2,2); imshow(im2); title('Image 2');
    
    % Convert to grayscale if needed
    if size(im1, 3) == 3
        im1_gray = rgb2gray(im1);
    else
        im1_gray = im1;
    end
    
    if size(im2, 3) == 3
        im2_gray = rgb2gray(im2);
    else
        im2_gray = im2;
    end
    
    % Detect SURF features in both images
    fprintf('Detecting features...\n');
    points1 = detectSURFFeatures(im1_gray);
    points2 = detectSURFFeatures(im2_gray);
    
    % Extract feature descriptors
    [features1, valid_points1] = extractFeatures(im1_gray, points1);
    [features2, valid_points2] = extractFeatures(im2_gray, points2);
    
    % Match features between images
    fprintf('Matching features...\n');
    indexPairs = matchFeatures(features1, features2, 'Unique', true);
    
    % Get matched points
    matchedPoints1 = valid_points1(indexPairs(:, 1), :);
    matchedPoints2 = valid_points2(indexPairs(:, 2), :);
    
    fprintf('Found %d matched points\n', size(matchedPoints1, 1));
    
    % Check the disparity direction (for debugging stereo geometry)
    mean_disparity = mean(matchedPoints1.Location(:,1) - matchedPoints2.Location(:,1));
    fprintf('Mean disparity (x1 - x2): %.2f pixels\n', mean_disparity);
    fprintf('Camera principal point difference (cx2 - cx1): %.2f pixels\n', cam2(1,3) - cam1(1,3));
    
    % Visualize matched features
    figure('Name', sprintf('%s - Matched Features', folder_name));
    showMatchedFeatures(im1, im2, matchedPoints1, matchedPoints2, 'montage');
    title(sprintf('Matched Features (%d pairs)', size(matchedPoints1, 1)));
    
    % Create camera parameters objects
    intrinsics1 = cameraIntrinsics([cam1(1,1), cam1(2,2)], ...
                                   [cam1(1,3), cam1(2,3)], ...
                                   [height, width]);
                                   
    intrinsics2 = cameraIntrinsics([cam2(1,1), cam2(2,2)], ...
                                   [cam2(1,3), cam2(2,3)], ...
                                   [height, width]);
    
    % Determine if we need to swap based on both disparity and camera geometry
    % For proper stereo: if cam2 is to the right (cx2 > cx1), disparity should be positive
    % if cam2 is to the left (cx2 < cx1), disparity should be negative
    expected_disparity_sign = sign(cam2(1,3) - cam1(1,3));
    actual_disparity_sign = sign(mean_disparity);
    
    if expected_disparity_sign ~= actual_disparity_sign
        fprintf('Swapping cameras and points to match geometry\n');
        % Swap intrinsics
        temp_intrinsics = intrinsics1;
        intrinsics1 = intrinsics2;
        intrinsics2 = temp_intrinsics;
        % Swap matched points  
        temp_points = matchedPoints1;
        matchedPoints1 = matchedPoints2;
        matchedPoints2 = temp_points;
    end
    
    % Create stereo parameters for rectified stereo pairs
    % For rectified stereo, both cameras have the same orientation
    % but are translated horizontally by the baseline
    stereoParams = stereoParameters(intrinsics1, intrinsics2, eye(3), [baseline, 0, 0]);
    
    % Triangulate using stereo parameters
    fprintf('Triangulating points...\n');
    points3D = triangulate(matchedPoints1, matchedPoints2, stereoParams);
    
    % Display raw statistics before filtering
    fprintf('\nRaw 3D point statistics before filtering:\n');
    if ~isempty(points3D)
        fprintf('  X: min=%.2f, max=%.2f, mean=%.2f, median=%.2f\n', ...
                min(points3D(:,1)), max(points3D(:,1)), mean(points3D(:,1)), median(points3D(:,1)));
        fprintf('  Y: min=%.2f, max=%.2f, mean=%.2f, median=%.2f\n', ...
                min(points3D(:,2)), max(points3D(:,2)), mean(points3D(:,2)), median(points3D(:,2)));
        fprintf('  Z: min=%.2f, max=%.2f, mean=%.2f, median=%.2f\n', ...
                min(points3D(:,3)), max(points3D(:,3)), mean(points3D(:,3)), median(points3D(:,3)));
        
        % Check for infinite or NaN values
        num_inf = sum(isinf(points3D(:)));
        num_nan = sum(isnan(points3D(:)));
        fprintf('  Infinite values: %d, NaN values: %d\n', num_inf, num_nan);
    end
    
    % Adaptive filtering based on baseline
    % Set maximum depth to be proportional to baseline
    max_depth = baseline * 50;  % Allow points up to 50x the baseline distance
    max_xy = baseline * 30;     % Allow lateral displacement proportional to baseline
    
    fprintf('\nFiltering with max_depth=%.2f, max_xy=%.2f\n', max_depth, max_xy);
    fprintf('Total triangulated points: %d\n', size(points3D, 1));
    
    % Remove points that are too far or have negative depth, and remove inf/nan
    valid_idx = isfinite(points3D(:,1)) & isfinite(points3D(:,2)) & isfinite(points3D(:,3)) & ...
                points3D(:,3) > 0 & points3D(:,3) < max_depth & ...
                abs(points3D(:,1)) < max_xy & abs(points3D(:,2)) < max_xy;
    points3D_filtered = points3D(valid_idx, :);
    matchedPoints1_filtered = matchedPoints1(valid_idx, :);
    
    fprintf('Points after filtering: %d valid 3D points\n', size(points3D_filtered, 1));
    
    % Display detailed statistics about rejected points
    neg_depth = sum(points3D(:,3) <= 0);
    too_far_z = sum(points3D(:,3) >= max_depth);
    too_far_x = sum(abs(points3D(:,1)) >= max_xy);
    too_far_y = sum(abs(points3D(:,2)) >= max_xy);
    fprintf('Rejected breakdown:\n');
    fprintf('  Negative/zero depth: %d\n', neg_depth);
    fprintf('  Z >= %.2f: %d\n', max_depth, too_far_z);
    fprintf('  |X| >= %.2f: %d\n', max_xy, too_far_x);
    fprintf('  |Y| >= %.2f: %d\n', max_xy, too_far_y);
    
    % Get colors from the first image for visualization
    colors = zeros(size(points3D_filtered, 1), 3);
    for i = 1:size(points3D_filtered, 1)
        x = round(matchedPoints1_filtered.Location(i, 1));
        y = round(matchedPoints1_filtered.Location(i, 2));
        
        % Ensure coordinates are within image bounds
        x = max(1, min(width, x));
        y = max(1, min(height, y));
        
        if size(im1, 3) == 3
            colors(i, :) = double(im1(y, x, :)) / 255;
        else
            gray_val = double(im1(y, x)) / 255;
            colors(i, :) = [gray_val, gray_val, gray_val];
        end
    end
    
    % Create 3D scatter plot
    fig = figure('Name', sprintf('%s - 3D Reconstruction', folder_name));
    scatter3(points3D_filtered(:,1), points3D_filtered(:,2), points3D_filtered(:,3), ...
             10, colors, 'filled');
    xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');
    title(sprintf('%s - 3D Reconstruction (%d points)', folder_name, size(points3D_filtered, 1)));
    grid on;
    axis equal;
    view(3);
    rotate3d on;
    
    % Save the 3D scatter plot
    output_filename = sprintf('%s/%s_3D_reconstruction.fig', folder_name, folder_name);
    savefig(fig, output_filename);
    fprintf('Saved figure to: %s\n', output_filename);
    
    % Also save as PNG
    output_png = sprintf('%s/%s_3D_reconstruction.png', folder_name, folder_name);
    saveas(fig, output_png);
    fprintf('Saved PNG to: %s\n', output_png);
    
    % Display statistics
    fprintf('\n3D Point Statistics:\n');
    fprintf('X range: [%.2f, %.2f] mm\n', min(points3D_filtered(:,1)), max(points3D_filtered(:,1)));
    fprintf('Y range: [%.2f, %.2f] mm\n', min(points3D_filtered(:,2)), max(points3D_filtered(:,2)));
    fprintf('Z range: [%.2f, %.2f] mm\n', min(points3D_filtered(:,3)), max(points3D_filtered(:,3)));
    
    fprintf('Completed processing %s\n', folder_name);
end

fprintf('\n========================================\n');
fprintf('All folders processed successfully!\n');
fprintf('========================================\n');
