function Retinotopic_Mapping(Parameters, Emulate)
%Retinotopic_Mapping(Parameters, Emulate)
% 
% Cyclic presentation with a rotating and/or expanding aperture.
% Behind the aperture a background is displayed as a movie.
%
% Parameters:
%   Parameters :    Struct containing various parameters
%   Emulate :       0 (default) for scanning
%                   1 for manual trigger
%


%PsychDebugWindowConfiguration;
eyeTrack = 0; % = 1 eyetracking yes; =0 no eyetracking
    
if eyeTrack == 1;
    %--- initialize iView eye tracker----------
    host = '10.41.111.213'; % SMI machine ip: '10.41.111.213'
    port = 4444;
    window = 1;
    ivx = iviewxinitdefaults2(window, 9,[], host, port);%original: ivx=iviewxinitdefaults(window, 9 , host, port);
    ivx.backgroundColour = 0; 
    [success, ivx]=iViewX('openconnection', ivx);
    [success, ivx]=iViewX('checkconnection', ivx);
    if success ~= 1;
        error('connection to eye tracker failed');
    end;
end;

% special center of ring stimulus because wide field mirror is used
centerRing = [400,150];%[400,191]; % center ring at 800x600: [400,191] visible window is at 136,245 % tr 31.8.: changed to 191-8
centerRing = [400,300];

%% Behavioural data
Behaviour = struct;
Behaviour.EventTime = [];
Behaviour.Response = [];
Behaviour.ResponseTime = [];

%% Initialize randomness & keycodes
SetupRand;
SetupKeyCodes;

%% Stimulus conditions 
Volumes = [];  
% Cycle through repeats of each set
for i = 1 : Parameters.Cycles_per_Expmt 
    Volumes = [Volumes; ones(Parameters.Vols_per_Cycle, 1)];
end
Vols_per_Expmt = length(Volumes);

% if Emulate
%     % In manual start there are no dummies
%     Parameters.Dummies = 0;
%     Parameters.Overrun = 0;
% end


% Add column for volume time stamps
Volumes = [Volumes, zeros(Vols_per_Expmt,1)];
Cycle_Vols = find(Volumes(:,1) == 1);

%% Event timings 
Events = [];
for e = Parameters.TR : Parameters.Event_Duration : (Parameters.Cycles_per_Expmt * Parameters.Vols_per_Cycle * Parameters.TR)
    if rand < Parameters.Prob_of_Event
        Events = [Events; e];
    end
end
% Add a dummy event at the end of the Universe
Events = [Events; Inf];

%% Configure scanner 
if Emulate 
    % Emulate scanner
    % TrigStr = 'Press key to start...';    % Trigger string
    TrigStr = 'Get ready...';    % Trigger string
else
    % Real scanner
    TrigStr = 'Stand by for scan...';    % Trigger string
end

% %% Initialize PTB

screenid = max(Screen('Screens'));
noScreens = length(Screen('Screens'));
if ismac && noScreens > 1; % only if projector is also a screen
    oldRes = Screen('Resolution',screenid,800,600,60);% with scanner projector: oldRes = screen('Resolution',screenid,1152,870,75)
