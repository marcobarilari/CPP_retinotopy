function [Data, PARAMETERS] = RetinotopicMapping(PARAMETERS, Emulate, Debug)
%Retinotopic_Mapping(PARAMETERS, Emulate)
%
% Cyclic presentation with a rotating and/or expanding aperture.
% Behind the aperture a background is displayed as a movie.
%
% PARAMETERS:
%   PARAMETERS :    Struct containing various parameters
%   Emulate :       0 for scanning
%                   1 for manual trigger
%   Debug : will play the experiment with PTB transparency

% BEHAVIOUR: structure to collect behavioural responses and target presentation time
% CURRENT: structure to keep track of which frame, refreshcycle, time, angle...
% RING: structure to keep of several information about the annulus size

%% Setup


% Randomness
SetUpRand;

% Eytetracker
ivx = EyeTrackInit(PARAMETERS);

switch PARAMETERS.Apperture
    case 'Ring'
        IsRing = true;
    otherwise
        IsRing = false;
end

% Configure scanner
[TrigStr, PARAMETERS] = ConfigScanner(Emulate, PARAMETERS);

% Event timings
% Events is a vector that says when (in seconds from the start of the
% experiment) a target should be presented.
Events = CreateEventsTiming(PARAMETERS);


try
    
    %% Initialize PTB
    if Debug
        PsychDebugWindowConfiguration
    end
    
    % Define escapte key and response button
    KeyCodes = SetupKeyCodes;
    
    [Win, Rect, ~, ifi] = InitPTB(PARAMETERS);
    
    % compute pixels per degree and apply conversion
    PPD = GetPPD(Rect, PARAMETERS.xWidthScreen , PARAMETERS.viewDist);
    TARGET.EventSizePix = PARAMETERS.EventSize * PPD;
    FixationSizePix = PARAMETERS.FixationSize * PPD;
    
    
    %% Load background movie
    StimRect = [0 0 size(PARAMETERS.Stimulus,2) size(PARAMETERS.Stimulus,1)];
    BgdTextures = LoadBckGrnd(PARAMETERS, Win);
    
    
    %% Initialize
    AppTexture = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
    
    Data = [];
    TargetData = [];
    FrameTimes = [];  % To collet info about the frames
    
    CURRENT.Frame = 1;  % CURRENT stimulus Frame
    CURRENT.Refresh = 0;   % CURRENT video Refresh
    CURRENT.Angle = 0;  % CURRENT Angle of wedge
    CURRENT.Time = 0;
    
    RING.ScalePix = 0;  % CURRENT inner radius of ring
    RING.ScaleInnerVA = 0;
    
    TARGET.WasEvent = false;
    
    PrevKeypr = 0;
    
    BEHAVIOUR.Response = [];
    BEHAVIOUR.ResponseTime = [];

    % Set parameters for rings
    if IsRing
        % currentScale is scale of outer ring (exceeding screen until inner ring reaches window boarder)
        RING.MaxEcc = PARAMETERS.FOV / 2 + PARAMETERS.AppertureWidth + log(PARAMETERS.FOV/2 + 1) ;
        % RING.CsFuncFact is used to expand with log increasing speed so that ring is at RING.MaxEcc at end of cycle
        RING.CsFuncFact = 1 / ( (RING.MaxEcc + exp(1)) * log(RING.MaxEcc + exp(1)) - (RING.MaxEcc + exp(1)) ) ;
        % CURRENT ring width in visual angle
        RING.RingWidthVA = PARAMETERS.AppertureWidth;
    end
    
    CycleDuration = PARAMETERS.TR * PARAMETERS.VolsPerCycle;
    CyclingEnd = CycleDuration * PARAMETERS.CyclesPerExpmt;
    
    
    %% Stand by screen
    Screen('FillRect', Win, PARAMETERS.Background, Rect);
    
    DrawFormattedText(Win, [PARAMETERS.Instruction '\n \n' TrigStr], ...
        'center', 'center', PARAMETERS.Foreground);
    
    Screen('Flip', Win);
    
    HideCursor;
    
    % Tell PTB we want to hoag a max of ressources
    Priority(MaxPriority(Win));
    
    
    %% Wait for start of experiment
    if Emulate == 1
        KbPressWait
        WaitSecs(PARAMETERS.TR*PARAMETERS.Dummies);
    else
        [MyPort] = WaitForScanTrigger(PARAMETERS);
    end
    
    EyeTrackStart(ivx, PARAMETERS)
    
    % Abort if Escape was pressed
    if Key(KeyCodes.Escape)
        % Abort screen
        Screen('FillRect', Win, PARAMETERS.Background, Rect);
        DrawFormattedText(Win, 'Experiment was aborted!', 'center', 'center', ...
            PARAMETERS.Foreground);
        CleanUp
        disp(' ');
        disp('Experiment aborted by user!');
        disp(' ');
        return
    end


    %% Start cycling the stimulus
    StartExpmt = GetSecs;
    
    rft = Screen('Flip', Win);
    
    
    %% Loop until the end of last cycle
    while CURRENT.Time < CyclingEnd
        
        
        %% Update Frame number
        CURRENT.Refresh = CURRENT.Refresh + 1;
        if CURRENT.Refresh == PARAMETERS.RefreshPerStim
            
            CURRENT.Refresh = 0;
            CURRENT.Frame = CURRENT.Frame + 1;
            
            if CURRENT.Frame > size(PARAMETERS.Stimulus, ndims(PARAMETERS.Stimulus))
                CURRENT.Frame = 1;
            end
            
        end
        
        % CURRENT Time stamp
        CURRENT.Time = GetSecs - StartExpmt;
        
        
        %% Determine size & angle
        
        % Update angle for rotation of background and for apperture for wedge
        switch PARAMETERS.Direction
            case '+'
                CURRENT.Angle = 90 - PARAMETERS.AppertureWidth/2 + (CURRENT.Time/CycleDuration) * 360;
            case '-'
                CURRENT.Angle = 90 - PARAMETERS.AppertureWidth/2 - (CURRENT.Time/CycleDuration) * 360;
        end
        
        % expansion speed is log over eccentricity
        [RING] = EccenLogSpeed(PARAMETERS, PPD, RING, CURRENT.Time);   
        
        
        %% Create apperture texture
        Screen('Fillrect', AppTexture, PARAMETERS.Background);
        
        FrameTimesUpdate = [CURRENT.Time CURRENT.Frame CURRENT.Angle];
        
        if IsRing
            
            Screen('FillOval', AppTexture, [0 0 0 0], ...
                CenterRectOnPoint([0 0 repmat(RING.ScalePix,1,2)], Rect(3)/2, Rect(4)/2 ));
            
            Screen('FillOval', AppTexture, [PARAMETERS.Background 255], ...
                CenterRectOnPoint([0 0 repmat(RING.ScaleInnerPix,1,2)], Rect(3)/2, Rect(4)/2 ));
            
            FrameTimesUpdate = [FrameTimesUpdate, ...
                RING.ScalePix RING.ScaleVA2 RING.ScaleInnerPix RING.ScaleInnerVA]; %#ok<AGROW>
            
        else
            
            Screen('FillArc', AppTexture, [0 0 0 0], ...
                CenterRect([0 0 repmat(StimRect(4),1,2)], Rect), CURRENT.Angle, PARAMETERS.AppertureWidth);
            
        end
        
        % CURRENT Frame, time & condition (can also be valuable for debugging)
        FrameTimes = [FrameTimes; FrameTimesUpdate]; %#ok<AGROW>
        
        
        %% Draw stimulus
        
        % Display background
        if PARAMETERS.RotateStimulus
            BgdAngle = CURRENT.Angle;
        else
            BgdAngle = 0;
        end
        
        % Rotate background movie
        SineRotate = cos(CURRENT.Time) * PARAMETERS.SineRotation;
        
        Screen('DrawTexture', Win, BgdTextures(CURRENT.Frame), StimRect, ...
            CenterRect(StimRect, Rect), BgdAngle + SineRotate);
        
        % Draw aperture
        Screen('DrawTexture', Win, AppTexture);
        
        % Draw fixation
        Screen('FillOval', Win, PARAMETERS.Foreground, ...
            CenterRect([0 0 FixationSizePix FixationSizePix], Rect));
        
        
        %% Draw target
        [TARGET] = DrawTarget(TARGET, Events, IsRing, CURRENT, RING, Win, Rect, PARAMETERS);

        
        %% Flip current frame
        rft = Screen('Flip', Win, rft+ifi);
        
        % collect target actual presentation time and target position
        if TARGET.Onset
             TargetData(end+1,[1 3:5]) = [rft-StartExpmt TARGET.X/PPD TARGET.Y/PPD PARAMETERS.EventSize]; %#ok<AGROW>
        elseif TARGET.Offset
            TargetData(end,2) = rft-StartExpmt;
        end
        
        %% Behavioural response
        [BEHAVIOUR, PrevKeypr, QUIT] = GetBehResp(KeyCodes, Win, PARAMETERS, Rect, PrevKeypr, BEHAVIOUR, StartExpmt);
        
        if QUIT
            CleanUp
            return
        end
        
    end
    
    
    %% Draw the fixation
    Screen('FillOval', Win, PARAMETERS.Foreground, ...
        CenterRect([0 0 FixationSizePix FixationSizePix], Rect));
    
    EndExpmt = Screen('Flip', Win);
    

    %% Give feedback and save
    BEHAVIOUR.EventTime = Events;
    BEHAVIOUR.TargetData = TargetData;
    
    Data = Save2TSV(FrameTimes, BEHAVIOUR, PARAMETERS);
    
    FeedbackScreen(Win, PARAMETERS, Rect, Data)

    % clear stim from structure and a few variables to save memory
    PARAMETERS = rmfield(PARAMETERS, 'Stimulus');

    if IsOctave
        save([PARAMETERS.OutputFilename '.mat'], '-mat7-binary', ...
            'FrameTimes', 'BEHAVIOUR', 'PARAMETERS', 'KeyCodes', 'StartExpmt');
    else
        save([PARAMETERS.OutputFilename '.mat'], '-v7.3', ...
            'FrameTimes', 'BEHAVIOUR', 'PARAMETERS', 'KeyCodes', 'StartExpmt');
    end

    WaitSecs(4);
    
    
    %% Experiment duration
    DispExpDur(EndExpmt, StartExpmt)
    
    WaitSecs(1);
    
    if Emulate ~= 1
        IOPort('ConfigureSerialPort', MyPort, 'StopBackgroundRead');
        IOPort('Close', MyPort);
    end
    
    EyeTrackStop(ivx, PARAMETERS);
    
    
    %% Farewell screen
    FarewellScreen(Win, PARAMETERS, Rect)
    
    CleanUp
    
    
catch
    CleanUp
    psychrethrow(psychlasterror);
end
