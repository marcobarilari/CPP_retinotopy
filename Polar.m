function Polar(Subj, Direc, Stim, Emul, Debug)
% Polar(Subj, Direc, Stim, Emul)
%
% Polar mapping: does the retinotopy with a rotating wedge
%   Subj :  String with subject ID
%   Direc : '+' or '-' for clockwise or anticlockwise
%   Stim :  Stimulus file name e.g. 'Checkerboard'
%   Emul :  0 = Triggered by scanner, 1 = Trigger by keypress
%   Debug : will play the experiment with PTB transparency

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
% Stimulus type
Parameters.Apperture = 'Wedge';
% Width of wedge in degrees
Parameters.AppertureWidth = 70;
% Direction of cycling
Parameters.Direction = Direc;
% Background image rotates
Parameters.RotateStimulus = true;
% Angle rotation back & forth
Parameters.SineRotation = 5;


%% Run the experiment
RetinotopicMapping(Parameters, Emul, Debug);

end
