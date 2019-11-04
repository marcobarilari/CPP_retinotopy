function Parameters = SetParameters(Subj, Run, Task, Stim)

Parameters = struct;    % Initialize the parameters variable

Subj = ['sub-', sprintf('%2.2d', Subj)];
Parameters.Subj = Subj;

Run = ['run-', sprintf('%2.2d', Run)];
Parameters.Run = Run;

Parameters.Task = ['task-' Task];


%% Output
Parameters.TargetDir = fullfile(fileparts(mfilename), 'output');


%% Splash screens
Parameters.Welcome = 'Please fixate the red dot at all times!';   % Welcome message
Parameters.Instruction = 'Press the button everytime it turns blue!';  % Instruction message

%% Engine parameters
Parameters.Screen = max(Screen('Screens')); % Main screen
Parameters.Resolution = [0 0 800 600]; % Resolution
Parameters.Foreground = [0 0 0]; % Foreground colour
Parameters.Background = [127 127 127]; % Background colour
Parameters.FontSize = 20; % Size of font
Parameters.FontName = 'Comic Sans MS'; % Font to use


%% Scanner parameters
Parameters.TR = 3; % Seconds per volume
Parameters.NumberOfSlices = 36; % Number of slices
Parameters.Dummies = 0; % Dummy volumes
Parameters.Overrun = 10; % Dummy volumes at end

%% Experiment parameters
Parameters.viewDist = 30; % viewing distance from eyes to screen
Parameters.xWidthScreen = 21.5; % horizontal width of screen
Parameters.CyclesPerExpmt = 1; % Stimulus cycles per run
Parameters.VolsPerCycle = ceil(10/Parameters.TR); % Volumes per cycle , standard is to have VolsPerCycle * TR ~ 1 min
Parameters.ProbOfEvent = 0.05; % Probability of a target event
Parameters.EventDuration = 0.2; % Duration of a target event
Parameters.EventSize = 1; % diameter of target circle in degrees VA
Parameters.EventColor = [255 0 0]; % rgb
Parameters.FixCrossSize = 1; % in degrees VA


%% Experiment parameters for drifting bar
Parameters.VolumesPerTrial = 12;
Parameters.NumberSlices = 40;


%% Eyetracker parameters
Parameters.Eyetracker.Do = 0;
Parameters.Eyetracker.Host = '10.41.111.213';  % SMI machine ip: '10.41.111.213'
Parameters.Eyetracker.Port = 4444;
Parameters.Eyetracker.Window = 1;


%% Compute some parameters

% Create the output folders if not already present
Parameters.OutputDir = fullfile(Parameters.TargetDir, Subj, 'func');
if ~exist(Parameters.OutputDir, 'dir')
    mkdir(Parameters.OutputDir);
end

% create base name for output files
DateFormat = 'yyyymmdd-HHMM';
Parameters.OutputFilename = fullfile(Parameters.OutputDir, ...
    sprintf('%s_%s_%s_%s', ...
    Parameters.Subj, ...
    Parameters.Task, ...
    Parameters.Run, ...
    datestr(now, DateFormat) ) );

% fullpath location of stim file
Parameters.StimFile = fullfile(fileparts(mfilename), 'input', Stim);

% compute full field of view
Parameters.FOV = GetFOV(Parameters);

% Load stimulus movie
Parameters = LoadStim(Parameters);

end