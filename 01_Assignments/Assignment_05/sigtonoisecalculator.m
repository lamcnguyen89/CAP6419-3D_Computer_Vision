function sigtonoisecalculator()
    close all
    clear all
    
    % Define folder containing the figures
    figureFolder = 'SNR_Input_Figures';
    
    % Define file arrays
    % Make sure the order matches between ground truth and reconstructed files
    groundTruthFiles = {
        'triangulate_3d_plot_globe_perspective.fig';
        'triangulate_3d_plot_Newkuba_perspective.fig';
        'triangulate_3d_plot_Piano_perspective.fig';
        'triangulate_3d_plot_Playroom_perspective.fig'
    };
    
    reconstructedFiles = {
        'linkbackproj_globe_3d_reconstruction.fig';
        'linkbackproj_Newkuba_3d_reconstruction.fig';
        'linkbackproj_Piano_3d_reconstruction.fig';
        'linkbackproj_Playroom_3d_reconstruction.fig'
    };
    
    datasetNames = {'globe', 'Newkuba', 'Piano', 'Playroom'};
    
    % Loop through each dataset
    fprintf('\n========================================\n');
    fprintf('SNR Calculation for All Datasets\n');
    fprintf('========================================\n');
    
    for idx = 1:length(groundTruthFiles)
        fprintf('\nDataset: %s\n', datasetNames{idx});
        
        groundTruthFile = fullfile(figureFolder, groundTruthFiles{idx});
        reconstructedFile = fullfile(figureFolder, reconstructedFiles{idx});
        
        % Load figures
        fig1 = openfig(groundTruthFile, 'invisible');
        fig2 = openfig(reconstructedFile, 'invisible');
        
        % Extract 3D scatter plot data from ground truth figure
        ax1 = findobj(fig1, 'Type', 'axes');
        scatter1 = findobj(ax1, 'Type', 'scatter');
        if isempty(scatter1)
            warning('No scatter plot found in ground truth figure for %s', datasetNames{idx});
            close(fig1);
            close(fig2);
            continue;
        end
        ReferencePoints = [scatter1.XData; scatter1.YData; scatter1.ZData];
        
        % Extract 3D scatter plot data from reconstructed figure
        ax2 = findobj(fig2, 'Type', 'axes');
        scatter2 = findobj(ax2, 'Type', 'scatter');
        if isempty(scatter2)
            warning('No scatter plot found in reconstructed figure for %s', datasetNames{idx});
            close(fig1);
            close(fig2);
            continue;
        end
        ReconstructedPoints = [scatter2.XData; scatter2.YData; scatter2.ZData];
        
        % Find nearest neighbor distances
        distances = zeros(1, size(ReconstructedPoints, 2));
        for i = 1:size(ReconstructedPoints, 2)
            % Find closest point in reference
            diffs = ReferencePoints(1:3, :) - ReconstructedPoints(1:3, i);
            point_distances = sqrt(sum(diffs.^2, 1));
            distances(i) = min(point_distances);
        end
        
        % Signal: spread of reference points
        signal = mean(sqrt(sum(ReferencePoints(1:3, :).^2, 1)));
        
        % Noise: mean nearest-neighbor distance
        noise = mean(distances);
        
        SNR_dB = 20 * log10(signal / noise);
        
        % Display results
        fprintf('  SNR: %.2f dB\n', SNR_dB);
        
        % Close invisible figures
        close(fig1);
        close(fig2);
    end
    
    fprintf('\n========================================\n');
end