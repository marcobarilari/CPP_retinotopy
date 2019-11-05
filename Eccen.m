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

Parameters = SetParameters(Subj, Run, Task, Stim);


%% Experiment parameters
% Stimulus type
Parameters.Apperture='Ring';
% Width of ring in degree of visual field at time = 0
Parameters.AppertureWidth = 1;
% Direction of cycling
Parameters.Direction = Direc;
% Background image rotates
Parameters.RotateStimulus = false;
% Rotating movie back & forth by this angle
Parameters.SineRotation = 2;


%% Run the experiment
RetinotopicMapping(Parameters, Emul, Debug);


end
