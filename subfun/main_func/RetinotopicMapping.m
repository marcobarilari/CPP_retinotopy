function RetinotopicMapping(Parameters, Emulate, Debug)
%Retinotopic_Mapping(Parameters, Emulate)
%
% Cyclic presentation with a rotating and/or expanding aperture.
% Behind the aperture a background is displayed as a movie.
%
% Parameters:
%   Parameters :    Struct containing various parameters
%   Emulate :       0 for scanning
%                   1 for manual trigger


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
    
    % compute pixels per degree
    PPD = GetPPD(Rect, Parameters.xWidthScreen , Parameters.viewDist);
    Target.EventSizePix = Parameters.EventSize * PPD;
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
    Current.Frame = 1;  % Current stimulus Frame
    Current.Refresh = 0;   % Current video Refresh
    Current.Angle = 0;  % Current Angle of wedge
    Ring.ScalePix = 0;  % Current inner radius of ring
    
    PrevKeypr = 0;
    
    if IsRing
        % currentScale is scale of outer ring (exceeding screen until inner ring reaches window boarder)
        Ring.MaxEcc = Parameters.FOV / 2 + Parameters.AppertureWidth + log(Parameters.FOV/2 + 1) ;
        % Ring.CsFuncFact is used to expand with log increasing speed so that ring is at Ring.MaxEcc at end of cycle
        Ring.CsFuncFact = 1 / ( (Ring.MaxEcc + exp(1)) * log(Ring.MaxEcc + exp(1)) - (Ring.MaxEcc + exp(1)) ) ;
        % Current ring width in visual Current.Angle
        Ring.RingWidthVA = Parameters.AppertureWidth;
    end
    
    
    %% Initialize apperture texture
    AppTexture = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
    
    
    %% Start cycling the stimulus
    CycleDuration = Parameters.TR * Parameters.VolsPerCycle;
    CyclingEnd = CycleDuration * Parameters.CyclesPerExpmt;
    CyclingStart = GetSecs;
    Current.Time = 0;
    Ring.ScaleInnerVA = 0;
    Target.WasEvent = false;
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
    
    StartExpmt = rft;   % Current.Time when cycling starts
    
    
    % Loop until the end of last cycle
    while Current.Time < CyclingEnd
        
        
        %% Update Frame number
        Current.Refresh = Current.Refresh + 1;
        if Current.Refresh == Parameters.RefreshPerStim
            
            Current.Refresh = 0;
            Current.Frame = Current.Frame + 1;
            
            if Current.Frame > size(Parameters.Stimulus, ndims(Parameters.Stimulus))
                Current.Frame = 1;
            end
            
        end
        
        % Current Time stamp
        Current.Time = GetSecs-CyclingStart;
        
        
        %% Determine size & angle
        
        % Rotation of apperture
        switch Parameters.Direction
            case '+'
                Current.Angle = 90 - Parameters.AppertureWidth/2 + (Current.Time/CycleDuration) * 360;
            case '-'
                Current.Angle = 90 - Parameters.AppertureWidth/2 - (Current.Time/CycleDuration) * 360;
        end
        
        % expansion speed is log over eccentricity
        [Ring] = EccenLogSpeed(Parameters, PPD, Ring, Current.Time);   
        
        
        %% Create apperture texture
        Screen('Fillrect', AppTexture, Parameters.Background);
        
        FrameTimesUpdate = [Current.Time Current.Frame Current.Angle];
        
        if IsRing
            
            Screen('FillOval', AppTexture, [0 0 0 0], ...
                CenterRectOnPoint([0 0 repmat(Ring.ScalePix,1,2)], Rect(3)/2, Rect(4)/2 ));
            
            Screen('FillOval', AppTexture, [Parameters.Background 255], ...
                CenterRectOnPoint([0 0 repmat(Ring.ScaleInnerPix,1,2)], Rect(3)/2, Rect(4)/2 ));
            
            FrameTimesUpdate = [FrameTimesUpdate, ...
                Ring.ScalePix Ring.ScaleVA2 Ring.ScaleInnerPix Ring.ScaleInnerVA]; %#ok<AGROW>
            
        else
            
            Screen('FillArc', AppTexture, [0 0 0 0], ...
                CenterRect([0 0 repmat(StimRect(4),1,2)], Rect), Current.Angle, Parameters.AppertureWidth);
            
        end
        
        % Current Frame, Time & condition
        FrameTimes = [FrameTimes; FrameTimesUpdate]; %#ok<AGROW>
        
        
        %% Draw stimulus
        
        % Display background
        if Parameters.RotateStimulus
            BgdAngle = Current.Angle;
        else
            BgdAngle = 0;
        end
        
        % Rotate background movie
        SineRotate = cos(Current.Time) * Parameters.SineRotation;
        
        Screen('DrawTexture', Win, BgdTextures(Current.Frame), StimRect, ...
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
        [Target] = DrawTarget(Target, Events, IsRing, Current, Ring, Win, Rect, Parameters);

        
        %% Draw current video Current.Frame
        rft = Screen('Flip', Win, rft+ifi);
        
        if Target.IsEvent
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
