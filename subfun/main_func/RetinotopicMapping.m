function RetinotopicMapping(Parameters, Emulate, Debug)
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


%% Initialize

% Randomness
SetUpRand;

% Eytetracker
ivx = EyeTrackInit(Parameters);

% Behavioural data variables
Behaviour = struct;
Behaviour.EventTime = [];
Behaviour.Response = [];
Behaviour.ResponseTime = [];


%% Configure scanner
[TrigStr, Parameters] = ConfigScanner(Emulate, Parameters);


%% Event timings
Events = CreateEventsTiming(Parameters);


try
    
    %% Initialize PTB
    if Debug
        PsychDebugWindowConfiguration
    end
    
    KeyCodes = SetupKeyCodes;
    
    [Win, Rect, ~, ifi] = InitPTB(Parameters);
    
    %% Load background movie
    StimRect = [0 0 size(Parameters.Stimulus,2) size(Parameters.Stimulus,1)];
    BgdTextures = LoadBckGrnd(Parameters, Win);
    
    %% Create fixation cross
    FixCross = CrossMatrix(16) * 255;
    [fh, fw] = size(FixCross);
    FixCross(:,:,2) = FixCross;   % alpha layer
    FixCross(:,:,1) = InvertContrast(FixCross(:,:,1));
    FixCrossTexture = Screen('MakeTexture', Win, FixCross);
    FixCrossRect = CenterRectOnPoint([0 0 fh fw], Rect(3)/2, Rect(4)/2);

    %% Stand by screen
    Screen('FillRect', Win, Parameters.Background, Rect);
    DrawFormattedText(Win, [Parameters.Instruction '\n \n' TrigStr], ...
        'center', 'center', Parameters.Foreground);

    Screen('Flip', Win);
    
    HideCursor;
    Priority(MaxPriority(Win));
    
    %% Wait for start of experiment
    if Emulate == 1
        KbPressWait
        WaitSecs(Parameters.TR*Parameters.Dummies);
    else
        [MyPort] = WaitForScanTrigger(Parameters);
    end
    
    EyeTrackStart(ivx, Parameters)   
    
    
    %% Begin main experiment
    FrameTimes = [];  % Time stamp of each frame
    CurrFrame = 1;  % Current stimulus frame
    CurrRefresh = 0;   % Current video refresh
    CurrAngle = 0;  % Current angle of wedge
    CurrScale = 0;  % Current inner radius of ring
    PrevKeypr = 0;
    
    % currentScale is scale of outer ring (exceeding screen until innter ring reaches window boarder)
    maxEcc = Parameters.FOV/2 + Parameters.AppertureWidth + log(Parameters.FOV/2+1) ; 
    % csFuncFact is used to expand with log increasing speed so that ring is at maxEcc at end of cycle
    csFuncFact = 1/ ((maxEcc+exp(1))*log(maxEcc+exp(1)) - (maxEcc+exp(1))) ; 
    CurrRingWidthVA = Parameters.AppertureWidth;
    
    
    %% Initialize apperture texture
    AppTexture = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
    
    
    %% Start cycling the stimulus
    Behaviour.EventTime = Events;
    CycleDuration = Parameters.TR * Parameters.VolsPerCycle;
    CyclingEnd = CycleDuration * Parameters.CyclesPerExpmt;
    CyclingStart = GetSecs;
    CurrTime = GetSecs - CyclingStart;
    IsEvent = false;
    WasEvent = false;
    Events2 = [];
    
    save([Parameters.OutputFilename '.mat']);
    
    
    %% Draw the fixation cross
    Screen('FillRect', Win, Parameters.Background, Rect);
    
    Screen('DrawTexture', Win, FixCrossTexture, [0 0 fh fw], FixCrossRect);
    
    rft = Screen('Flip', Win);
    
    StartExpmt = rft;   % Time when cycling starts

    
    % Loop until the end of last cycle
    while CurrTime < CyclingEnd
        
        
        %% Update frame number
        CurrRefresh = CurrRefresh + 1;
        if CurrRefresh == Parameters.RefreshPerStim
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
            CurrAngle = 90 - Parameters.AppertureWidth/2 + (CurrTime/CycleDuration) * 360;
        elseif strcmpi(Parameters.Direction, '-')
            CurrAngle = 90 - Parameters.AppertureWidth/2 - (CurrTime/CycleDuration) * 360;
        end
        % Size of apperture (CurrScale only influences  ring)
        if strcmpi(Parameters.Direction, '+')
            %CurrScale = 0 + mod(CurrTime, CycleDuration)/CycleDuration * StimRect(4);
            
            %---tr: vary CurrScale so that expansion speed is log over eccentricity
            % cf. Tootell 1997; Swisher 2007; Warnking 2002 etc;
            CurrScaleVA = 0 + mod(CurrTime, CycleDuration)/CycleDuration * maxEcc; % current visual angle linear in time
            % ensure some foveal stimulation at beginning (which is hidden by fixation cross otherwise)
            if CurrScaleVA < 0.5
                CurrScaleVA = 0.5;
            end
        elseif strcmpi(Parameters.Direction, '-')
            %CurrScale = StimRect(4) - mod(CurrTime, CycleDuration)/CycleDuration * StimRect(4);
            CurrScaleVA = maxEcc - mod(CurrTime, CycleDuration)/CycleDuration * maxEcc;
            if CurrScaleVA > maxEcc - 0.5
                CurrScaleVA = maxEcc - 0.5;
            end
        end
        
        % near-exp visual angle
        CurrScaleVA2 = ((CurrScaleVA+exp(1)) * log(CurrScaleVA+exp(1)) - (CurrScaleVA+exp(1))) * maxEcc * csFuncFact;
        CurrScaleCm = tan(CurrScaleVA2*pi/180)* Parameters.viewDist; % in cm  on screen
        CurrScale = CurrScaleCm / (Parameters.xWidthScreen/2) * (StimRect(4)/2) * 2;% in pixel
        
        %--tr width of apperture changes logarithmically with eccentricity of inner ring, cf.
        %authors above
        if strcmpi(Parameters.Apperture, 'Ring')
            oldScaleInnerVA = CurrScaleVA - CurrRingWidthVA;
            if oldScaleInnerVA < 0
                oldScaleInnerVA = 0;
            end
            CurrRingWidthVA = Parameters.AppertureWidth + log(oldScaleInnerVA+1); % growing with inner ring ecc
            CurrScaleInnerVA = CurrScaleVA2 - CurrRingWidthVA;
            CurrScaleInnerCM = tan(CurrScaleInnerVA*pi/180)* Parameters.viewDist; % in cm  on screen
            CurrScaleInner =  2*(CurrScaleInnerCM / (Parameters.xWidthScreen/2) * (StimRect(4)/2));% in pixel
            if CurrScaleInner < 0
                CurrScaleInner = 0;
            end
        end
        
        % Current frame time & condition
        if strcmpi(Parameters.Apperture, 'Ring')
            FrameTimes = [FrameTimes; CurrTime CurrFrame CurrAngle CurrScale CurrScaleVA2 CurrScaleInner CurrScaleInnerVA];
        elseif strcmpi(Parameters.Apperture, 'Wedge')
            FrameTimes = [FrameTimes; CurrTime CurrFrame CurrAngle CurrScale];
        end
        
        
        %% Create apperture texture
        Screen('Fillrect', AppTexture, Parameters.Background);
        if strcmpi(Parameters.Apperture, 'Ring')
            Screen('FillOval', AppTexture, [0 0 0 0], ...
                CenterRectOnPoint([0 0 repmat(CurrScale,1,2)], Rect(3)/2, Rect(4)/2 ));
            
            Screen('FillOval', AppTexture, [Parameters.Background 255], ...
                CenterRectOnPoint([0 0 repmat(CurrScaleInner,1,2)], Rect(3)/2, Rect(4)/2 ));
            
            % Wrapping around?
            %         %WrapAround = CurrScale+CurrRingWidth-StimRect(4);
            %         WrapAround = CurrScale+ wrapAroundPix -StimRect(4);
            %         if WrapAround < 0
            %             WrapAround = 0;
            %         end
            %         %Screen('FillOval', AppTexture, [0 0 0 0], CenterRect([0 0 repmat(WrapAround,1,2)], Rect));
            %         Screen('FillOval', AppTexture, [0 0 0 0], CenterRectOnPoint([0 0 repmat(WrapAround,1,2)],centerRing(1),centerRing(2)));
        elseif strcmpi(Parameters.Apperture, 'Wedge')
            Screen('FillArc', AppTexture, [0 0 0 0], ...
                CenterRect([0 0 repmat(StimRect(4),1,2)], Rect), CurrAngle, Parameters.AppertureWidth);
        end
        
        
        %% Draw stimulus
        
        % Display background
        if Parameters.RotateStimulus
            BgdAngle = CurrAngle;
        else
            BgdAngle = 0;
        end
        
        % Rotate background movie?
        SineRotate = cos(CurrTime) * Parameters.SineRotation;
        
        Screen('DrawTexture', Win, BgdTextures(CurrFrame), StimRect, ...
            CenterRect(StimRect, Rect), BgdAngle+SineRotate);
        
        % Draw aperture
        Screen('DrawTexture', Win, AppTexture);
        DrawCross(Win, Parameters, FixCrossTexture, fh, fw, FixCrossRect)
        
        
        %% Draw target
        
        CurrEvents = Events - CurrTime;
        
        if strcmp(Parameters.Apperture,'Wedge') && sum(CurrEvents > 0 & CurrEvents < Parameters.EventDuration)
            IsEvent = true;
            Events2 = [Events2, GetSecs-CyclingStart]; % for relating shown events and responses in ring runs
        elseif strcmp(Parameters.Apperture,'Ring') && (CurrScaleInnerVA > 10) && sum(CurrEvents > 0 & CurrEvents < Parameters.EventDuration)
            IsEvent = true;
            Events2 = [Events2, GetSecs-CyclingStart];
        else
            IsEvent = false;
        end
        
        if IsEvent == true
            
            if WasEvent == false
                RndAngle = RandOri;
                % if ring is presented under wide V FOV condition, target
                % appears only @ 0 or 180 degree (tr)
                if strcmpi(Parameters.Apperture, 'Ring')
                    possAngle = [0,180];
                    RndAngle = possAngle(randi(2,[1 1]));
                end
                RndScale = round(rand*(Rect(4)/2));
                WasEvent = true;
            end
            
            if strcmpi(Parameters.Apperture, 'Wedge')
                [X, Y] = pol2cart((90 + CurrAngle + Parameters.AppertureWidth/2) / 180*pi, RndScale);
            elseif strcmpi(Parameters.Apperture, 'Ring')
                % target always on horizontal meridian
                [X, Y] = pol2cart(RndAngle/180*pi,(CurrScale/2 + CurrScaleInner/2)/2);
            end
            
            % tr
            X = Rect(3)/2-X;
            Y = Rect(4)/2-Y;

            % Draw event
            Screen('FillOval', Win, ...
                Parameters.EventColor,...
                [X-Parameters.EventSize/2 ...
                Y-Parameters.EventSize/2 ...
                X+Parameters.EventSize/2 ...
                Y+Parameters.EventSize/2]);
            
        elseif IsEvent == false
            WasEvent = false;
            
        end
        
        %% Draw current video frame
        rft = Screen('Flip', Win, rft+ifi);
        
        %% Behavioural response
        [Behaviour] = GetBehResp(KeyCodes, Win, Parameters, Rect, PrevKeypr, Behaviour, CyclingStart);
        
    end
    
    
    %% Draw the fixation cross
    DrawCross(Win, Parameters, FixCrossTexture, fh, fw, FixCrossRect)
    EndExpmt = Screen('Flip', Win);
    
    
    %% Farewell screen
    FarewellScreen(Win, Parameters, Rect)
    
    CleanUp
    
    %% Save workspace
    % clear stim from structure and a few variables to save memory
    Parameters = rmfield(Parameters, 'Stimulus');
    Parameters.Stimulus = []; 
    clear('Apperture', 'R', 'T', 'X', 'Y');
    if IsOctave
        save([Parameters.OutputFilename '.mat'], '-mat7-binary');
    else
        save([Parameters.OutputFilename '.mat'], '-v7.3');
    end
    
    %% Experiment duration
    DispExpDur(EndExpmt, StartExpmt)

    WaitSecs(1);
    
    if Emulate ~= 1
        IOPort('ConfigureSerialPort', MyPort, 'StopBackgroundRead');
        IOPort('Close', MyPort);
    end
    
    EyeTrackStop(ivx, Parameters)
    
catch
    CleanUp
    psychrethrow(psychlasterror);
end
