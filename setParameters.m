function [cfg] = setParameters(cfg)

    cfg.verbose = false;

    cfg.debug.transpWin = false;
    cfg.debug.smallWin = false;

    cfg.dir.output = fullfile(fileparts(mfilename('fullpath')), 'output');

    %% Splash screens
    cfg.welcome = 'Please fixate the black dot at all times!';
    cfg.task.instruction = 'Press the button everytime it changes color!';

    %% Feedback screens
    cfg.hit = 'You responded %i / %i times when there was a target.';
    cfg.miss = 'You did not respond %i / %i times when there was a target.';
    cfg.fa = 'You responded %i times when there was no target.';
    cfg.respWin = 2; % duration of the response window

    %% Experiment parameters
    [cfg] = setMonitor(cfg);
    [cfg] = setMRI(cfg);
    [cfg] = setKeyboards(cfg);

    % Target parameters
    % Changing those parameters might affect participant's performance
    % Need to find a set of parameters that give 85-90% accuracy.

    % Probability of a target event
    cfg.target.probability = 0.02;
    % Duration of a target event in ms
    cfg.target.duration = 0.1;
    % diameter of target circle in degrees VA
    cfg.target.size = .15;
    % rgb color of the target
    cfg.target.color = [255 100 100];
    % is the fixation dot the only possible location of the target?
    % setting this to true might induce more saccade (not formally tested)
    cfg.target.central = true;

    % Background image rotates
    cfg.rotateStimulus = true;
    % Angle rotation back & forth
    cfg.sineRotation = 10;

    % Stimulus cycles per run
    cfg.cyclesPerExpmt = 5;

    % Volumes per cycle - sets the "speed" of the mapping -
    % standard is to have VolsPerCycle * TR ~ 1 min
    % e.g expParameters.VolsPerCycle = ceil(60/expParameters.TR);
    % expParameters.VolsPerCycle = ceil(5/expParameters.TR);
    cfg.volsPerCycle = 20;

    cfg.fixation.type = 'bestFixation'; % dot bestFixation
    cfg.fixation.width = .15; % in degrees VA

    %% Eyetracker parameters
    cfg.eyeTracker.do = false;

    %% Saving aperture parameters (for pRF)
    cfg.aperture.outputDir = fullfile(cfg.dir.output, 'stimuli');
    cfg.aperture.dimension = 200;

    %% Stimulus movie
    cfg.stimFile = fullfile(fileparts(mfilename), 'input', cfg.stim);

    %% DO NOT TOUCH
    if cfg.debug.do
        cfg.cyclesPerExpmt = 4;
    end

    cfg.audio.do = false;

    cfg.extraColumns.x_target_pos = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'x position of the the target', ...
        'Units', 'degrees of visual angles'));

    cfg.extraColumns.y_target_pos = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'y position of the the target', ...
        'Units', 'degrees of visual angles'));

    cfg.extraColumns.target_width = struct( ...
        'length', 1, ...
        'bids', struct( ...
        'LongName', 'diameter of the the target', ...
        'Units', 'degrees of visual angles'));

end

function [cfg] = setKeyboards(cfg)
    cfg.keyboard.escapeKey = 'ESCAPE';
    cfg.keyboard.responseKey = { ...
        'r', 'g', 'y', 'b', ...
        'd', 'n', 'z', 'e', ...
        't'}; % dnze rgyb
    cfg.keyboard.keyboard = [];
    cfg.keyboard.responseBox = [];

    if strcmpi(cfg.testingDevice, 'mri')
        cfg.keyboard.keyboard = [];
        cfg.keyboard.responseBox = [];
    end
end

function [cfg] = setMRI(cfg)
    % letter sent by the trigger to sync stimulation and volume acquisition
    cfg.mri.triggerKey = 't';
    cfg.mri.triggerNb = 5;
    cfg.mri.repetitionTime = 1.8;

    cfg.bids.MRI.Instructions = 'Press the button everytime a red dot appears!';
    cfg.bids.MRI.TaskDescription = [];

end

function [cfg, expParameters] = setMonitor(cfg, expParameters)

    % Monitor parameters for PTB
    cfg.color.white = [255 255 255];
    cfg.color.black = [0 0 0];
    cfg.color.red = [255 0 0];
    cfg.color.grey = mean([cfg.color.black; cfg.color.white]);
    cfg.color.background = [127 127 127];
    cfg.color.foreground = cfg.color.black;

    % Monitor parameters
    cfg.screen.monitorWidth = 42; % in cm
    cfg.screen.monitorDistance = 134; % distance from the screen in cm
    if strcmpi(cfg.testingDevice, 'mri')
        cfg.screen.monitorWidth = 25;
        cfg.screen.monitorDistance = 95;
    end

    % Resolution [width height refresh_rate]
    cfg.screen.resolution = [800 600 60];

    cfg.text.color = cfg.color.black;
    cfg.text.font = 'Courier New';
    cfg.text.size = 18;
    cfg.text.style = 1;

end
