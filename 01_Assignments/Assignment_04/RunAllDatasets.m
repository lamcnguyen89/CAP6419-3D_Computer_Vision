%% RunAllDatasets - Batch process all image folders to create panoramas
%
% DESCRIPTION:
%   Convenience script that automatically discovers all image dataset folders
%   in the imagesets/ directory and processes each one to create panoramas.
%   This is useful for testing the algorithm on multiple datasets at once.
%
% FEATURES:
%   - Automatic folder discovery (no hardcoding needed)
%   - Progress reporting for each dataset
%   - Error handling (continues if one dataset fails)
%   - Visual display of results in separate figure windows
%   - Saves all results to results/ folder
%
% USAGE:
%   Simply run this script:
%   >> RunAllDatasets
%
% OUTPUT:
%   - One figure window per dataset showing the panorama
%   - JPEG files saved in results/ folder
%   - Console output showing progress and timing
%
% NOTES:
%   - Processing time depends on number of images and their sizes
%   - Each dataset uses parameters defined in main.m
%   - Results are automatically saved even if display fails
%

clear; clc; close all;

%% Discover all image folders in imagesets directory
imgs_path = 'imagesets';

% Scan directory for subdirectories (each is a dataset)
imgsFolderContents = dir(imgs_path);
imgsFolderContents = imgsFolderContents([imgsFolderContents.isdir]); % Keep only directories
imgsFolderContents = imgsFolderContents(~ismember({imgsFolderContents.name},{'.','..'})); % Remove . and ..

% Display discovered datasets
numDatasets = length(imgsFolderContents);
fprintf('Found %d image folders in "%s" directory:\n', numDatasets, imgs_path);
for i = 1:numDatasets
    fprintf('  %d. %s\n', i, imgsFolderContents(i).name);
end
fprintf('\n');

%% Process each dataset sequentially
for i = 1:numDatasets
    try
        % Progress header
        fprintf('========================================\n');
        fprintf('Processing dataset %d of %d: %s\n', i, numDatasets, imgsFolderContents(i).name);
        fprintf('========================================\n');
        
        % Call main() with dataset index
        panorama = main(i);
        
        % Display result in new figure window
        figure('Name', sprintf('Panorama %d: %s', i, imgsFolderContents(i).name));
        imshow(panorama);
        title(sprintf('%s', imgsFolderContents(i).name), 'Interpreter', 'none');
        
        fprintf('Successfully created panorama for %s\n\n', imgsFolderContents(i).name);
    catch ME
        % Error handling: report error but continue with next dataset
        fprintf('ERROR processing %s:\n', imgsFolderContents(i).name);
        fprintf('  %s\n\n', ME.message);
        % Continue to next dataset instead of stopping
        continue;
    end
end

%% Summary
fprintf('========================================\n');
fprintf('Completed processing all datasets\n');
fprintf('========================================\n');