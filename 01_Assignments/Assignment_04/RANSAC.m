%% RANSAC - Robust estimation of 2D translation using Random Sample Consensus
%
% DESCRIPTION:
%   Implements the RANSAC (Random Sample Consensus) algorithm to robustly
%   estimate a 2D translation transformation between matched point pairs,
%   filtering out outlier matches. RANSAC is essential for handling the
%   many incorrect matches that typically come from feature matching.
%
% INPUTS:
%   confidence - Desired confidence level (e.g., 0.99 = 99% probability of success)
%   inliner_Ratio - Expected ratio of inliers to total points (e.g., 0.3 = 30%)
%   Npairs - Number of point pairs needed to compute model (1 for translation)
%   data - Nx3x2 array of matched point pairs in homogeneous coordinates:
%          data(:,:,1) = points from image 1
%          data(:,:,2) = points from image 2
%   epsilon - Threshold for inlier determination (pixels, typically 1.5)
%
% OUTPUTS:
%   T - 3x3 transformation matrix representing 2D translation:
%       T = [1  0  tx]
%           [0  1  ty]
%           [0  0  1 ]
%       where (tx, ty) is the translation in pixels
%   MaxInliers - Number of inlier points that agree with the final model
%
% ALGORITHM:
%   1. Calculate number of iterations m = log(1-conf) / log(1-inlierRatio^Npairs)
%   2. For m iterations:
%      a. Randomly sample Npairs point pairs
%      b. Compute translation from sample: t = point1 - point2
%      c. Test all points against this translation
%      d. Count inliers (points within epsilon pixels after transformation)
%      e. Keep track of model with most inliers
%   3. Recompute final translation using all inliers
%
% MATHEMATICAL FORMULATION:
%   Translation model: p1 = p2 + t, where t = [tx; ty]
%   Error metric: ||p1 - (p2 + t)||^2 < epsilon
%   The transformation matrix in homogeneous coordinates enables composition with
%   other transformations in the panorama pipeline.
%
function [T,MaxInliers] = RANSAC(confidence, inliner_Ratio, Npairs, data, epsilon)

% Calculate number of RANSAC iterations needed for desired confidence
% More iterations = higher probability of finding a good model
m = ceil(log(1 - confidence) / log(1 - inliner_Ratio^Npairs));

NPoints = size(data, 1);  % Total number of matched point pairs
MaxInliers = 0;           % Track best model's inlier count

% Set up linear system for solving translation: A*t = b
% For translation, we need: x1 = x2 + tx, y1 = y2 + ty
A = zeros(2*Npairs, 2);
b = zeros(2*Npairs, 1);
for i = 1:Npairs
    A(2*i-1,1) = 1;  % Coefficient for tx in x-equation
    A(2*i,2) = 1;    % Coefficient for ty in y-equation
end

% RANSAC main loop: try different random samples
for i = 1:m
    % Randomly select Npairs point pairs
    sampleIndicies = randperm(NPoints, Npairs);
    samples = data(sampleIndicies,:,:);
    
    % Extract point coordinates from samples
    pair0=samples(:,:,1);  % Points from image 1 (reference)
    pair1=samples(:,:,2);  % Points from image 2 (to be transformed)

    % Compute translation from sampled points: t = pair0 - pair1
    for j = 1:Npairs
        b(2*j-1) = pair0(j,1)-pair1(j,1);  % tx = x1 - x2
        b(2*j) = pair0(j,2)-pair1(j,2);    % ty = y1 - y2
    end
    t = A \ b;  % Solve for translation vector
    
    % Create transformation matrix in homogeneous coordinates
    T = [1 0 t(1);   % [1 0 tx]
         0 1 t(2);   % [0 1 ty]
         0 0 1];     % [0 0 1 ]
    
    % Test this model against all point pairs
    p_prime = T * data(:,:,2)';           % Transform all points from image 2
    error = data(:,:,1)' - p_prime;       % Compute error vs. image 1 points
    SE = error .^ 2;                      % Squared error
    SSE = sum(SE);                        % Sum of squared errors per point
    
    numInliers=sum(SSE<epsilon);          % Count points within error threshold
    
    % Keep track of the best model (most inliers)
    if numInliers > MaxInliers
        bestSet = find(SSE<epsilon);      % Save indices of inlier points
        MaxInliers = numInliers;          % Update best inlier count
    end
end

% Refine the transformation using all inliers from the best model
% This gives a better estimate than using just the random sample
pair0=data(bestSet,:,1);  % Inlier points from image 1
pair1=data(bestSet,:,2);  % Inlier points from image 2

% Recompute translation using all inliers
for j = 1:Npairs
    b(2*j-1) = pair0(j,1)-pair1(j,1);
    b(2*j) = pair0(j,2)-pair1(j,2);
end
t = A \ b;

% Final transformation matrix computed from all inliers
T = [1 0 t(1); 0 1 t(2); 0 0 1];

end