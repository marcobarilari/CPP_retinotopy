function PARAMETERS = LoadStim(PARAMETERS)

    load(PARAMETERS.StimFile);

    [~, file] = fileparts(PARAMETERS.StimFile);
    if strcmpi(file, 'Checkerboard')

        PARAMETERS.Stimulus(:, :, 1) = Stimulus;
        PARAMETERS.Stimulus(:, :, 2) = uint8(InvertContrastCogent(CogentImage(Stimulus)) * 255);

    else

        PARAMETERS.Stimulus = Stimulus;

    end

    PARAMETERS.RefreshPerStim = StimFrames;  % Video frames per stimulus frame

end
