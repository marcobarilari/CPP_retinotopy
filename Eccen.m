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

addpath(genpath(fullfile(pwd, 'subfun')));

Task = 'retinotopyeccen';

Parameters = SetParameters(Subj, Run, Task, Stim);


%% Experiment parameters
Parameters.Apperture='Ring';    % Stimulus type
Parameters.AppertureWidth = 0.5;  % Width of ring in degree of visual field at time = 0
Parameters.Direction = Direc; % Direction of cycling

Parameters.RotateStimulus = false;   % Image rotates
Parameters.SineRotation = 2;  % Rotating movie back & forth by this angle


%% Run the experiment
RetinotopicMapping(Parameters, Emul, Debug);


end
