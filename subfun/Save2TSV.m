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

% For Bars
% FrameTimesUpdate = [CURRENT.Time CURRENT.Frame CURRENT.Condit CURRENT.BarPos]; 

% For Wedges
% FrameTimesUpdate = [CURRENT.Time CURRENT.Frame CURRENT.Angle];

% For Rings
% FrameTimesUpdate = [CURRENT.Time CURRENT.Frame CURRENT.Angle  RING.ScalePix RING.ScaleVA2 RING.ScaleInnerPix RING.ScaleInnerVA];

% Stimuli type
Ring = 1;
Wedge = 2;
Bar = 3;
Target = 4;
Response = 5;

NbColumns = 10;

if numel(BEHAVIOUR.EventTime)>size(BEHAVIOUR.TargetData,1)
    warning('not all planned target events were presented')
end


%% Prepare stimuli presentation data
StimData = nan(size(FrameTimes,1), NbColumns);

StimData(:, [1 3:5]) = [...
    FrameTimes(:,1), ... 'Onset'
    zeros(size(FrameTimes,1),1), ... 'duration'
    FrameTimes(:,3), ... 'angle' / 'eccentricity' / 'bar angle'
    ones(size(FrameTimes,1),1) * PARAMETERS.AppertureWidth, ... 'wedge angle' / 'ring width' / 'bar width'
    ];

switch PARAMETERS.Apperture
    
    case 'Ring'
        Header = {'onset', 'trial_type', 'duration', 'ring_eccentricity', 'ring_width', ...
                  'x_target_pos', 'y_target_pos', 'target_width', ...
                  'scale_inner', 'scale'};
        StimData(:, [2 9:10]) = [
            Ring*ones(size(FrameTimes,1),1), ... 'trial_type'
            FrameTimes(:,5), ... 'scale_inner'
            FrameTimes(:,7)]; % 'scale'
        
    case 'Wedge'
        Header = {'onset', 'trial_type', 'duration', 'angle', 'wedge_angle', ...
                  'x_target_pos', 'y_target_pos', 'target_width'};
        StimData(:, 2) = Wedge*ones(size(FrameTimes,1),1); % 'trial_type'
        
    case 'Bar'
        Header = {'onset', 'trial_type', 'duration', 'bar_angle', 'bar_width', ...
                  'x_target_pos', 'y_target_pos', 'target_width', ...
                  'bar_position'};
        StimData(:, [2 9]) = [Bar*ones(size(FrameTimes,1),1), ... % 'trial_type'
                                FrameTimes(:,4)]; % Bar position along the axis defined by the 
end


%% Prepare reponse data
RespData = nan(size(BEHAVIOUR.ResponseTime,1), NbColumns);
if size(BEHAVIOUR.ResponseTime,1)>0
    RespData(:, 1:3) = [...
        BEHAVIOUR.ResponseTime(:,1), ... 'Onset'
        Response*ones(size(BEHAVIOUR.ResponseTime,1),1), ... 'trial_type'
        zeros(size(BEHAVIOUR.ResponseTime,1),1), ... 'duration'
        ];
end


%% Prepare target data
TargetData = nan(size(BEHAVIOUR.TargetData,1), NbColumns);
TargetData(:, [1:3 6:8]) = [...
    BEHAVIOUR.TargetData(:,1), ... 'Onset'
    Target*ones(size(BEHAVIOUR.TargetData,1),1), ... 'trial_type'
    diff(BEHAVIOUR.TargetData(:,1:2), 1, 2), ... 'duration'
    BEHAVIOUR.TargetData(:,3:5)... 'x_target_pos', 'y_target_pos', 'target_width'
    ];


%% Concatenate, sort, clean data

%sort data by onset
Data = [StimData ; RespData ; TargetData];
[~,I] = sort(Data(:,1));
Data = Data(I,:);

% Remove columns of NaNs
switch PARAMETERS.Apperture
  
    case 'Wedge'
        Data(:, 9:10) = [];
        
    case 'Bar'
        Data(:, 10) = []; 
end


%% Print
fid = fopen ([PARAMETERS.OutputFilename '.tsv'], 'w');

% print header
for iHeader = 1:numel(Header)
    fprintf(fid, '%s\t', Header{iHeader});
end
fprintf(fid, '\n');

% print onsets, then figure out trial type and then print all the other data
for iLine = 1:size(Data,1)
    
    fprintf(fid, '%f\t', Data(iLine,1));
    
    switch Data(iLine, 2)
        case Wedge
            TrialType = 'wedge';
        case Ring
            TrialType = 'ring';
        case Target
            TrialType = 'target';
        case Response
            TrialType = 'response';
        case Bar
            TrialType = sprintf('bar_angle-%02.2f_pos-%02.2f', Data(iLine, 4), Data(iLine, 9));
    end
    
    fprintf(fid, '%s\t', TrialType);
    
    fprintf(fid, '%f\t', Data(iLine, 3:size(Data,2)));
    
    fprintf(fid, '\n');
end

fclose (fid);

end