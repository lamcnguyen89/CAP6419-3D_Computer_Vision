%% imorder - Automatically order unordered images by finding pairwise connections
%
% DESCRIPTION:
%   When images are not taken in sequential order, this function determines
%   the correct ordering by matching SIFT features between all pairs of images.
%   It uses a graph-based approach to find the sequence that maximizes overlap
%   between adjacent images.
%
% INPUTS:
%   imgs - 4D array of unordered images (height x width x channels x numImages)
%
% OUTPUTS:
%   sorted_imgs - 4D array of images reordered to form a coherent sequence
%
% ALGORITHM:
%   1. Extract SIFT features from all images
%   2. Match features between all possible pairs (N×N comparisons)
%   3. Build connectivity graph based on number of inlier matches
%   4. Find the optimal sequence through the graph
%   5. Reorder images according to found sequence
%
% NOTES:
%   - Computationally expensive: O(N²) feature matching operations
%   - Uses RANSAC to filter outliers and count good matches
%   - Only pairs with sufficient matches (>threshold) are considered neighbors
%
function [sorted_imgs]=imorder(imgs)
% RANSAC parameters for matching
Thresh = 5;              % SIFT edge threshold
confidence = 0.999;      % High confidence for robust matching
inlierRatio = 0.1;       % Expected inlier ratio (lower since all pairs tested)
epsilon = 1.5;           % Inlier threshold in pixels

nImgs = size(imgs, 4);   % Number of images to order

%% Extract SIFT features from all images
T = zeros(3, 3, nImgs);
T(:, :, 1) = eye(3);
imgs_feat{nImgs}={};     % Cell array to store feature locations
imgs_dist{nImgs}={};     % Cell array to store feature descriptors

for i=1: nImgs
    [f, d] = getSIFTFeatures(imgs(:, :, :, i), Thresh);
    imgs_feat{i}=f;
    imgs_dist{i}=d;
end

%% Build connectivity matrix: which images match which
% ifmatch(i,j) = 1 if image i and j have sufficient matches
ifmatch=zeros(nImgs,nImgs);
transforms{nImgs,nImgs}={};  % Store transformations between matches

for i = 1 : nImgs
    for j = 1 : nImgs
        if j==i
            continue  % Skip self-matching
        end
        
        % Match features between image i and image j
        [matches, ~] = getMatches(imgs_feat{i}, imgs_dist{i},...
            imgs_feat{j}, imgs_dist{j});
        
        % Use RANSAC to find inliers and estimate transformation
        [T,nInliers] = ...
        RANSAC(confidence, inlierRatio, 1, matches, epsilon);
        
        % Threshold: if enough inliers, mark as matching pair
        % Threshold = 5.9 + 0.22 * total_matches (empirical formula)
        if nInliers>5.9+.22*length(matches)
            ifmatch(i,j)=1;
            transforms{i,j}=T;
        end
    end
end

%% Find sequence through connectivity graph
% Start from image 1 and follow connections to build sequence
sequence=[];
sequence(1)=1;  % Start with first image

% Forward matching: build sequence by following connections
for i=2:nImgs
    % Find all images that match with previous image in sequence
    nextIdx=find(ifmatch(sequence(i-1),:)==1);
    if size(nextIdx,2)==0
        break  % No more connections found
    end
    
    % Select next image that hasn't been added yet
    failed=true;
    for matched=1:size(nextIdx,2)
        % Skip if this image already in sequence
        if size(find(sequence==nextIdx(matched)),2)==1
            continue
        end
        real_idx=matched;
        failed=false;
        break
    end
    
	if failed==false
        sequence(i)=nextIdx(real_idx);
    else
        break
    end
end
%% backward matching
for i=2:nImgs
    nextIdx=find(ifmatch(sequence(1),:)==1);
    if size(nextIdx,2)==0
        break
    end
    failed=true;
    for matched=1:size(nextIdx,2)
        if size(find(sequence==nextIdx(matched)),2)==1
            continue
        end
        real_idx=matched;
        failed=false;
        break
    end
    if failed==false
        sequence=[nextIdx(real_idx),sequence];
    else
        break
    end
end
%% reorder
disp(['using ',int2str(length(sequence)),' of ',int2str(length(imgs(1,1,1,:))),' unordered imgs']);
sorted_imgs=zeros(size(imgs,1),size(imgs,2),size(imgs,3),length(sequence),'like',imgs);
for i=1:length(sequence)
    sorted_imgs(:,:,:,i)=imgs(:,:,:,sequence(i));
end