end;
[Win Rect] = Screen('OpenWindow', Parameters.Screen, Parameters.Background); 
Screen('TextFont', Win, Parameters.FontName);
Screen('TextSize', Win, Parameters.FontSize);
Screen('BlendFunction', Win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
HideCursor;
RefreshDur = Screen('GetFlipInterval',Win);
Slack = RefreshDur / 2;

%% Load background movie
StimRect = [0 0 size(Parameters.Stimulus,2) size(Parameters.Stimulus,1)];
BgdTextures = [];
if length(size(Parameters.Stimulus)) < 4
    for f = 1:size(Parameters.Stimulus, 3)
        BgdTextures(f) = Screen('MakeTexture', Win, Parameters.Stimulus(:,:,f));
    end
else
    for f = 1:size(Parameters.Stimulus, 4)
        BgdTextures(f) = Screen('MakeTexture', Win, Parameters.Stimulus(:,:,:,f));
    end
end

%% Create fixation cross
Fix_Cross = cross_matrix(16) * 255;
[fh fw] = size(Fix_Cross);
Fix_Cross(:,:,2) = Fix_Cross;   % alpha layer
Fix_Cross(:,:,1) = InvertContrast(Fix_Cross(:,:,1));
FixCrossTexture = Screen('MakeTexture', Win, Fix_Cross);
if strcmp(Parameters.Apperture,'Wedge');
    fixCrossRect = CenterRectOnPoint([0 0 fh fw],Rect(3)/2,Rect(4)/2);
elseif strcmp(Parameters.Apperture,'Ring');
    %fixCrossRect = CenterRectOnPoint([0 0 fh fw],Rect(3)/2,Rect(4)/2);
    fixCrossRect = CenterRectOnPoint([0 0 fh fw],centerRing(1),centerRing(2));
end;

%% Standby screen
Screen('FillRect', Win, Parameters.Background, Rect);
if strcmpi(Parameters.Apperture, 'Wedge');
    DrawFormattedText(Win, [Parameters.Instruction '\n \n' TrigStr], 'center', 'center', Parameters.Foreground); 
elseif strcmpi(Parameters.Apperture, 'Ring');
    DrawFormattedText(Win, [Parameters.Instruction '\n \n' TrigStr],centerRing(1)-100, centerRing(2)-50, Parameters.Foreground); 
end;
Screen('Flip', Win);

%% Wait for start of experiment
 if Emulate == 1
    % Start manually
    KbPressWait
    
    WaitSecs(Parameters.TR*Parameters.Dummies);
    Start_Session = GetSecs;
    CurrSlice = 0;
 else
   
    %% Opening IOPort
    portSettings = sprintf('BaudRate=115200 InputBufferSize=10000 ReceiveTimeout=60');
    portSpec = FindSerialPort([], 1);

    % Open port portSpec with portSettings, return handle:
    myport = IOPort('OpenSerialPort', portSpec, portSettings);

    % Start asynchronous background data collection and timestamping. Use
    % blocking mode for reading data -- easier on the system:
    asyncSetup = sprintf('BlockingBackgroundRead=1 ReadFilterFlags=0 StartBackgroundRead=1');
    IOPort('ConfigureSerialPort', myport, asyncSetup);

    % Read once to warm up
    WaitSecs(1);
    IOPort('Read', myport); 
    
    nTrig = 0;
    
    %% waiting for dummie triggers from the scanner
    while (nTrig <= Parameters.Dummies)

        [pktdata, treceived] = IOPort('Read', myport);

        % it is checked if something was received via trigger_port
        % oldtrigger is there so 'number' is only updated when something new is
        % received via trigger_port (normally you receive a "small series" of data at
        % a time)
        if isempty(pktdata)
            treceived = 0;
        end

        if treceived && (oldtrigger == 0)
            number = 1;
        else
            number = 0;
        end

        oldtrigger = treceived;
        
        if number
            nTrig = nTrig + 1;
            number = 0; %#ok<NASGU>
        end
        
    end
    
     %-- start eye tracking ---
    if eyeTrack == 1 ;
        %iViewX('clearbuffer', ivx);
        % to clear data buffer
        % stop tracker
%         iViewX('stoprecording', ivx);
%         thedatestr = datestr(now, 'yyyy-mm-dd_HH.MM');
%         strFile = ['"D:\Data\trohe\Ret_oldDat' thedatestr '.idf"'];
%         iViewX('datafile', ivx,strFile);
        
        iViewX('startrecording', ivx);
        iViewX('message', ivx, ['Start_Ret_','Subj_', Parameters.Subj,'_','_Run', num2str(Parameters.Session(end)), Parameters.Apperture,'_',Parameters.Direction]); 
        iViewX('incrementsetnumber', ivx, 0);
    end;
    
%     config_serial;
%     start_cogent;
%     Port = 1;
%     CurrSlice = waitslice(Port, Parameters.Dummies * Parameters.Number_of_Slices + 1);  
end

%% Begin main experiment 
Start_of_Expmt = NaN;   % Time when cycling starts
FrameTimes = [];  % Time stamp of each frame
CurrEvent = 1;  % Current dimming event
CurrFrame = 1;  % Current stimulus frame
CurrRefresh = 0;   % Current video refresh
CurrAngle = 0;  % Current angle of wedge
CurrScale = 0;  % Current inner radius of ring
PrevKeypr = 0;  % If previously key was pressed
maxEcc = Parameters.FOV/2 + Parameters.Apperture_Width + log(Parameters.FOV/2+1) ; % currentScale is scale of outer ring (exceeding screen until innter ring reaches window boarder)
csFuncFact = 1/((maxEcc+exp(1))*log(maxEcc+exp(1))- (maxEcc+exp(1))) ; % csFuncFact is used to expand with log increasing speed so that ring is at maxEcc at end of cycle
CurrRingWidthVA = Parameters.Apperture_Width;%maxEcc -  Parameters.FOV/2;

%% Draw the fixation cross
Screen('FillRect', Win, Parameters.Background, Rect);
Screen('DrawTexture', Win, FixCrossTexture, [0 0 fh fw], fixCrossRect);
Screen('Flip', Win);

%% Initialize apperture texture
AppTexture = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));

