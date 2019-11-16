function PARAMETERS = SetParameters(Subj, Run, Task, Stim)

checkDependencies()

% Initialize the parameters variable
PARAMETERS = struct;

% Volumes per cycle - sets the "speed" of the mapping - standard is to have VolsPerCycle * TR ~ 1 min
% e.g PARAMETERS.VolsPerCycle = ceil(60/PARAMETERS.TR);
% PARAMETERS.VolsPerCycle = ceil(5/PARAMETERS.TR);

%% Output directory
PARAMETERS.TargetDir = fullfile(fileparts(mfilename('fullpath')), 'output');
% PARAMETERS.TargetDir = fullfile(fileparts(mfilename('fullpath')), 'output');


%% Splash screens
PARAMETERS.Welcome = 'Please fixate the black dot at all times!';
PARAMETERS.Instruction = 'Press the button everytime it changes color!';


%% feedback screens
PARAMETERS.Hit = 'You responded %i / %i times when there was a target.';
PARAMETERS.Miss = 'You did not respond %i / %i times when there was a target.';
PARAMETERS.FA = 'You responded %i times when there was no target.';
PARAMETERS.RespWin = 2; % duration of the response window


%% Engine parameters
% Screen used to display
% PARAMETERS.Screen = max(Screen('Screens'));
PARAMETERS.Screen = max(Screen('Screens'));
% Resolution [width height refresh_rate]
PARAMETERS.Resolution = [800 600 60];
% Foreground colour
PARAMETERS.Foreground = [0 0 0];
% Background colour
PARAMETERS.Background = [127 127 127];
% Size of font
PARAMETERS.FontSize = 40;
% Font to use
PARAMETERS.FontName = 'Comic Sans MS';

PARAMETERS.ScreenCapture = true;


%% Scanner parameters
% Seconds per volume
PARAMETERS.TR = 1;
% Dummy volumes
PARAMETERS.Dummies = 0;


%% Experiment parameters
% viewing distance from eyes to screen (cm)
PARAMETERS.viewDist = 30;
% horizontal width of screen (cm)
PARAMETERS.xWidthScreen = 21.5;

PARAMETERS.FixationSize = .15; % in degrees VA

% Target parameters
% Changing those parameters might affect participant's performance
% Need to find a set of parameters that give 85-90% accuracy.

% Probability of a target event
PARAMETERS.ProbOfEvent = 0.1;
% Duration of a target event in ms
PARAMETERS.EventDuration = 0.15;
% diameter of target circle in degrees VA
PARAMETERS.EventSize = .15;
% rgb color of the target
PARAMETERS.EventColor = [255 200 200];
% is the fixation dot the only possible location of the target?
% setting this to true might induce more saccade (not formally tested)
PARAMETERS.EventCentral = true;


%% Eyetracker parameters
% do we use an eyetracker ?
PARAMETERS.Eyetracker.Do = false;

PARAMETERS.Eyetracker.Host = '10.41.111.213';  % SMI machine ip: '10.41.111.213'
PARAMETERS.Eyetracker.Port = 4444;
PARAMETERS.Eyetracker.Window = 1;


%% Saving aperture parameters (for pRF)
PARAMETERS.Aperture.TargetDir = fullfile(PARAMETERS.TargetDir, 'stimuli');
PARAMETERS.Aperture.Dimension = 200;


%% Compute some parameters

Subj = ['sub-', sprintf('%2.2d', Subj)];
PARAMETERS.Subj = Subj;

Run = ['run-', sprintf('%2.2d', Run)];
PARAMETERS.Run = Run;

PARAMETERS.Task = ['task-' Task];

% create the output folders if not already present
% stick to BIDS structure (might need to implement session)
PARAMETERS.OutputDir = fullfile(PARAMETERS.TargetDir, Subj, 'func');
[~,~,~] = mkdir(PARAMETERS.OutputDir);

% create base name for output files
% departure from BIDS specification: append dates to base filenae
DateFormat = 'yyyymmdd-HHMM';
PARAMETERS.OutputFilename = fullfile(PARAMETERS.OutputDir, ...
    sprintf('%s_%s_%s_%s', ...
    PARAMETERS.Subj, ...
    PARAMETERS.Task, ...
    PARAMETERS.Run, ...
    datestr(now, DateFormat) ) );

% fullpath location of stim file
PARAMETERS.StimFile = fullfile(fileparts(mfilename), 'input', Stim);

% compute full field of view
PARAMETERS.FOV = GetFOV(PARAMETERS);

% Load stimulus movie
PARAMETERS = LoadStim(PARAMETERS);

% for octave: to prevent output being presented one screen at a time
if IsOctave
    more off
    pkg load image
end

end