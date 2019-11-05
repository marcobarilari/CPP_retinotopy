function Parameters = SetParameters(Subj, Run, Task, Stim)

% Initialize the parameters variable
Parameters = struct;    


%% Output directory
Parameters.TargetDir = fullfile(fileparts(mfilename), 'output');
% Parameters.TargetDir = fullfile(fileparts(mfilename), 'output');


%% Splash screens
Parameters.Welcome = 'Please fixate the black dot at all times!';  
Parameters.Instruction = 'Press the button everytime it changes color!';


%% Engine parameters
% Screen used to display
% Parameters.Screen = max(Screen('Screens')); 
Parameters.Screen = max(Screen('Screens')); 
% Resolution [width height refresh_rate]
Parameters.Resolution = [2560 1440 60]; 
% Foreground colour
Parameters.Foreground = [0 0 0]; 
% Background colour
Parameters.Background = [127 127 127]; 
% Size of font
Parameters.FontSize = 40; 
% Font to use
Parameters.FontName = 'Comic Sans MS'; 


%% Scanner parameters
% Seconds per volume
Parameters.TR = 3; 
% Number of slices
Parameters.NumberOfSlices = 36; 
% Dummy volumes
Parameters.Dummies = 0; 
% Dummy volumes at end
Parameters.Overrun = 10; 


%% Experiment parameters
% viewing distance from eyes to screen (cm)
Parameters.viewDist = 30; 
% horizontal width of screen (cm)
Parameters.xWidthScreen = 21.5; 
% Stimulus cycles per run
Parameters.CyclesPerExpmt = 2; 
% Volumes per cycle - sets the "speed" of the mapping - standard is to have VolsPerCycle * TR ~ 1 min
% e.g Parameters.VolsPerCycle = ceil(60/Parameters.TR); 
Parameters.VolsPerCycle = ceil(10/Parameters.TR); 
Parameters.FixationSize = .25; % in degrees VA

% Target parameters
% Changing those parameters might affect participant's performance
% Need to find a set of parameters that give 85-90% accuracy.

% Probability of a target event
Parameters.ProbOfEvent = 0.6; 
% Duration of a target event in ms
Parameters.EventDuration = 0.15; 
% diameter of target circle in degrees VA
Parameters.EventSize = 1; 
% rgb color of the target
Parameters.EventColor = [255 127 127]; 
% is the fixation dot the only possible location of the target?
% setting this to true might induce more saccade (not formally tested)
Parameters.EventCentral = false;



%% Experiment parameters for drifting bar
% Might be moved later to the drifting bar script
Parameters.VolumesPerTrial = 12;
Parameters.NumberSlices = 40;


%% Eyetracker parameters
% do we use an eyetracker ?
Parameters.Eyetracker.Do = false; 

Parameters.Eyetracker.Host = '10.41.111.213';  % SMI machine ip: '10.41.111.213'
Parameters.Eyetracker.Port = 4444;
Parameters.Eyetracker.Window = 1;


%% Compute some parameters

Subj = ['sub-', sprintf('%2.2d', Subj)];
Parameters.Subj = Subj;

Run = ['run-', sprintf('%2.2d', Run)];
Parameters.Run = Run;

Parameters.Task = ['task-' Task];

% create the output folders if not already present
 % stick to BIDS structure (might need to implement session)
Parameters.OutputDir = fullfile(Parameters.TargetDir, Subj, 'func');
if ~exist(Parameters.OutputDir, 'dir')
    mkdir(Parameters.OutputDir);
end

% create base name for output files
% departure from BIDS: append dates to base filenae
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

% for octave: to prevent output being presented one screen at a time
more off

end