%% Start cycling the stimulus
Behaviour.EventTime = Events;
CycleDuration = Parameters.TR * Parameters.Vols_per_Cycle;
CyclingEnd = CycleDuration * Parameters.Cycles_per_Expmt;
CyclingStart = GetSecs;
CurrTime = GetSecs-CyclingStart;
IsEvent = false; 
WasEvent = false;
Events2 = [];

save([Parameters.Session_name]);

% Loop until the end of last cycle
while CurrTime < CyclingEnd    
    %% Update frame number
    CurrRefresh = CurrRefresh + 1;
    if CurrRefresh == Parameters.Refreshs_per_Stim
        CurrRefresh = 0;
        CurrFrame = CurrFrame + 1;
        if length(size(Parameters.Stimulus)) < 4
            if CurrFrame > size(Parameters.Stimulus,3) 
                CurrFrame = 1;
            end
        else
            if CurrFrame > size(Parameters.Stimulus,4) 
                CurrFrame = 1;
            end
        end
    end
    % Current time stamp
    CurrTime = GetSecs-CyclingStart;        
    
    
    %% Determine size & angle
    % Rotation of apperture
    if strcmpi(Parameters.Direction, '+')
        CurrAngle = 90 - Parameters.Apperture_Width/2 + (CurrTime/CycleDuration) * 360;
    elseif strcmpi(Parameters.Direction, '-')
        CurrAngle = 90 - Parameters.Apperture_Width/2 - (CurrTime/CycleDuration) * 360;
    end
    % Size of apperture (CurrScale only influences  ring)
    if strcmpi(Parameters.Direction, '+')
        %CurrScale = 0 + mod(CurrTime, CycleDuration)/CycleDuration * StimRect(4);
        
        %---tr: vary CurrScale so that expansion speed is log over eccentricity  
        % cf. Tootell 1997; Swisher 2007; Warnking 2002 etc;
        CurrScaleVA = 0 + mod(CurrTime, CycleDuration)/CycleDuration * maxEcc; % current visual angle linear in time  
          % ensure some foveal stimulation at beginning (which is hidden by fixation cross otherwise)
        if CurrScaleVA < 0.5;
            CurrScaleVA = 0.5;
        end; 
    elseif strcmpi(Parameters.Direction, '-')
        %CurrScale = StimRect(4) - mod(CurrTime, CycleDuration)/CycleDuration * StimRect(4);
        CurrScaleVA = maxEcc - mod(CurrTime, CycleDuration)/CycleDuration * maxEcc; 
        if CurrScaleVA > maxEcc - 0.5;
            CurrScaleVA = maxEcc - 0.5;
        end;
    end;
     
    % near-exp visual angle
    CurrScaleVA2 = ((CurrScaleVA+exp(1)) * log(CurrScaleVA+exp(1)) - (CurrScaleVA+exp(1))) * maxEcc * csFuncFact;         
    CurrScaleCm = tan(CurrScaleVA2*pi/180)* Parameters.viewDist; % in cm  on screen  
    CurrScale = CurrScaleCm / (Parameters.xWidthScreen/2) * (StimRect(4)/2) * 2;% in pixel
    
    %--tr width of apperture changes logarithmically with eccentricity of inner ring, cf.
    %authors above
    if strcmpi(Parameters.Apperture, 'Ring');
        oldScaleInnerVA = CurrScaleVA - CurrRingWidthVA;        
        if oldScaleInnerVA < 0;
            oldScaleInnerVA = 0;
        end;
        CurrRingWidthVA = Parameters.Apperture_Width + log(oldScaleInnerVA+1); % growing with inner ring ecc
        CurrScaleInnerVA = CurrScaleVA2 - CurrRingWidthVA;
        CurrScaleInnerCM = tan(CurrScaleInnerVA*pi/180)* Parameters.viewDist; % in cm  on screen      
        CurrScaleInner =  2*(CurrScaleInnerCM / (Parameters.xWidthScreen/2) * (StimRect(4)/2));% in pixel
        if CurrScaleInner < 0;
            CurrScaleInner = 0;
        end;
    end;
    
    % Current frame time & condition
    if strcmpi(Parameters.Apperture, 'Ring');
        FrameTimes = [FrameTimes; CurrTime CurrFrame CurrAngle CurrScale CurrScaleVA2 CurrScaleInner CurrScaleInnerVA];
    elseif strcmpi(Parameters.Apperture, 'Wedge');
        FrameTimes = [FrameTimes; CurrTime CurrFrame CurrAngle CurrScale];
    end;
    
    %% Create apperture texture
    Screen('Fillrect', AppTexture, Parameters.Background);
    if strcmpi(Parameters.Apperture, 'Ring');
