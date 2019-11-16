function Data = Save2TSV(FrameTimes, BEHAVIOUR, PARAMETERS)
% Saves a BIDS compatible events.tsv files to
%
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
NbLines = size(FrameTimes, 1);
StimData = nan(NbLines, NbColumns);

StimData(:, [1 3]) = [...
    FrameTimes(:,1), ... 'Onset'
    zeros(NbLines, 1)]; % Duration

switch PARAMETERS.Apperture
    
    case 'Ring'
        Header = {'onset', 'trial_type', 'duration', 'ring_eccentricity', 'ring_width',...
            'x_target_pos', 'y_target_pos', 'target_width', ...
            'scale_outer', 'scale_inner'};
        StimData(:, [2 4 5 9:10]) = [Ring*ones(NbLines, 1), ... 'trial_type'
            FrameTimes(:,7) + (FrameTimes(:,5)-FrameTimes(:,7))/2, ... ring_eccentricity
            FrameTimes(:,5)-FrameTimes(:,7), ... ring_width
            FrameTimes(:,5), ... 'scale_outer'
            FrameTimes(:,7)]; % 'scale_inner'
        
    case 'Wedge'
        Header = {'onset', 'trial_type', 'duration', 'angle', 'wedge_angle', ...
            'x_target_pos', 'y_target_pos', 'target_width'};
        StimData(:, [2 4:5]) = [Wedge*ones(NbLines, 1), ... % 'trial_type'
            rem(FrameTimes(:, 3), 360), ... % make sure that all angles are <= abs(360)
            ones(NbLines, 1) * PARAMETERS.AppertureWidth];% 'wedge angle'
        
    case 'Bar'
        Header = {'onset', 'trial_type', 'duration', 'bar_angle', 'bar_width', ...
            'x_target_pos', 'y_target_pos', 'target_width', ...
            'bar_position', 'stimuli'};
        StimData(:, [2 4 5 9]) = [Bar*ones(NbLines, 1), ... % 'trial_type'
            FrameTimes(:, 3), ... 'bar angle'
            ones(NbLines, 1) * PARAMETERS.AppertureWidth, ... 'bar width'
            FrameTimes(:, 4)]; % bar position along the axis the bar moves along
        
        
end


%% Prepare reponse data
NbLines = size(BEHAVIOUR.ResponseTime,1);
RespData = nan(NbLines, NbColumns);
if size(BEHAVIOUR.ResponseTime,1)>0
    RespData(:, 1:3) = [...
        BEHAVIOUR.ResponseTime(:,1), ... 'Onset'
        Response*ones(NbLines,1), ... 'trial_type'
        zeros(NbLines,1), ... 'duration'
        ];
end


%% Prepare target data
NbLines = size(BEHAVIOUR.TargetData,1);
TargetData = nan(NbLines, NbColumns);
TargetData(:, [1:3 6:8]) = [...
    BEHAVIOUR.TargetData(:,1), ... 'Onset'
    Target*ones(NbLines,1), ... 'trial_type'
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
fid = fopen ([PARAMETERS.OutputFilename '_events.tsv'], 'w');

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
    
    switch Data(iLine, 2)
        case Bar
            sprintf('bar_angle-%i_position-%02.2f.tif\t', Data(iLine, 4), Data(iLine, 9));
    end
    
    fprintf(fid, '\n');
end

fclose (fid);


%% Print JSON file
PrintJSONfile(PARAMETERS)


end