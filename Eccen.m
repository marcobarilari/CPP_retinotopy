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
    Subj = 66;
    Run = 1;
    Direc = '-';
    Stim = 'Checkerboard.mat';
    Emul = 1;
    Debug = 1;
end

if isempty(Subj)
    Subj = input('Subject number? ');  
    Run = input('Retinotopic run number? ');    
end

Subj = ['sub-', sprintf('%2.2d', Subj)]; 

% Create the mandatory folders if not already present
OutputDir = fullfile(pwd, 'output', Subj, 'func');
if ~exist(OutputDir, 'dir')
    mkdir(OutputDir);
end


DateFormat = 'yyyy_mm_dd_HH_MM';

NameFile = [Subj, '_task-retinotopyeccen_run_', num2str(Run), datestr(now, DateFormat)];

addpath(genpath(fullfile(pwd, 'subfun')));

[Parameters] = SetParameters(Subj);
[Parameters.Session, Parameters.SessionName] = CurrentSession([Parameters.Subj '_ecc-' Direc], OutputDir);   % Determine next session
Parameters.OutputDir = OutputDir;


%% Experiment parameters
Parameters.Apperture='Ring';    % Stimulus type
Parameters.AppertureWidth = 0.5;  % Width of ring in degree of visual field at time = 0
Parameters.Direction = Direc; % Direction of cycling

Parameters.RotateStimulus = false;   % Image rotates
Parameters.SineRotation = 2;  % Rotating movie back & forth by this angle

% Load stimulus movie
Parameters = LoadStim(fullfile(pwd, 'input', Stim), Parameters);


%% Run the experiment
RetinotopicMapping(Parameters, Emul, Debug);


end
