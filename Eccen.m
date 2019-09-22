function Eccen(Subj, Direc, Stim, Emul)
%Eccen(Subj, Direc, Stim, Emul)
%
% Eccentricity mapping
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


if isempty(Subj)
    SubjNb = input('Subject number? ');  
    Run = input('Retinotopic run number? ');  
    Subj = ['Sub-', sprintf('%2.2d', SubjNb), '_Run_' num2str(Run)];    
end


if ismac
    saveDir = fullfile(pwd, 'Subjects_Data', strcat('Subject_', sprintf('%2.2d', SubjNb)));
elseif ispc
    % saveDir = '\\uni\trohe\w2kdata\PhD\Experiments\Exp1_VE_fMRI\Retinotopy\Retinotopy_StimToolbox\Results\';
end

% Create the mandatory folders if not already present
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end


DateFormat = 'yyyy_mm_dd_HH_MM';

nameFile = strcat('Retinotopy_Subject_', sprintf('%2.2d', SubjNb), '_Run_', num2str(Run), '_', Stim, '_Eccen_', Direc, '_', datestr(now, DateFormat)); 


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
Parameters.TR=3;    % Seconds per volume
Parameters.Number_of_Slices=36; % Number of slices
Parameters.Dummies=0;   % Dummy volumes
Parameters.Overrun=10;   % Dummy volumes at end

%% Experiment parameters
Parameters.Cycles_per_Expmt=9;  % Stimulus cycles per run
Parameters.Vols_per_Cycle= ceil(60/Parameters.TR);   % Volumes per cycle 
Parameters.Prob_of_Event=0.05;  % Probability of a target event
Parameters.Event_Duration=0.2;  % Duration of a target event
Parameters.Event_Size=15;  % Width of target circle
Parameters.Event_Color = [255 0 0]; % rgb
Parameters.Apperture='Ring';    % Stimulus type
Parameters.Apperture_Width=0.5;  % Width of ring in degree of visual field at time = 0
Parameters.Direction=Direc; % Direction of cycling

Parameters.viewDist = 30; % viewing distance from eyes to screen
Parameters.xWidthScreen = 21.5; % horizontal width of screen
Parameters.FOV = 2* atan(Parameters.xWidthScreen/2/Parameters.viewDist)*180/pi; % left-to-right angle of visual field in scanner in degree

% Load stimulus movie
Parameters = LoadStim(Stim, Parameters);

%% Run the experiment
RetinotopicMapping(Parameters, Emul);

%% Various parameters
Parameters.Instruction='Bitte immer Kreuz fixieren!\n\nDruecke bei rotem Kreis!';
[Parameters.Session Parameters.Session_name]=CurrentSession([saveDir filesep nameFile]); % Determine current session CurrentSession([saveDir Subj '_' Stim '_Eccen' Direc]); % Determine current session
Parameters.Subj = Subj;

end
