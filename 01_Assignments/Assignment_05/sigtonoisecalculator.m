function sigtonoisecalculator()
    close all
    clear all
    
    % Define folder containing the figures
    figureFolder = 'SNR_Input_Figures';
    
    % Load the ground truth figure (with "triangulate" in filename)
    groundTruthFile = fullfile(figureFolder, 'triangulate_3d_plot_globe_perspective.fig');
    reconstructedFile = fullfile(figureFolder, 'linkbackproj_globe_3d_reconstruction.fig');
    
    fprintf('Loading ground truth figure: %s\n', groundTruthFile);
    fig1 = openfig(groundTruthFile, 'invisible');
    
    fprintf('Loading reconstructed figure: %s\n', reconstructedFile);
    fig2 = openfig(reconstructedFile, 'invisible');
    
    % Extract 3D scatter plot data from ground truth figure
    ax1 = findobj(fig1, 'Type', 'axes');
    scatter1 = findobj(ax1, 'Type', 'scatter');
    if isempty(scatter1)
        error('No scatter plot found in ground truth figure');
    end
    ReferencePoints = [scatter1.XData; scatter1.YData; scatter1.ZData];
    
    % Extract 3D scatter plot data from reconstructed figure
    ax2 = findobj(fig2, 'Type', 'axes');
    scatter2 = findobj(ax2, 'Type', 'scatter');
    if isempty(scatter2)
        error('No scatter plot found in reconstructed figure');
    end
    ReconstructedPoints = [scatter2.XData; scatter2.YData; scatter2.ZData];
    
    fprintf('\nGround truth points: %d\n', size(ReferencePoints, 2));
    fprintf('Reconstructed points: %d\n', size(ReconstructedPoints, 2));
    
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
    fprintf('\nSNR: %.2f dB\n', SNR_dB);
    
    % Close invisible figures
    close(fig1);
    close(fig2);
end