 function DriftingBars(Subj_ID, Stim, Emul)
%DriftingBars(Subj_ID, Stim, Emul)
%
% Drifting bars for mapping population receptive fields
%   Subj :  String with subject ID
%   Stim :  Stimulus file name e.g. 'Checkerboard'
%   Emul :  0 = Triggered by scanner, 1 = Trigger by keypress
%

if nargin == 0
    Subj_ID = 'Demo';
    Stim = 'Ripples';
    Emul = 1;
end
addpath('Common_Functions');
Parameters = struct;    % Initialize the parameters variable

%% Engine parameters
Parameters.Screen=0;    % Main screen
Parameters.Resolution=[ 0 0 1920 1200];  % Resolution
Parameters.Foreground=[0 0 0];  % Foreground colour
Parameters.Background=[127 127 127];    % Background colour
Parameters.FontSize = 20;   % Size of font
Parameters.FontName = 'Comic Sans MS';  % Font to use

%% Scanner parameters
Parameters.TR=3.06;    % Seconds per volume
Parameters.Number_of_Slices=36; % Number of slices
Parameters.Dummies=4;   % Dummy volumes
Parameters.Overrun=0.5;   % Dummy volumes at end

%% Subject & session 
Parameters.Subj_ID = Subj_ID;   % Subject ID
[Parameters.Session Parameters.Session_name] = CurrentSession([Parameters.Subj_ID '_pRF']);   % Determine next session
Parameters.Welcome = 'Please fixate the red dot at all times!';   % Welcome message
Parameters.Instruction = 'Press the button everytime it turns blue!';  % Instruction message

%% Experimental Parameters
Parameters.Volumes_per_Trial = 20;  % Duration of trial in volumes
Parameters.Bar_Width = 120; % Width of bar in pixels
Parameters.Conditions = [90 45 0 135 270 225 180 315];  % Stimulus conditions in each block defined by number
Parameters.Prob_of_Event = 0.01;  % Probability of a target event
Parameters.Event_Duration = 0.2;  % Duration of a target event
% Load stimulus movie
load(Stim);
Parameters.Stimulus = Stimulus; % Stimulus movie
Parameters.Refreshs_per_Stim = StimFrames;  % Video frames per stimulus frame
Parameters.Sine_Rotation = 0;  % Rotating movie back & forth by this angle

%% Run the experiment
BarsMapping(Parameters, Emul);
