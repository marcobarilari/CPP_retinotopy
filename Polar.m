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
    Subj=1;
    Run = 1;
    Direc = '-';
    Stim = 'Checkerboard';
    Emul = 1;
    Debug = 1;
end

if isempty(Subj)
    SubjNb = input('Subject number? ');  
    Run = input('Retinotopic run number? ');  
    Subj = ['Sub-', sprintf('%2.2d', SubjNb), '_Run_' num2str(Run)];    
end


% Create the mandatory folders if not already present
saveDir = fullfile(pwd, strcat('sub-', sprintf('%2.2d', SubjNb)), 'func');
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end


DateFormat = 'yyyy_mm_dd_HH_MM';

nameFile = strcat('Retinotopy_Subject_', sprintf('%2.2d', SubjNb), '_Run_', num2str(Run), '_', Stim, '_Polar_', Direc, '_', datestr(now, DateFormat));


addpath(fullfile(pwd, 'subfun'));

[Parameters] = SetParameters(Subj);

[Parameters.Session, Parameters.SessionName] = CurrentSession([Parameters.Subj '_Pol' Direc]);   % Determine next session


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
