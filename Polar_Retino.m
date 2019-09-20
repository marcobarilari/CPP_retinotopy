function Polar_Retino(Subj, Direc, Stim, Emul)
%Polar(Subj, Direc, Stim, Emul)
%
% Polar mapping
%   Subj :  String with subject ID
%   Direc : '+' or '-' for clockwise/expanding or anticlockwise/contracting
%   Stim :  Stimulus file name e.g. 'Checkerboard'
%   Emul :  0 = Triggered by scanner, 1 = Trigger by keypress
%

if nargin == 0
    Subj = 'Demo';
    Direc = '+';
    Stim = 'Checkerboard';
    Emul = 1;
end
if isempty(Subj);
    %select subj
    sub_id = input('Which subject number? ', 's');
    day = input('Day? ', 's');
    run = input('Run? ', 's');
    Subj = ['Subj' sub_id, '_Day' day '_Run' run];
    viewingDist_base = 78; 
    distanceEyeMark = input('Distance from eye to black mark? ');
    distanceEyeCoil = input('Distance from eye to coil? ');
    viewingDist = viewingDist_base + distanceEyeMark + distanceEyeCoil;
else
    Subj = Subj; %#ok<ASGSL>
    viewingDist = 25;
end;

saveDir = ['/Users/joana/Documents/TMS-fMRI/Data/Subj' sub_id '/Day' day];
nameFile = ['Retinotopy_' Subj '_' Stim '_Polar' Direc];

if exist(saveDir,'dir') == 0
    mkdir(saveDir)
elseif ~isempty(dir([saveDir '/' nameFile]))
    disp('This file already exists for current subject!');
    overwrite = input('Do you want to continue anyway? (y/n) ','s');    
    if overwrite == 'n'
        return;
    end
end


addpath('Common_Functions');
Parameters = struct;    % Initialize the parameters variable

%% Engine parameters
screenid = max(Screen('Screens'));
Parameters.Screen=screenid;    % Main screen
Parameters.Resolution=[0 0 800 600];   % Resolution
Parameters.Foreground=[0 0 0];  % Foreground colour
Parameters.Background=[127 127 127];    % Background colour
Parameters.FontSize = 20;   % Size of font
Parameters.FontName = 'Comic Sans MS';  % Font to use

%% Scanner parameters
Parameters.TR=2.480;    % Seconds per volume
Parameters.Number_of_Slices=42; % Number of slices
Parameters.Dummies=3;   % Dummy volumes
Parameters.Overrun=3;   % Dummy volumes at end

%% Experiment parameters
Parameters.Cycles_per_Expmt=9;  % Stimulus cycles per run
Parameters.Vols_per_Cycle= ceil(42/Parameters.TR);   % Volumes per cycle , standard is to have noVolsPerCycle * TR ~ 1 min
Parameters.Prob_of_Event=0.05;  % Probability of a target event
Parameters.Event_Duration=0.2;  % Duration of a target event
Parameters.Event_Size=15;  % Width of target circle
Parameters.Event_Color = [255 0 0]; % rgb
Parameters.Apperture='Wedge';   % Stimulus type
Parameters.Apperture_Width=70;  % Width of wedge in degrees
Parameters.Direction=Direc; % Direction of cycling
Parameters.Rotate_Stimulus=true;    % Does image rotate?
Parameters.viewDist = viewingDist; % viewing distance from eyes to screen
Parameters.xWidthScreen = 35; % horizontal width of screen
Parameters.FOV = 2* atan(Parameters.xWidthScreen/2/Parameters.viewDist)*180/pi; % left-to-right angle of visual field in scanner in degree
% Load stimulus movie
load(Stim);
if strcmpi(Stim, 'Checkerboard')
    Parameters.Stimulus(:,:,1)=Stimulus;
    Parameters.Stimulus(:,:,2)=uint8(InvertContrastCogent(CogentImage(Stimulus))*255);
else
    Parameters.Stimulus=Stimulus;
end
Parameters.Rotate_Stimulus=true;   % Image rotates
Parameters.Refreshs_per_Stim=StimFrames;  % Video frames per stimulus frame
Parameters.Sine_Rotation=0;  % No rotation back & forth 

%% Various parameters
Parameters.Instruction='Bitte immer Kreuz fixieren!\n\nDruecke bei rotem Kreis!';
[Parameters.Session Parameters.Session_name]=CurrentSession([saveDir '/' nameFile]); % Determine current session
Parameters.Subj = Subj;

%% Run the experiment
 Retinotopic_Mapping(Parameters, Emul);