%         Screen('FillOval', AppTexture, [0 0 0 0], CenterRect([0 0 repmat(CurrScale+Parameters.Apperture_Width,1,2)], Rect));
%         Screen('FillOval', AppTexture, [Parameters.Background 255], CenterRect([0 0 repmat(CurrScale,1,2)], Rect));
        Screen('FillOval', AppTexture, [0 0 0 0], CenterRectOnPoint([0 0 repmat(CurrScale,1,2)],centerRing(1),centerRing(2)));
               
        Screen('FillOval', AppTexture, [Parameters.Background 255], CenterRectOnPoint([0 0 repmat(CurrScaleInner,1,2)],centerRing(1),centerRing(2)));
        
        % Wrapping around?
%         %WrapAround = CurrScale+CurrRingWidth-StimRect(4);
%         WrapAround = CurrScale+ wrapAroundPix -StimRect(4);
%         if WrapAround < 0
%             WrapAround = 0;
%         end
%         %Screen('FillOval', AppTexture, [0 0 0 0], CenterRect([0 0 repmat(WrapAround,1,2)], Rect));
%         Screen('FillOval', AppTexture, [0 0 0 0], CenterRectOnPoint([0 0 repmat(WrapAround,1,2)],centerRing(1),centerRing(2)));
    elseif strcmpi(Parameters.Apperture, 'Wedge');
        Screen('FillArc', AppTexture, [0 0 0 0], CenterRect([0 0 repmat(StimRect(4),1,2)], Rect), CurrAngle, Parameters.Apperture_Width);
    end

    %% Stimulus presentation
    % Display background
    if Parameters.Rotate_Stimulus
        BgdAngle = CurrAngle;
    else        
        BgdAngle = 0;
    end
    % Rotate background movie?
    SineRotate = cos(CurrTime) * Parameters.Sine_Rotation;
    
    if strcmp(Parameters.Apperture,'Wedge');
        Screen('DrawTexture', Win, BgdTextures(CurrFrame), StimRect, CenterRect(StimRect, Rect), BgdAngle+SineRotate);
        % Draw aperture
        Screen('DrawTexture', Win, AppTexture);
        % Draw the fixation cross & aperture
        Screen('DrawTexture', Win, FixCrossTexture);    
    elseif strcmp(Parameters.Apperture,'Ring');
        Screen('DrawTexture', Win, BgdTextures(CurrFrame), StimRect, CenterRectOnPoint(StimRect,centerRing(1),centerRing(2)), BgdAngle+SineRotate);
        % Draw aperture
        Screen('DrawTexture', Win, AppTexture);
        % Draw the fixation cross & aperture
        Screen('DrawTexture', Win, FixCrossTexture, [0 0 fh fw], fixCrossRect);       
    end;

    
    % Is this an event?
    CurrEvents = Events - CurrTime;
    %if sum(CurrEvents > 0 & CurrEvents < Parameters.Event_Duration)
    if strcmp(Parameters.Apperture,'Wedge') && sum(CurrEvents > 0 & CurrEvents < Parameters.Event_Duration) ;
        IsEvent = true;
        Events2 = [Events2,GetSecs-CyclingStart]; % for relating shown events and responses in ring runs
    elseif strcmp(Parameters.Apperture,'Ring') && (CurrScaleInnerVA > 10) && sum(CurrEvents > 0 & CurrEvents < Parameters.Event_Duration);
        IsEvent = true;
        Events2 = [Events2,GetSecs-CyclingStart]; 
    else IsEvent = false;
        
    end;
    if IsEvent == true;
        if WasEvent == false
            RndAngle = RandOri;
            % because ring is presented under wide V FOV condition, target
            % appears only @ 0 or 180 degree (tr)
            if strcmpi(Parameters.Apperture, 'Ring');
                possAngle = [0,180];
                RndAngle = possAngle(randi(2,[1 1]));
            end;
            RndScale = round(rand*(Rect(4)/2));
            WasEvent = true;
        end
        if strcmpi(Parameters.Apperture, 'Wedge')
            [X Y] = pol2cart((90+CurrAngle+Parameters.Apperture_Width/2)/180*pi, RndScale);
        elseif strcmpi(Parameters.Apperture, 'Ring')
            [X Y] = pol2cart(RndAngle/180*pi,(CurrScale/2 + CurrScaleInner/2)/2);
            % target always on horizontal meridian
            
        end
        
        % tr
        if strcmpi(Parameters.Apperture, 'Wedge');
            X = Rect(3)/2-X;
            Y = Rect(4)/2-Y;
        elseif strcmpi(Parameters.Apperture, 'Ring');
            X = X + Rect(3)/2;
            Y = centerRing(2) - Y;
        end;
        % Draw event
        %Screen('FillOval', Win, Parameters.Background,[X-Parameters.Event_Size/2 Y-Parameters.Event_Size/2 X+Parameters.Event_Size/2 Y+Parameters.Event_Size/2]);
        Screen('FillOval', Win, Parameters.Event_Color,[X-Parameters.Event_Size/2 Y-Parameters.Event_Size/2 X+Parameters.Event_Size/2 Y+Parameters.Event_Size/2]);
    elseif IsEvent == false;
        WasEvent = false;
    end
    % Draw current video frame   
    rft = Screen('Flip', Win);
    if isnan(Start_of_Expmt)
        Start_of_Expmt = rft;
    end
    
    %% Behavioural response
    [Keypr KeyTime Key] = KbCheck;
    if Key(KeyCodes.Escape) 
        % Abort screen
        Screen('FillRect', Win, Parameters.Background, Rect);
        DrawFormattedText(Win, 'Experiment was aborted!', 'center', 'center', Parameters.Foreground); 
        WaitSecs(0.5);
        ShowCursor;
        Screen('CloseAll');
        disp(' '); 
        disp('Experiment aborted by user!'); 
        disp(' ');
        return
    end
    if Keypr ;
        if ~PrevKeypr
            PrevKeypr = 1;
            keyNum = find(Key); 
            keyNum = keyNum(1);% prevent that trigger+response or double response spoil Behaviour.Response dimensions!!
            Behaviour.Response = [Behaviour.Response; keyNum];
            Behaviour.ResponseTime = [Behaviour.ResponseTime; KeyTime - CyclingStart];
        end
    else
        if PrevKeypr
            PrevKeypr = 0;
        end
    end
