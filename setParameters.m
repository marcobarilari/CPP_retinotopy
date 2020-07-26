function [cfg, expParameters] = setParameters(cfg, expParameters)

    expParameters.verbose = false;
    cfg.verbose = false;

    if cfg.debug
        cfg.testingTranspScreen = true;
        cfg.testingSmallScreen = false;
    else
        cfg.testingTranspScreen = false;
        cfg.testingSmallScreen = false;
    end

    expParameters.outputDir = fullfile(fileparts(mfilename('fullpath')), 'output');

    %% Splash screens
    expParameters.welcome = 'Please fixate the black dot at all times!';
    expParameters.instruction = 'Press the button everytime it changes color!';

    %% Feedback screens
    expParameters.hit = 'You responded %i / %i times when there was a target.';
    expParameters.miss = 'You did not respond %i / %i times when there was a target.';
    expParameters.fA = 'You responded %i times when there was no target.';
    expParameters.respWin = 2; % duration of the response window

    %% Experiment parameters
    [cfg, expParameters] = setMonitor(cfg, expParameters);
    [cfg, expParameters] = setMRI(cfg, expParameters);
    [cfg, expParameters] = setKeyboards(cfg, expParameters);

    % Target parameters
    % Changing those parameters might affect participant's performance
    % Need to find a set of parameters that give 85-90% accuracy.

    % Probability of a target event
    expParameters.target.probability = 0.1;
    % Duration of a target event in ms
    expParameters.target.duration = 0.15;
    % diameter of target circle in degrees VA
    expParameters.target.size = .15;
    % rgb color of the target
    expParameters.target.color = [255 200 200];
    % is the fixation dot the only possible location of the target?
    % setting this to true might induce more saccade (not formally tested)
    expParameters.target.central = true;

    % Background image rotates
    expParameters.rotateStimulus = true;
    % Angle rotation back & forth
    expParameters.sineRotation = 10;

    % Stimulus cycles per run
    expParameters.cyclesPerExpmt = 3;

    % Volumes per cycle - sets the "speed" of the mapping -
    % standard is to have VolsPerCycle * TR ~ 1 min
    % e.g expParameters.VolsPerCycle = ceil(60/expParameters.TR);
    % expParameters.VolsPerCycle = ceil(5/expParameters.TR);
    expParameters.volsPerCycle = 5;

    expParameters.fixationSize = .15; % in degrees VA

    %% Eyetracker parameters
    cfg.eyeTracker = false;
    %     cfg.eyeTrackerParam.host = '10.41.111.213';  % SMI machine ip: '10.41.111.213'
    %     cfg.eyeTrackerParam.Port = 4444;
    %     cfg.eyeTrackerParam.Window = 1;

    %% Saving aperture parameters (for pRF)
    expParameters.aperture.outputDir = fullfile(expParameters.outputDir, 'stimuli');
    expParameters.aperture.dimension = 200;

    %% Stimulus movie
    expParameters.stimFile = fullfile(fileparts(mfilename), 'input', expParameters.stim);

    %% DO NOT TOUCH
    if cfg.debug
        %         expParameters.verbose = true;
        %         cfg.verbose = true;
        expParameters.cyclesPerExpmt = 3;
    end

    cfg.initAudio = false;

    expParameters.extraColumns.x_target_pos = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'x position of the the target', ...
        'Units', 'degrees of visual angles'));

    expParameters.extraColumns.y_target_pos = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'y position of the the target', ...
        'Units', 'degrees of visual angles'));

    expParameters.extraColumns.target_width = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'diameter of the the target', ...
        'Units', 'degrees of visual angles'));

end

function [cfg, expParameters] = setKeyboards(cfg, expParameters)
    cfg.keyboard.escapeKey = 'ESCAPE';
    cfg.keyboard.responseKey = {'space'};
    cfg.keyboard.keyboard = [];
    cfg.keyboard.responseBox = [];

    if strcmpi(cfg.testingDevice, 'mri')
        cfg.keyboard.keyboard = [];
        cfg.keyboard.responseBox = [];
    end
end

function [cfg, expParameters] = setMRI(cfg, expParameters)
    % letter sent by the trigger to sync stimulation and volume acquisition
    cfg.triggerKey = 't';
    cfg.numTriggers = 4;
    cfg.triggerString = 'Waiting for the scanner';

    expParameters.bids.MRI.RepetitionTime = 1;
    expParameters.bids.MRI.Instructions = '';
    expParameters.bids.MRI.TaskDescription = [];

end

function [cfg, expParameters] = setMonitor(cfg, expParameters)

    % Monitor parameters for PTB
    cfg.white = [255 255 255];
    cfg.black = [0 0 0];
    cfg.red = [255 0 0];
    cfg.grey = mean([cfg.black; cfg.white]);
    cfg.backgroundColor = [127 127 127];
    cfg.foregroundColor = cfg.black;

    % Monitor parameters
    cfg.monitorWidth = 42; % in cm
    cfg.screenDistance = 134; % distance from the screen in cm

    % Resolution [width height refresh_rate]
    cfg.resolution = [800 600 60];

    cfg.text.color = cfg.black;
    cfg.text.font = 'Courier New';
    cfg.text.size = 18;
    cfg.text.style = 1;

    if strcmpi(cfg.testingDevice, 'mri')
        cfg.monitorWidth = 42;
        cfg.screenDistance = 134;
    end
end
