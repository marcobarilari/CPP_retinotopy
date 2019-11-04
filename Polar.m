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
    Stim = 'Checkerboard.mat';
    Emul = 1;
    Debug = 1;
end

if isempty(Subj)
    Subj = input('Subject number? ');  
    Run = input('Retinotopic run number? ');    
end

addpath(genpath(fullfile(pwd, 'subfun')));

Task = 'retinotopypolar';

Parameters = SetParameters(Subj, Run, Task, Stim);


%% Experiment parameters
Parameters.Apperture = 'Wedge'; % Stimulus type
Parameters.AppertureWidth = 70; % Width of wedge in degrees
Parameters.Direction = Direc; % Direction of cycling

Parameters.RotateStimulus = true; % Does image rotate?
Parameters.SineRotation = 5; % Angle rotation back & forth 


%% Run the experiment
RetinotopicMapping(Parameters, Emul, Debug);

end
