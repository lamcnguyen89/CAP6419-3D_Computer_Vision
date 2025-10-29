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
    %             1       2unorder          3           4             5
    datasets={'ucsb4','family_house','glacier4','yellowstone2','GrandCanyon1',...
        'yellowstone5','yellowstone4','west_campus1','redrock','intersection',...
    ...%     6              7               8unorder            9      10
    'GrandCanyon2'};
    % 11  
    if isnumeric(filename)
        dataset_idx=filename;
        path='imgs';
    else
        if strcmp(filename(end),'/')
            filename=filename(1:end-1);
        end
        [path,dataset_name,~]=fileparts(filename);
        disp(['path ',path,' dataset ',dataset_name])
        
        dataset_idx=find(strcmp(datasets,dataset_name));
    end
    %% params
    %dataset_idx=8;
    %       1   2  3    4     5   6    7    8    9    10   11
    focus=[595,400,2000,1000,1000,1000,1000,1000,2000,2000,2000];
    Full360=[0,0,0,0,0,0,0,0,0,0,0];
    unordered=[0,1,0,0,0,0,0,1,0,0,0];
    size_bound=400.0;
    %%
    full=Full360(dataset_idx);
    f=focus(dataset_idx);
    run('lib/vlfeat-0.9.20/toolbox/vl_setup');
    disp(['creating panorama for ',datasets{dataset_idx}]);
    s=imageSet(fullfile(path,datasets{dataset_idx}));
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
    disp(['resizing',int2str(cputime-t),' sec']);

    if unordered(dataset_idx)
        t=cputime;
        disp('ordering unordered images');
        imgs=imorder(imgs);
        disp([int2str(cputime-t),' sec']);
    end

    panorama=create( imgs, f, full);
    imwrite(panorama,['./results/',datasets{dataset_idx},'.jpg']);
    if unordered(dataset_idx)
        imwrite(panorama,['./results/',datasets{dataset_idx},'from unordered.jpg']);
    end