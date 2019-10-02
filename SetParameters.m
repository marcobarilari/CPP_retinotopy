function [Parameters] = SetParameters(Subj)

Parameters = struct;    % Initialize the parameters variable

%% Subject & session 
Parameters.Subj = Subj;   % Subject ID
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
Parameters.VolsPerCycle = ceil(60/Parameters.TR); % Volumes per cycle , standard is to have noVolsPerCycle * TR ~ 1 min
Parameters.ProbOfEvent = 0.05; % Probability of a target event
Parameters.EventDuration = 0.2; % Duration of a target event
Parameters.EventSize = 15; % Width of target circle
Parameters.EventColor = [255 0 0]; % rgb

%% Eyetracker parameters
Parameters.Eyetracker.Do = 0;
Parameters.Eyetracker.Host = '10.41.111.213';  % SMI machine ip: '10.41.111.213'
Parameters.Eyetracker.Port = 4444;
Parameters.Eyetracker.Window = 1;


Parameters.FOV = GetFOV(Parameters);

end