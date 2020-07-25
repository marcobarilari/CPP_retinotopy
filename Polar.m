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

    addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'subfun')));

    Task = 'retinotopypolar';

    PARAMETERS = SetParameters(Subj, Run, Task, Stim);

    %% Experiment parameters
    % Stimulus type
    PARAMETERS.Apperture = 'Wedge';
    % Width of wedge in degrees
    PARAMETERS.AppertureWidth = 70;
    % Stimulus cycles per run
    PARAMETERS.CyclesPerExpmt = 3;
    % Volumes per cycle - sets the "speed" of the mapping - standard is to have VolsPerCycle * TR ~ 1 min
    PARAMETERS.VolsPerCycle = 5;
    % Direction of cycling
    PARAMETERS.Direction = Direc;
    % Background image rotates
    PARAMETERS.RotateStimulus = true;
    % Angle rotation back & forth
    PARAMETERS.SineRotation = 10;

    %% Run the experiment
    [Data, PARAMETERS] = RetinotopicMapping(PARAMETERS, Emul, Debug);

    PlotResults(Data, PARAMETERS);

end
