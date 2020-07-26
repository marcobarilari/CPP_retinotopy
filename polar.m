function polar(direc, stim, emul, debug)
    % Polar mapping: does the retinotopy with a rotating wedge
    %   direc : '+' or '-' for clockwise or anticlockwise
    %   stim :  Stimulus file name e.g. 'Checkerboard'
    %   emul :  0 = Triggered by scanner, 1 = Trigger by keypress
    %   debug : will play the experiment with PTB transparency

    if nargin < 1
        direc = '-';
    end
    if nargin < 2
        stim = 'Checkerboard.mat';
    end
    if nargin < 3
        emul = 1;
    end
    if nargin < 4
        debug = 1;
    end

    initEnv();

    %% Experiment parameters

    expParameters.task = 'retinotopyPolar';

    % Stimulus type
    expParameters.aperture.type = 'Wedge';
    % Width of wedge in degrees
    expParameters.aperture.width = 70;
    % Direction of cycling
    expParameters.direction = direc;

    %% Set defaults

    expParameters.stim = stim;
    cfg.debug = debug;

    if ~emul
        cfg.testingDevice = 'mri';
    else
        cfg.testingDevice = 'pc';
    end

    expParameters.extraColumns.angle = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'position of the center of the wedge', ...
        'Units', 'degrees'));

    expParameters.extraColumns.wedge_angle = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'angular width of the wedge', ...
        'Units', 'degrees'));

    [cfg, expParameters] = setParameters(cfg, expParameters);

    %% Run the experiment
    [data, expParameters] = retinotopicMapping(cfg, expParameters);

    %     plotResults(data, expParameters);

end
