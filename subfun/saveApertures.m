function saveApertures(saveAps, expParameters, apertures)

    if saveAps

        matFile = fullfile( ...
            expParameters.outputDir, ...
            strrep(expParameters.fileName.events, '.tsv', '_AperturesPRF.mat'));
        if IsOctave
            save(matFile, '-mat7-binary');
        else
            save(matFile, '-v7.3');
        end

        for iApert = 1:size(apertures.Frames, 3)

            tmp = apertures.Frames(:, :, iApert);

            % We skip the all nan frames and print the others
            if ~all(isnan(tmp(:)))

                close all;

                imagesc(apertures.Frames(:, :, iApert));

                colormap gray;

                box off;
                axis off;
                axis square;

                ApertureName = GetApertureName(expParameters, apertures, iApert);

                print(gcf, ...
                    fullfile(expParameters.aperture.targetDir, [ApertureName '.tif']), ...
                    '-dtiff');
            end

        end

    end

end
