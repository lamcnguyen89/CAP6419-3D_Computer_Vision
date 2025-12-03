% Function built from scratch to create 3D reconstruction from 2 images of a scene

function linkbackproj()
  close all
  clear all

  % Define folders to process
  folders = {'globe', 'Newkuba', 'Piano', 'Playroom'};
  
  % Loop through each folder
  for folderIdx = 1:length(folders)
      folderName = folders{folderIdx};
      fprintf('\n========================================\n');
      fprintf('Processing folder: %s\n', folderName);
      fprintf('========================================\n');
      
      % Load calibration data
      cd(folderName);
      run('calib.m');
      cd('..');
      
      % Display images for point selection
      fprintf('Select corresponding points in both images.\n');
      fprintf('Left-click to add a point, right-click when done.\n\n');
      
      % Select points in first image
      figure('Name', sprintf('%s - Image 1 - Select Points', folderName));
      imshow(im1);
      title(sprintf('%s - Image 1: Click to select points (right-click when done)', folderName));
      [x1, y1] = getpts;
      numPts = length(x1);
      
      if numPts == 0
          warning('No points selected for %s! Skipping...', folderName);
          close;
          continue;
      end
      
      close;
      
      % Select corresponding points in second image
      figure('Name', sprintf('%s - Image 2 - Select Corresponding Points', folderName));
      imshow(im2);
      title(sprintf('%s - Image 2: Select %d corresponding points in SAME ORDER', folderName, numPts-1));
      [x2, y2] = getpts;
      
      if length(x2) ~= numPts
          warning('Number of points mismatch for %s! Selected %d in image 1, but %d in image 2. Skipping...', ...
                  folderName, numPts, length(x2));
          close;
          continue;
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

          [U, S, V] = svd(A);
          TriangulatedPoints(:, i) = V(:, end);
      end
      for i = 1:4
          TriangulatedPoints(i, :) = TriangulatedPoints(i, :) ./ TriangulatedPoints(4, :);
      end
      
      % Display results
      fprintf('\nTriangulated 3D Points for %s:\n', folderName);
      fprintf('Point\t   X\t\t   Y\t\t   Z\n');
      fprintf('-----\t-------\t-------\t-------\n');
      for i = 1:numPts
          fprintf('%d\t%8.3f\t%8.3f\t%8.3f\n', i, ...
                  TriangulatedPoints(1, i), TriangulatedPoints(2, i), TriangulatedPoints(3, i));
      end
      
      % Show selected points on images
      fig_corresp = figure('Name', sprintf('%s - Selected Point Correspondences', folderName));
      subplot(1, 2, 1);
      imshow(im1);
      hold on;
      plot(x1, y1, 'r+', 'MarkerSize', 15, 'LineWidth', 2);
      for i = 1:numPts
          text(x1(i)+10, y1(i), sprintf('%d', i), 'Color', 'yellow', 'FontSize', 12, 'FontWeight', 'bold');
      end
      title(sprintf('%s - Image 1 - Selected Points', folderName));
      hold off;
      
      subplot(1, 2, 2);
      imshow(im2);
      hold on;
      plot(x2, y2, 'r+', 'MarkerSize', 15, 'LineWidth', 2);
      for i = 1:numPts
          text(x2(i)+10, y2(i), sprintf('%d', i), 'Color', 'yellow', 'FontSize', 12, 'FontWeight', 'bold');
      end
      title(sprintf('%s - Image 2 - Corresponding Points', folderName));
      hold off;
      
      % Save point correspondences figure
      saveas(fig_corresp, fullfile(folderName, sprintf('linkbackproj_%s_correspondences.fig', folderName)));
      saveas(fig_corresp, fullfile(folderName, sprintf('linkbackproj_%s_correspondences.png', folderName)));
      
      % Plot 3D reconstruction
      fig_3d = figure('Name', sprintf('%s - 3D Reconstruction', folderName));
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
      title(sprintf('%s - Triangulated Points', folderName));
      grid on;
      axis equal;
      view(3);
      hold off;
      
      % Save 3D reconstruction figure
      saveas(fig_3d, fullfile(folderName, sprintf('linkbackproj_%s_3d_reconstruction.fig', folderName)));
      saveas(fig_3d, fullfile(folderName, sprintf('linkbackproj_%s_3d_reconstruction.png', folderName)));
      
      % Save triangulated points data
      save(fullfile(folderName, sprintf('linkbackproj_%s_data.mat', folderName)), ...
           'TriangulatedPoints', 'x1', 'y1', 'x2', 'y2', 'numPts', 'baseline');
      
      fprintf('\nSaved results for %s\n', folderName);
      
  end % End of folder loop
  
  fprintf('\n========================================\n');
  fprintf('Processing complete for all folders!\n');
  fprintf('========================================\n');
