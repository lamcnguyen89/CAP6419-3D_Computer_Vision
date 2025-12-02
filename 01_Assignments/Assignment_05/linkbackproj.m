% Source - https://stackoverflow.com/questions/5059568/triangulation-using-the-direct-linear-transform-taken-directly-from-hartley-zi
% Posted by Jeroen Vlek
% Retrieved 2025-12-01, License - CC BY-SA 2.5
% Modified to work with actual images and calibration data


function linkbackproj()
  close all
  clear all

  % Load calibration data
  cd('Input_Images');
  run('calib.m');
  cd('..');
  
  % Display images for point selection
  fprintf('Select corresponding points in both images.\n');
  fprintf('Left-click to add a point, right-click when done.\n\n');
  
  % Select points in first image
  figure('Name', 'Image 1 - Select Points');
  imshow(im1);
  title('Image 1: Click to select points (right-click when done)');
  [x1, y1] = getpts;
  numPts = length(x1);
  
  if numPts == 0
      error('No points selected!');
  end
  
  close;
  
  % Select corresponding points in second image
  figure('Name', 'Image 2 - Select Corresponding Points');
  imshow(im2);
  title(sprintf('Image 2: Select %d corresponding points in SAME ORDER', numPts));
  [x2, y2] = getpts;
  
  if length(x2) ~= numPts
      error('Number of points must match! Selected %d in image 1, but %d in image 2', numPts, length(x2));
  end
  
  close;
  
  % Build projection matrices
  % Camera 1 is at origin: P1 = K1 * [I | 0]
  P = cam1 * [eye(3), zeros(3,1)];
  
  % Camera 2 is translated by baseline along X-axis: P2 = K2 * [I | t]
  % The baseline is the distance between cameras
  Q = cam2 * [eye(3), [-baseline; 0; 0]];
  
  % Create homogeneous coordinates from selected points
  PPtsHom = [x1'; y1'; ones(1, numPts)];
  QPtsHom = [x2'; y2'; ones(1, numPts)];

  % normalize for homogenous scaling (already done by getpts, but ensure)
  for i = 1:3
      PPtsHom(i, :) = PPtsHom(i, :) ./ PPtsHom(3, :);
      QPtsHom(i, :) = QPtsHom(i, :) ./ QPtsHom(3, :);
  end

  % 2D cartesian coordinates
  PPtsCart = PPtsHom(1:2,:);
  QPtsCart = QPtsHom(1:2,:);



  % compute normalizing transform

  % calc centroid
  centroidPPtsCart = mean(PPtsCart,2);
  centroidQPtsCart = mean(QPtsCart,2);

  % calc mean distance to centroid
  normsPPtsCart = zeros(1, numPts);
  normsQPtsCart = zeros(1, numPts);
  for i = 1:numPts
    normsPPtsCart(1,i) = norm(PPtsCart(:,i) - centroidPPtsCart);
    normsQPtsCart(1,i) = norm(QPtsCart(:,i) - centroidQPtsCart);
  end
  mdcPPtsCart = mean(normsPPtsCart);
  mdcQPtsCart = mean(normsQPtsCart);

  % setup transformation
  scaleP = sqrt(2)/mdcPPtsCart;
  scaleQ = sqrt(2)/mdcQPtsCart;

  tP = [ scaleP 0      -scaleP*centroidPPtsCart(1);
    0      scaleP -scaleP*centroidPPtsCart(2);
    0      0      1];
  tQ = [ scaleQ 0      -scaleQ*centroidQPtsCart(1);
    0      scaleQ -scaleQ*centroidQPtsCart(2);
    0      0      1];


  % transform points
  PPtsHom = tP * PPtsHom;
  QPtsHom = tQ * QPtsHom;

  % normalize for homogenous scaling
  for i = 1:3
      PPtsHom(i, :) = PPtsHom(i, :) ./ PPtsHom(3, :);
      QPtsHom(i, :) = QPtsHom(i, :) ./ QPtsHom(3, :);
  end
  % 2D cartesian coordinates
  PPtsCart = PPtsHom(1:2,:);
  QPtsCart = QPtsHom(1:2,:);

  % transform cameras
  P = tP * P;
  Q = tQ * Q;


  % triangulating points
  TriangulatedPoints = zeros(4,numPts);
  for i = 1:numPts
      A = [
          PPtsCart(1, i) * P(3, :) - P(1, :);
          PPtsCart(2, i) * P(3, :) - P(2, :);
          QPtsCart(1, i) * Q(3,:) - Q(1,:);
          QPtsCart(2, i) * Q(3,:) - Q(2,:)
      ];

      [U S V] = svd(A);
      TriangulatedPoints(:, i) = V(:, end);
  end
  for i = 1:4
      TriangulatedPoints(i, :) = TriangulatedPoints(i, :) ./ TriangulatedPoints(4, :);
  end
  
  % Display results
  fprintf('\nTriangulated 3D Points:\n');
  fprintf('Point\t   X\t\t   Y\t\t   Z\n');
  fprintf('-----\t-------\t-------\t-------\n');
  for i = 1:numPts
      fprintf('%d\t%8.3f\t%8.3f\t%8.3f\n', i, ...
              TriangulatedPoints(1, i), TriangulatedPoints(2, i), TriangulatedPoints(3, i));
  end
  
  % Show selected points on images
  figure('Name', 'Selected Point Correspondences');
  subplot(1, 2, 1);
  imshow(im1);
  hold on;
  plot(x1, y1, 'r+', 'MarkerSize', 15, 'LineWidth', 2);
  for i = 1:numPts
      text(x1(i)+10, y1(i), sprintf('%d', i), 'Color', 'yellow', 'FontSize', 12, 'FontWeight', 'bold');
  end
  title('Image 1 - Selected Points');
  hold off;
  
  subplot(1, 2, 2);
  imshow(im2);
  hold on;
  plot(x2, y2, 'r+', 'MarkerSize', 15, 'LineWidth', 2);
  for i = 1:numPts
      text(x2(i)+10, y2(i), sprintf('%d', i), 'Color', 'yellow', 'FontSize', 12, 'FontWeight', 'bold');
  end
  title('Image 2 - Corresponding Points');
  hold off;
  
  % Plot 3D reconstruction
  figure('Name', '3D Reconstruction')
  scatter3(TriangulatedPoints(1, :), TriangulatedPoints(2, :), TriangulatedPoints(3, :), 100, 'filled');
  hold on;
  
  % Add point labels
  for i = 1:numPts
      text(TriangulatedPoints(1, i), TriangulatedPoints(2, i), TriangulatedPoints(3, i), ...
           sprintf('  P%d', i), 'FontSize', 10);
  end
  
  % Plot camera positions
  scatter3(0, 0, 0, 200, 'r', 'filled', 'MarkerEdgeColor', 'k');
  text(0, 0, 0, '  Cam1', 'FontSize', 12, 'Color', 'r', 'FontWeight', 'bold');
  
  scatter3(-baseline, 0, 0, 200, 'b', 'filled', 'MarkerEdgeColor', 'k');
  text(-baseline, 0, 0, '  Cam2', 'FontSize', 12, 'Color', 'b', 'FontWeight', 'bold');
  
  xlabel('X (mm)');
  ylabel('Y (mm)');
  zlabel('Z (mm)');
  title('Triangulated Points');
  grid on;
  axis equal;
  view(3);
  hold off;
