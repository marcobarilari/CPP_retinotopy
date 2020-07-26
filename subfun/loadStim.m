function expParameters = loadStim(expParameters)

    load(expParameters.stimFile);

    [~, file] = fileparts(expParameters.stimFile);
    if strcmpi(file, 'Checkerboard')

        expParameters.stimulus(:, :, 1) = Stimulus;
        expParameters.stimulus(:, :, 2) = uint8(invertContrastCogent(cogentImage(Stimulus)) * 255);

    else

        expParameters.stimulus = Stimulus;

    end

    expParameters.refreshPerStim = StimFrames;  % Video frames per stimulus frame

end

function ImgCogent = cogentImage(Img8bit)
    % ImgCogent = CogentImage(Img8bit)
    % Converts the 8 bit image (0-255) into a cogent image (0-1).

    ImgCogent = (double(Img8bit) + 1) / 256;
end

function imgOut = invertContrastCogent(imgIn)
    % imgOut = InvertContrastCogent(imgIn)
    % Inverts the contrast of a greyscale image.

    imgOut = abs(imgIn - 1);
end