end

%% Draw the fixation cross
Screen('DrawTexture', Win, FixCrossTexture);
End_of_Expmt = Screen('Flip', Win);

%%% REMOVE THIS IF YOU DON'T USE COGENT!!! %%%
% % Turn off Cogent
% if Emulate == 0
%     stop_cogent;
% end

%% Farewell screen
% Screen('FillRect', Win, Parameters.Background, Rect);
% DrawFormattedText(Win, '', 'center', 'center', Parameters.Foreground); 
% Screen('Flip', Win);

%% Draw the fixation cross
if strcmp(Parameters.Apperture,'Wedge');
    Screen('FillRect', Win, Parameters.Background, Rect);
    Screen('DrawTexture', Win, FixCrossTexture);
    Screen('Flip', Win);
elseif strcmp(Parameters.Apperture,'Ring');
    Screen('FillRect', Win, Parameters.Background, Rect);
    Screen('DrawTexture', Win, FixCrossTexture, [0 0 fh fw], fixCrossRect);
    Screen('Flip', Win);
end; 
WaitSecs(Parameters.TR * Parameters.Overrun);
ShowCursor;
Screen('CloseAll');

%% Save workspace
Parameters = rmfield(Parameters, 'Stimulus');  
clear('Apperture', 'R', 'T', 'X', 'Y');
Parameters.Stimulus = [];
save([Parameters.Session_name]);

%% Experiment duration

new_line;
ExpmtDur = End_of_Expmt - Start_of_Expmt;
ExpmtDurMin = floor(ExpmtDur/60);
ExpmtDurSec = mod(ExpmtDur, 60);
disp(['Cycling lasted ' num2str(ExpmtDurMin) ' minutes, ' num2str(ExpmtDurSec) ' seconds']);
new_line;
WaitSecs(1);

if ismac && Emulate ~= 1;
    IOPort('ConfigureSerialPort', myport, ['StopBackgroundRead']);
    IOPort('Close', myport);
end;

if eyeTrack == 1 ;    
    % stop tracker
    iViewX('stoprecording', ivx);
    % save data file
    thedatestr = datestr(now, 'yyyy-mm-dd_HH.MM');
    strFile = ['"D:\Data\trohe\Ret_Subj_', Parameters.Subj, '_Run', num2str(Parameters.Session(end)),'_', Parameters.Apperture,'_',Parameters.Direction,'_',thedatestr, '.idf"'];
    iViewX('datafile', ivx,strFile); % gaensefuessc hen important!  
    %close iView connection
    iViewX('closeconnection', ivx);
    
end;
