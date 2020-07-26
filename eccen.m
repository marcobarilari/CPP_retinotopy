function eccen(direc, stim, emul, debug)
    % Eccentricity mapping: does the retinotopy with an contracting or
    % expanding ring
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

    expParameters.task = 'retinotopyEccen';

    % Stimulus type
    expParameters.aperture.type = 'Ring';
    % Width of wedge in degrees
    expParameters.aperture.width = 1;
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

    expParameters.extraColumns.ring_inner_rim = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'position of the inner rim of the ring', ...
        'Units', 'degrees  of visual angles'));
    expParameters.extraColumns.ring_outer_rim = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'position of the outer rim of the ring', ...
        'Units', 'degrees  of visual angles'));

    [cfg, expParameters] = setParameters(cfg, expParameters);

    %% Run the experiment
    [data, expParameters] = retinotopicMapping(cfg, expParameters);

    %     plotResults(data, expParameters);

end
