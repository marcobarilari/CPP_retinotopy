 function DriftingBars(Subj, Stim, Emul)
%DriftingBars(Subj_ID, Stim, Emul)
%
% Drifting bars for mapping population receptive fields
%   Subj :  String with subject ID
%   Stim :  Stimulus file name e.g. 'Checkerboard'
%   Emul :  0 = Triggered by scanner, 1 = Trigger by keypress
%

if nargin == 0
    Subj = 66;
    Run = 1;
    Direc = '-';
    Stim = 'Ripples.mat';
    Emul = 1;
    Debug = 1;
end

if isempty(Subj)
    Subj = input('Subject number? ');  
    Run = input('Retinotopic run number? ');    
end

Subj = ['sub-', sprintf('%2.2d', Subj)]; 


% Create the mandatory folders if not already present
OutputDir = fullfile(pwd, 'output', ['sub-', sprintf('%2.2d', Subj)], 'func');
if ~exist(OutputDir, 'dir')
    mkdir(OutputDir);
end


DateFormat = 'yyyy_mm_dd_HH_MM';

NameFile = [Subj, '_task-retinotopydriftbar_run_', num2str(Run), datestr(now, DateFormat)];

addpath(genpath(fullfile(pwd, 'subfun')));

[Parameters] = SetParameters(Subj);
[Parameters.Session, Parameters.SessionName] = CurrentSession([Parameters.Subj '_driftbars-' Direc], OutputDir);   % Determine next session
Parameters.OutputDir = OutputDir;



%% Experimental Parameters
Parameters.Volumes_per_Trial = 20;  % Duration of trial in volumes
Parameters.BarWidth = 120; % Width of bar in pixels
Parameters.Conditions = [90 45 0 135 270 225 180 315];  % Stimulus conditions in each block defined by number

% Load stimulus movie
Parameters = LoadStim(fullfile(pwd, 'input', Stim), Parameters);

Parameters.SineRotation = 0;  % Rotating movie back & forth by this angle

%% Run the experiment
BarsMapping(Parameters, Emul, Debug)