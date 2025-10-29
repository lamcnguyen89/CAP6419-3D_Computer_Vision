%% Code to Generate a Panorama from Multiple Images
% This script implements a panoramic image stitching pipeline that:
% - Reads multiple images from a sequence
% - Detects and matches feature points between adjacent images
% - Estimates homographies using RANSAC
% - Warps images to a common reference frame
% - Composites them into a single panoramic image
%
% ASSIGNMENT REQUIREMENTS:
%
% 1. IMAGE SEQUENCE ACQUISITION
%    - Obtain an image sequence where the camera projection center does not
%      change (or changes minimally) during the entire sequence
%    - Adjacent pairs of images must significantly overlap each other
%    - You may use provided sequences or capture your own images
%    - Required: Test on at least one self-captured image set
%    - Minimum: Mosaic at least 4 images together per data set
%    - Apply method to at least 3 different sequences
%    - All results must be reproducible
%
% 2. FEATURE POINT CORRESPONDENCE
%    - Use a feature point correspondence algorithm (e.g., SIFT with RANSAC)
%      to automatically track point correspondences
%    - Set number of features to track as appropriate (e.g., 100 features)
%    - Document and justify any parameter changes from default settings
%    - Run the algorithm on your image sequence to create point correspondences
%    - Note: Manual point correspondence is also allowed but tedious
%
% 3. HOMOGRAPHY COMPUTATION
%    - Compute the infinite homography between each pair of adjacent frames
%    - Implement forward or backward homography mapping for each candidate
%      set of point correspondences
%    - Use RANSAC to ensure best fit in the presence of outliers (when using SIFT)
%    - Reference: Normalized GOLD standard algorithm and robust version
%      using RANSAC (see textbook)
%
% 4. IMAGE WARPING
%    - Warp each image via the infinite homography associated with one reference
%      frame (ideally one in the middle of the sequence)
%    - Use backward mapping method with bilinear interpolation for pixel resampling
%    - Note: MATLAB image transformation functions are allowed, or use functions
%      from Assignment 2
%
% 5. IMAGE COMPOSITING
%    - Composite all images into a single panoramic image
%    - Optional: Implement feathering algorithm using bilinear weighting function
%      for all pixels contributing at a given point
%    - Reference: Equation (9) in Szeliski, R. "Video mosaics for virtual 
%      environments," IEEE Computer Graphics and Applications 16(2), 22-30, 1996
%    - Feathering reduces noticeable seams in the result image

function [panorama]=main(filename)
    %% parse path
    path='imagesets';
    
    % If numeric index provided, get dataset name from folder list
    if isnumeric(filename)
        dataset_idx=filename;
        % Get all folders in imagesets directory
        imgsFolderContents = dir(path);
        imgsFolderContents = imgsFolderContents([imgsFolderContents.isdir]); % Keep only directories
        imgsFolderContents = imgsFolderContents(~ismember({imgsFolderContents.name},{'.','..'})); % Remove . and ..
        
        if dataset_idx < 1 || dataset_idx > length(imgsFolderContents)
            error('Dataset index %d is out of range. Valid range: 1-%d', dataset_idx, length(imgsFolderContents));
        end
        
        dataset_name = imgsFolderContents(dataset_idx).name;
    else
        % String path provided
        if strcmp(filename(end),'/')
            filename=filename(1:end-1);
        end
        [path,dataset_name,~]=fileparts(filename);
        disp(['path ',path,' dataset ',dataset_name])
        dataset_idx = -1; % Not used when string path provided
    end
    
    %% params - default values for unknown datasets
    % Known datasets with specific parameters
    known_datasets = struct(...
        'ucsb4', struct('focus', 595, 'full360', 0, 'unordered', 0), ...
        'family_house', struct('focus', 400, 'full360', 0, 'unordered', 1), ...
        'glacier4', struct('focus', 2000, 'full360', 0, 'unordered', 0), ...
        'yellowstone2', struct('focus', 1000, 'full360', 0, 'unordered', 0), ...
        'GrandCanyon1', struct('focus', 1000, 'full360', 0, 'unordered', 0), ...
        'yellowstone5', struct('focus', 1000, 'full360', 0, 'unordered', 0), ...
        'yellowstone4', struct('focus', 1000, 'full360', 0, 'unordered', 0), ...
        'west_campus1', struct('focus', 1000, 'full360', 0, 'unordered', 1), ...
        'redrock', struct('focus', 2000, 'full360', 0, 'unordered', 0), ...
        'intersection', struct('focus', 2000, 'full360', 0, 'unordered', 0), ...
        'GrandCanyon2', struct('focus', 2000, 'full360', 0, 'unordered', 0) ...
    );
    
    % Default parameters for new/unknown datasets
    default_focus = 800;
    default_full360 = 0;
    default_unordered = 0;
    
    % Get parameters for this dataset
    if isfield(known_datasets, dataset_name)
        params = known_datasets.(dataset_name);
        f = params.focus;
        full = params.full360;
        is_unordered = params.unordered;
    else
        % Use defaults for unknown datasets
        f = default_focus;
        full = default_full360;
        is_unordered = default_unordered;
        disp(['Using default parameters for unknown dataset: ', dataset_name]);
    end
    
    size_bound=400.0;
    %%
    run('lib/vlfeat-0.9.20/toolbox/vl_setup');
    disp(['creating panorama for ',dataset_name]);
    disp(['  focal length: ', num2str(f), ', 360: ', num2str(full), ', unordered: ', num2str(is_unordered)]);
    s=imageSet(fullfile(path,dataset_name));
    img=read(s,1);
    size_1=size(img,1);
    if size_1>size_bound
        img=imresize(img,size_bound/size_1);
    end
    imgs=zeros(size(img,1),size(img,2),size(img,3),s.Count,'like',img);
    t=cputime;
    for i=1:s.Count
        new_img=read(s,i);
        if size_1>size_bound
            imgs(:,:,:,i)=imresize(new_img,size_bound/size_1);
        else
            imgs(:,:,:,i)=new_img;
        end
        
    end
    disp(['resizing ',int2str(cputime-t),' sec']);

    if is_unordered
        t=cputime;
        disp('ordering unordered images');
        imgs=imorder(imgs);
        disp([int2str(cputime-t),' sec']);
    end

    panorama=create( imgs, f, full);
    imwrite(panorama,['./results/',dataset_name,'.jpg']);
    if is_unordered
        imwrite(panorama,['./results/',dataset_name,'_from_unordered.jpg']);
    end