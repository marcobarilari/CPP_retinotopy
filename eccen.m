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

    cfg.task.name = 'retinotopy eccen';

    % Stimulus type
    cfg.aperture.type = 'ring';
    % Width of wedge in degrees
    cfg.aperture.width = 1;
    % Direction of cycling
    cfg.direction = direc;

    %% Set defaults

    cfg.stim = stim;
    cfg.debug.do = debug;

    if ~emul
        cfg.testingDevice = 'mri';
    else
        cfg.testingDevice = 'pc';
    end

    cfg.extraColumns.ring_inner_rim = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'position of the inner rim of the ring', ...
        'Units', 'degrees  of visual angles'));
    cfg.extraColumns.ring_outer_rim = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'position of the outer rim of the ring', ...
        'Units', 'degrees  of visual angles'));

    [cfg] = setParameters(cfg);

    %% Run the experiment
    [data, cfg] = retinotopicMapping(cfg);

    %     plotResults(data, expParameters);

end
