function Polar(Subj, Direc, Stim, Emul, Debug)
% Polar(Subj, Direc, Stim, Emul)
%
% Polar mapping
%   Subj :  String with subject ID
%   Direc : '+' or '-' for clockwise/expanding or anticlockwise/contracting
%   Stim :  Stimulus file name e.g. 'Checkerboard'
%   Emul :  0 = Triggered by scanner, 1 = Trigger by keypress
%

if nargin == 0
    Subj = 66;
    Run = 1;
    Direc = '-';
    Stim = 'Checkerboard';
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

NameFile = [Subj, '_task-retinotopypolar_run_', num2str(Run), datestr(now, DateFormat)];

addpath(genpath(fullfile(pwd, 'subfun')));

[Parameters] = SetParameters(Subj);

[Parameters.Session, Parameters.SessionName] = CurrentSession([Parameters.Subj '_pol-' Direc], OutputDir);   % Determine next session


%% Experiment parameters
Parameters.Apperture = 'Wedge'; % Stimulus type
Parameters.AppertureWidth = 70; % Width of wedge in degrees
Parameters.Direction = Direc; % Direction of cycling

Parameters.RotateStimulus = true; % Does image rotate?
Parameters.SineRotation = 5; % No rotation back & forth 

% Load stimulus movie
Parameters = LoadStim(Stim, Parameters);



%% Run the experiment
RetinotopicMapping(Parameters, Emul, Debug);

end
