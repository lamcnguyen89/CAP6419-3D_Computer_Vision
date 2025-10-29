%% main - Entry point for panorama stitching pipeline
%
% DESCRIPTION:
%   Main function that coordinates the entire panorama creation process.
%   Handles dataset selection, parameter configuration, image loading,
%   preprocessing, and invokes the panorama creation pipeline.
%
% INPUTS:
%   filename - Either:
%              1. Numeric index (e.g., 1, 2, 3...) to process Nth folder in imagesets/
%              2. String path (e.g., 'imagesets/GrandCanyon1') to process specific folder
%
% OUTPUTS:
%   panorama - Final stitched panoramic image (saved to results/ folder)
%
% USAGE EXAMPLES:
%   panorama = main(1);                    % Process first dataset in imagesets/
%   panorama = main('imagesets/ucsb4');    % Process specific dataset by name
%
% DATASET PARAMETERS:
%   focus - Focal length in pixels (affects cylindrical warping curvature)
%           Lower (400-600): Wide-angle, more distortion correction
%           Higher (1500-2000): Telephoto, less distortion correction
%   full360 - Whether this is a 360° panorama that wraps around (0 or 1)
%   unordered - Whether images need to be ordered automatically (0 or 1)
%               Set to 1 if images are not in sequential left-to-right order
%
% PROCESSING STEPS:
%   1. Parse input and determine dataset path
%   2. Load dataset-specific parameters (or use defaults)
%   3. Initialize VLFeat library for SIFT features
%   4. Load and resize images for faster processing
%   5. Order images if they're unordered
%   6. Call create() to generate panorama
%   7. Save result to results/ folder
%
function [panorama]=main(filename)
    %% Parse input and determine dataset path
    path='imagesets';  % Base directory containing all image folders
    
    % Handle numeric index: find the Nth folder in imagesets/
    if isnumeric(filename)
        dataset_idx=filename;
        
        % Scan imagesets directory for all subdirectories
        imgsFolderContents = dir(path);
        imgsFolderContents = imgsFolderContents([imgsFolderContents.isdir]); % Keep only directories
        imgsFolderContents = imgsFolderContents(~ismember({imgsFolderContents.name},{'.','..'})); % Remove . and ..
        
        % Validate index is in range
        if dataset_idx < 1 || dataset_idx > length(imgsFolderContents)
            error('Dataset index %d is out of range. Valid range: 1-%d', dataset_idx, length(imgsFolderContents));
        end
        
        % Get folder name for this index
        dataset_name = imgsFolderContents(dataset_idx).name;
    else
        % Handle string path: extract dataset name from path
        if strcmp(filename(end),'/')
            filename=filename(1:end-1);  % Remove trailing slash
        end
        [path,dataset_name,~]=fileparts(filename);
        disp(['path ',path,' dataset ',dataset_name])
        dataset_idx = -1; % Not used when string path provided
    end
    
    %% Load dataset-specific parameters or use defaults
    % Parameters control the stitching behavior for each dataset
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
    
    % Default parameters for unknown/new datasets
    default_focus = 800;        % Focal length suitable for typical phone cameras
    default_full360 = 0;        % Not a 360° panorama
    default_unordered = 0;      % Assume images are in correct sequence
    
    % Select parameters: use custom if known, otherwise use defaults
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
    
    size_bound=400.0;  % Resize images to this max dimension for faster processing
    
    %% Initialize VLFeat library for SIFT feature detection
    run('lib/vlfeat-0.9.20/toolbox/vl_setup');
    disp(['creating panorama for ',dataset_name]);
    disp(['  focal length: ', num2str(f), ', 360: ', num2str(full), ', unordered: ', num2str(is_unordered)]);
    
    %% Load images from dataset folder
    s=imageSet(fullfile(path,dataset_name));
    img=read(s,1);  % Read first image to determine dimensions
    size_1=size(img,1);
    
    % Resize images if they're too large (for faster processing)
    if size_1>size_bound
        img=imresize(img,size_bound/size_1);
    end
    
    % Pre-allocate array for all resized images
    imgs=zeros(size(img,1),size(img,2),size(img,3),s.Count,'like',img);
    
    % Load and resize all images
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

    %% Order images if they're not in sequence
    % Some datasets have images in random order and need to be sorted
    if is_unordered
        t=cputime;
        disp('ordering unordered images');
        imgs=imorder(imgs);
        disp([int2str(cputime-t),' sec']);
    end

    %% Create panorama using the main pipeline
    panorama=create( imgs, f, full);
    
    %% Save results to disk
    imwrite(panorama,['./results/',dataset_name,'.jpg']);
    if is_unordered
        imwrite(panorama,['./results/',dataset_name,'_from_unordered.jpg']);
    end