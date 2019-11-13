function Data = Save2TSV(FrameTimes, BEHAVIOUR, PARAMETERS)
% onset 	REQUIRED. Onset (in seconds) of the event measured from the beginning of the acquisition
% of the first volume in the corresponding task imaging data file. If any acquired scans have been
% discarded before forming the imaging data file, ensure that a time of 0 corresponds to the first
% image stored. In other words negative numbers in "onset" are allowed5.
%
% duration 	REQUIRED. Duration of the event (measured from onset) in seconds. Must always be either
% zero or positive. A "duration" value of zero implies that the delta function or event is so short
% as to be effectively modeled as an impulse.
%
% trial_type 	OPTIONAL. Primary categorisation of each trial to identify them as instances of the
% experimental conditions. For example: for a response inhibition task, it could take on values "go"
% and "no-go" to refer to response initiation and response inhibition experimental conditions.

if numel(BEHAVIOUR.EventTime)>size(BEHAVIOUR.TargetData,1)
    warning('not all planned target events were presented')
end

Header = {'onset', 'trial_type', 'duration', 'angle', 'width', 'x_target_pos', 'y_target_pos', 'scale_inner', 'scale'};


%% Prepare stimuli presentation data for printing
StimData = nan(size(FrameTimes,1), 9);

StimData(:, [1 3:5]) = [...
    FrameTimes(:,1), ... 'Onset'
    zeros(size(FrameTimes,1),1), ... 'duration'
    FrameTimes(:,3), ... 'angle'
    ones(size(FrameTimes,1),1) * PARAMETERS.AppertureWidth, ... 'width'
    ];

switch PARAMETERS.Apperture
    case 'Ring'
        StimData(:, [2 8:9]) = [
            2*ones(size(FrameTimes,1),1), ... 'trial_type'
            FrameTimes(:,5), ... 'scale_inner'
            FrameTimes(:,7)]; % 'scale'
        
    otherwise
        StimData(:, 2) = ones(size(FrameTimes,1),1); % 'trial_type'
end


%% Prepare reponse data for printing
RespData = nan(size(BEHAVIOUR.ResponseTime,1), 9);
if size(BEHAVIOUR.ResponseTime,1)>0
    RespData(:, 1:3) = [...
        BEHAVIOUR.ResponseTime(:,1), ... 'Onset'
        4*ones(size(BEHAVIOUR.ResponseTime,1),1), ... 'trial_type'
        zeros(size(BEHAVIOUR.ResponseTime,1),1), ... 'duration'
        ];
end


%% Prepare target data for printing
TargetData = nan(size(BEHAVIOUR.TargetData,1), 9);
TargetData(:, [1:3 6:7]) = [...
    BEHAVIOUR.TargetData(:,1), ... 'Onset'
    3*ones(size(BEHAVIOUR.TargetData,1),1), ... 'trial_type'
    diff(BEHAVIOUR.TargetData(:,1:2), 1, 2), ... 'duration'
    BEHAVIOUR.TargetData(:,3:4)... 'x_target_pos' 'y_target_pos'
    ];


%% Print
%sort data by onset
Data = [StimData ; RespData ; TargetData];
[~,I] = sort(Data(:,1));
Data = Data(I,:);

fid = fopen ([PARAMETERS.OutputFilename '.tsv'], 'w');

% print header
for iHeader = 1:numel(Header)
    fprintf(fid, '%s\t', Header{iHeader});
end
fprintf(fid, '\n');

% print onsets, then figure out trial type and then print all the other
% data
for iLine = 1:size(Data,1)
    
    fprintf(fid, '%f\t', Data(iLine,1));
    
    switch Data(iLine, 2)
        case 1
            TrialType = 'wedge';
        case 2
            TrialType = 'ring';
        case 3
            TrialType = 'target';
        case 4
            TrialType = 'response';
    end
    
    fprintf(fid, '%s\t', TrialType);
    
    fprintf(fid, '%f\t', Data(iLine,3:size(Data,2)));
    
    fprintf(fid, '\n');
end

fclose (fid);

end