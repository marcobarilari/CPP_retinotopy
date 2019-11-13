function Eccen(Subj, Direc, Stim, Emul)
%Eccen(Subj, Direc, Stim, Emul)
%
% Eccentricity mapping: does the retinotopy with an contracting or
% expanding ring
%   Subj :  String with subject ID
%   Direc : '+' or '-' for expanding or contracting
%   Stim :  Stimulus file name e.g. 'Checkerboard'
%   Emul :  0 = Triggered by scanner, 1 = Trigger by keypress
%   Debug : will play the experiment with PTB transparency

if nargin == 0
    Subj = 66;
    Run = 1;
    Direc = '+';
    Stim = 'Checkerboard.mat';
    Emul = 1;
    Debug = 1;
end

if isempty(Subj)
    Subj = input('Subject number? ');
    Run = input('Retinotopic run number? ');
end

addpath(genpath(fullfile(pwd, 'subfun')));

Task = 'retinotopyeccen';

PARAMETERS = SetParameters(Subj, Run, Task, Stim);


%% Experiment parameters
% Stimulus type
PARAMETERS.Apperture='Ring';
% Width of ring in degree of visual field at time = 0
PARAMETERS.AppertureWidth = 1;
% Direction of cycling
PARAMETERS.Direction = Direc;
% Background image rotates
PARAMETERS.RotateStimulus = false;
% Rotating movie back & forth by this angle
PARAMETERS.SineRotation = 10;


%% Run the experiment
[Data, PARAMETERS] = RetinotopicMapping(PARAMETERS, Emul, Debug);


PlotResults(Data, PARAMETERS)

end
