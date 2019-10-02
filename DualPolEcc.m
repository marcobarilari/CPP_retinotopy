function DualPolEcc(Subj, Direc, Stim, Emul)
%DualPolEcc(Subj_ID, Direc, Stim, Emul)
%
% Dual mapping stimulus combining polar and eccentricity mapping. 
% Can also be used for mapping population receptive fields.
%   Subj :  String with subject ID
%   Direc :  Direction = '+' (clockwise/expanding) or '-' (anticlockwise/contracting)
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
OutputDir = fullfile(pwd, 'output', Subj, 'func');
if ~exist(OutputDir, 'dir')
    mkdir(OutputDir);
end


DateFormat = 'yyyy_mm_dd_HH_MM';

NameFile = [Subj, '_task-retinotopypoleccen_run_', num2str(Run), datestr(now, DateFormat)];

addpath(genpath(fullfile(pwd, 'subfun')));

[Parameters] = SetParameters(Subj);
[Parameters.Session, Parameters.SessionName] = CurrentSession([Parameters.Subj '_polecc-' Direc], OutputDir);   % Determine next session
Parameters.OutputDir = OutputDir;


%% Experimental Parameters
Parameters.Repetitions = 2; % Number of times a whole set of cycles is repeated per run
Parameters.Blanks = true;  % Whether or not blanks are included

Parameters.Direction = Direc;   % Direction of cycling
Parameters.Sine_Rotation = 4;  % Rotating movie back & forth by this angle

% Load stimulus movie
Parameters = LoadStim(Stim, Parameters);



%% Run the experiment
DualPolEccMapping(Parameters, Emul, Debug);

end
