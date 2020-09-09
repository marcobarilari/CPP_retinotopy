function cfg = loadStim(cfg)

    fprintf('Loading file: %s\n', cfg.stimFile);

    load(cfg.stimFile);

    [~, file] = fileparts(cfg.stimFile);
    if strcmpi(file, 'checkerboard')

        cfg.stimulus(:, :, 1) = stimulus;
        cfg.stimulus(:, :, 2) = uint8(invertContrastCogent(cogentImage(stimulus)) * 255);

    else

        cfg.stimulus = stimulus;

    end

    cfg.refreshPerStim = stimFrames;  % Video frames per stimulus frame

    cfg.stimRect = [0 0 size(cfg.stimulus, 2) size(cfg.stimulus, 1)];

end

function imgCogent = cogentImage(Img8bit)
    % ImgCogent = CogentImage(Img8bit)
    % Converts the 8 bit image (0-255) into a cogent image (0-1).

    imgCogent = (double(Img8bit) + 1) / 256;
end

function imgOut = invertContrastCogent(imgIn)
    % imgOut = InvertContrastCogent(imgIn)
    % Inverts the contrast of a greyscale image.

    imgOut = abs(imgIn - 1);
end
