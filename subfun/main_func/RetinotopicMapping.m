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

switch Parameters.Apperture
    case 'Ring'
        IsRing = true;
    otherwise
        IsRing = false;
end


%% Configure scanner
[TrigStr, Parameters] = ConfigScanner(Emulate, Parameters);


%% Event timings
Events = CreateEventsTiming(Parameters);
Behaviour.EventTime = Events;

try
    
    %% Initialize PTB
    if Debug
        PsychDebugWindowConfiguration
    end
    
    KeyCodes = SetupKeyCodes;
    
    [Win, Rect, ~, ifi] = InitPTB(Parameters);
    
    PPD = GetPPD(Rect, Parameters.xWidthScreen , Parameters.viewDist);
    
    EventSizePix = Parameters.EventSize * PPD;
    FixationSizePix = Parameters.FixationSize * PPD;
    
    %% Load background movie
    StimRect = [0 0 size(Parameters.Stimulus,2) size(Parameters.Stimulus,1)];
    BgdTextures = LoadBckGrnd(Parameters, Win);
    
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
    CurrScalePix = 0;  % Current inner radius of ring
    PrevKeypr = 0;
    
    if IsRing
        % currentScale is scale of outer ring (exceeding screen until inner ring reaches window boarder)
        MaxEcc = Parameters.FOV / 2 + Parameters.AppertureWidth + log(Parameters.FOV/2 + 1) ;
        % csFuncFact is used to expand with log increasing speed so that ring is at maxEcc at end of cycle
        CsFuncFact = 1 / ( (MaxEcc + exp(1)) * log(MaxEcc + exp(1)) - (MaxEcc + exp(1)) ) ;
        % Current ring width in visual angle
        CurrRingWidthVA = Parameters.AppertureWidth;
    end
    
    
    %% Initialize apperture texture
    AppTexture = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
    
    
    %% Start cycling the stimulus
    CycleDuration = Parameters.TR * Parameters.VolsPerCycle;
    CyclingEnd = CycleDuration * Parameters.CyclesPerExpmt;
    CyclingStart = GetSecs;
    CurrTime = 0;
    CurrScaleInnerVA = 0;
    IsEvent = false;
    WasEvent = false;
    Events2 = [];
    
    save([Parameters.OutputFilename '.mat']);
    
    Screen('FillRect', Win, Parameters.Background, Rect);
    
    % Draw fixation
    Screen('FillOval', Win, ...
        [255 255 255],...
        [Rect(3)/2-FixationSizePix/2 ...
        Rect(4)/2-FixationSizePix/2 ...
        Rect(3)/2+FixationSizePix/2 ...
        Rect(4)/2+FixationSizePix/2]);
    
    rft = Screen('Flip', Win);
    
    StartExpmt = rft;   % Time when cycling starts
    
    
    % Loop until the end of last cycle
    while CurrTime < CyclingEnd
        
        
        %% Update frame number
        CurrRefresh = CurrRefresh + 1;
        if CurrRefresh == Parameters.RefreshPerStim
            
            CurrRefresh = 0;
            CurrFrame = CurrFrame + 1;
            
            if CurrFrame > size(Parameters.Stimulus, ndims(Parameters.Stimulus))
                CurrFrame = 1;
            end
            
        end
        
        % Current time stamp
        CurrTime = GetSecs-CyclingStart;
        
        
        %% Determine size & angle
        
        % Rotation of apperture
        switch Parameters.Direction
            case '+'
                CurrAngle = 90 - Parameters.AppertureWidth/2 + (CurrTime/CycleDuration) * 360;
            case '-'
                CurrAngle = 90 - Parameters.AppertureWidth/2 - (CurrTime/CycleDuration) * 360;
        end
        
        % CurrScale only influences  ring
        if IsRing
            
            %vary CurrScale so that expansion speed is log over eccentricity
            % cf. Tootell 1997; Swisher 2007; Warnking 2002 etc

            switch Parameters.Direction
                case '+'
                    % current visual angle linear in time
                    CurrScaleVA = 0 + mod(CurrTime, CycleDuration)/CycleDuration * MaxEcc; 
                    % ensure some foveal stimulation at beginning (which is hidden by fixation cross otherwise)
                    if CurrScaleVA < Parameters.FixationSize + .1
                        CurrScaleVA = 0.6;
                    end
                case '-'
                    CurrScaleVA = MaxEcc - mod(CurrTime, CycleDuration)/CycleDuration * MaxEcc;
                    if CurrScaleVA > MaxEcc - 0.1
                        CurrScaleVA = MaxEcc - 0.1;
                    end
            end
            
            % near-exp visual angle
            CurrScaleVA2 = ((CurrScaleVA+exp(1)) * log(CurrScaleVA+exp(1)) - (CurrScaleVA+exp(1))) * MaxEcc * CsFuncFact;
            CurrScalePix = CurrScaleVA2 *PPD; % in pixel

            %width of apperture changes logarithmically with eccentricity of inner ring            
            oldScaleInnerVA = CurrScaleVA - CurrRingWidthVA;
            if oldScaleInnerVA < 0
                oldScaleInnerVA = 0;
            end
            
            % growing with inner ring ecc
            CurrRingWidthVA = Parameters.AppertureWidth + log(oldScaleInnerVA+1); 
            CurrScaleInnerVA = CurrScaleVA2 - CurrRingWidthVA;
            CurrScaleInnerPix =  CurrScaleInnerVA *PPD; % in pixel
            
            if CurrScaleInnerPix < 0
                CurrScaleInnerPix = 0;
            end
        end
        
        
        %% Create apperture texture
        Screen('Fillrect', AppTexture, Parameters.Background);
        
        if IsRing
            
            Screen('FillOval', AppTexture, [0 0 0 0], ...
                CenterRectOnPoint([0 0 repmat(CurrScalePix,1,2)], Rect(3)/2, Rect(4)/2 ));
            
            Screen('FillOval', AppTexture, [Parameters.Background 255], ...
                CenterRectOnPoint([0 0 repmat(CurrScaleInnerPix,1,2)], Rect(3)/2, Rect(4)/2 ));
            
            FrameTimesUpdate = [CurrTime CurrFrame CurrAngle CurrScalePix CurrScaleVA2 CurrScaleInnerPix CurrScaleInnerVA];
            
        else
            
            Screen('FillArc', AppTexture, [0 0 0 0], ...
                CenterRect([0 0 repmat(StimRect(4),1,2)], Rect), CurrAngle, Parameters.AppertureWidth);
            
            
            FrameTimesUpdate = [CurrTime CurrFrame CurrAngle];
            
        end
        
        % Current frame time & condition
        FrameTimes = [FrameTimes; FrameTimesUpdate]; %#ok<AGROW>
        
        
        %% Draw stimulus
        
        % Display background
        if Parameters.RotateStimulus
            BgdAngle = CurrAngle;
        else
            BgdAngle = 0;
        end
        
        % Rotate background movie
        SineRotate = cos(CurrTime) * Parameters.SineRotation;
        
        Screen('DrawTexture', Win, BgdTextures(CurrFrame), StimRect, ...
            CenterRect(StimRect, Rect), BgdAngle + SineRotate);
        
        % Draw aperture
        Screen('DrawTexture', Win, AppTexture);
        
        % Draw fixation
        Screen('FillOval', Win, ...
            Parameters.Foreground,...
            [Rect(3)/2-FixationSizePix/2 ...
            Rect(4)/2-FixationSizePix/2 ...
            Rect(3)/2+FixationSizePix/2 ...
            Rect(4)/2+FixationSizePix/2]);
        
        
        %% Draw target
        
        CurrEvents = Events - CurrTime;
        
        if  all( [CurrEvents > 0 ; CurrEvents < Parameters.EventDuration] )
            IsEvent = true;
        else
            IsEvent = false;
        end
        
        if all( [IsRing ; CurrScaleInnerVA > 10] )
            IsEvent = false;
        end
        
        if IsEvent
            
            if ~WasEvent
                RndAngle = RandOri;
                RndScale = round(rand*(Rect(4)/2));
                WasEvent = true;
            end
            
            if IsRing
                % target always on horizontal meridian
                [X, Y] = pol2cart( RndAngle/180*pi, (CurrScalePix/2 + CurrScaleInnerPix/2)/2 );
            else
                [X, Y] = pol2cart( (90 + CurrAngle + Parameters.AppertureWidth/2) / 180*pi, RndScale );
            end
            
            % target position
            X = Rect(3)/2-X;
            Y = Rect(4)/2-Y;
            
            % Draw event
            Screen('FillOval', Win, ...
                Parameters.EventColor,...
                [X-EventSizePix/2 ...
                Y-EventSizePix/2 ...
                X+EventSizePix/2 ...
                Y+EventSizePix/2]);
            
        elseif ~IsEvent
            
            WasEvent = false;
            
        end
        
        %% Draw current video frame
        rft = Screen('Flip', Win, rft+ifi);
        
        if IsEvent
             Events2 = [Events2, rft];
        end
        
        %% Behavioural response
        [Behaviour, PrevKeypr, QUIT] = GetBehResp(KeyCodes, Win, Parameters, Rect, PrevKeypr, Behaviour, CyclingStart);
        
        if QUIT
            return
        end
        
    end
    
    
    %% Draw the fixation cross
    Screen('FillOval', Win, ...
        Parameters.Foreground,...
        [Rect(3)/2-FixationSizePix/2 ...
        Rect(4)/2-FixationSizePix/2 ...
        Rect(3)/2+FixationSizePix/2 ...
        Rect(4)/2+FixationSizePix/2]);
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
