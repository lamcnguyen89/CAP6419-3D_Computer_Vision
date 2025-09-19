function runRectification()
    % Load image
    img = imread('your_test_image.jpg');
    
    % Display for point selection
    figure; imshow(img); title('Select points for rectification');
    
    % Perform affine rectification
    img_affine = performAffineRectification(img);
    
    % Perform metric rectification
    img_metric = performMetricRectification(img_affine);
    
    % Display results
    figure;
    subplot(1,3,1); imshow(img); title('Original');
    subplot(1,3,2); imshow(img_affine); title('Affine Rectified');
    subplot(1,3,3); imshow(img_metric); title('Metric Rectified');
end