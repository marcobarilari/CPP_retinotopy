function SaveApertures(SaveAps, PARAMETERS, Apertures)

if SaveAps
    if IsOctave
        save([PARAMETERS.OutputFilename '_AperturesPRF.mat'], '-mat7-binary', 'Apertures', 'PARAMETERS');
    else
        save([PARAMETERS.OutputFilename '_AperturesPRF.mat'], '-v7.3', 'Apertures', 'PARAMETERS');
    end
    
    for iApert = 1:size(Apertures.Frames, 3)
        
        tmp = Apertures.Frames(:, :, iApert);
        
        %We skip the all nan frames and print the others
        if ~all(isnan(tmp(:)))
            
            close all
            
            imagesc(Apertures.Frames(:, :, iApert))
            
            colormap gray
            
            box off
            axis off
            axis square
            
            ApertureName = GetApertureName(PARAMETERS, Apertures, iApert);
            
            print(gcf, fullfile(PARAMETERS.Aperture.TargetDir, [ApertureName '.tif']), '-dtiff');
        end
        
    end
    
end

end