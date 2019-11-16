function BarsMapping(PARAMETERS, Emulate, Debug, SaveAps)
%Bars_Mapping(PARAMETERS, Emulate, SaveAps)
%
% Runs the drifting bar protocol for mapping population receptive fields.
% If SaveAps is true it saves the aperture mask for each volume (for pRF).
%

if nargin < 4
    SaveAps = false;
end


%% Setup
SetUpRand

% Eytetracker
ivx = EyeTrackInit(PARAMETERS);

% Event timings
% Events is a vector that says when (in seconds from the start of the
% experiment) a target should be presented.
PARAMETERS.CyclesPerExpmt = length(PARAMETERS.Conditions);
Events = CreateEventsTiming(PARAMETERS);

% Configure scanner
[TrigStr, PARAMETERS] = ConfigScanner(Emulate, PARAMETERS);


try
    
    %% Initialize PTB
    if Debug
        PsychDebugWindowConfiguration
    end
    
    KeyCodes = SetupKeyCodes;
    
    [Win, Rect, ~, ifi] = InitPTB(PARAMETERS);

    % compute pixels per degree and apply conversion
    PPD = GetPPD(Rect, PARAMETERS.xWidthScreen , PARAMETERS.viewDist);
    TARGET.EventSizePix = PARAMETERS.EventSize * PPD;
    FixationSizePix = PARAMETERS.FixationSize * PPD;
    
    
    %% Load background movie
    StimRect = [0 0 repmat(size(PARAMETERS.Stimulus,1), 1, 2)];
    
    BarWidth = StimRect(3)/PARAMETERS.VolsPerCycle;
    PARAMETERS.AppertureWidth = BarWidth / PPD; % Width of bar in degrees of VA (needed for saving)
    
    BgdTextures = LoadBckGrnd(PARAMETERS, Win);
    
    
    %% Initialize
    CircAperture = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
    if SaveAps
        ApFrm = zeros(100, 100, PARAMETERS.VolsPerCycle * length(PARAMETERS.Conditions));
        SavWin = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
    end
    
    % Background variables
    CURRENT.Frame = 0;
    CURRENT.Stim = 1;
    
    IsRing = [];
    RING = [];
    
    BEHAVIOUR.Response = [];
    BEHAVIOUR.ResponseTime = [];
    
    TARGET.WasEvent = false;
    
    PrevKeypr = 0;
    
    FrameTimes = [];
    
    CURRENT.Volume = 0;

    % Set parameters drifting bars and add to parameters list for saving
    DriftPerVol = StimRect(3) / PARAMETERS.VolsPerCycle;
    BarPos = [0 : DriftPerVol : StimRect(3)-DriftPerVol] + (Rect(3)/2-StimRect(3)/2) + DriftPerVol/2;
    PARAMETERS.DriftPerVol = DriftPerVol;
    PARAMETERS.BarPos = BarPos;
    
    %% Standby screen
    Screen('FillRect', Win, PARAMETERS.Background, Rect);
    
    DrawFormattedText(Win, ...
        [PARAMETERS.Welcome '\n \n' PARAMETERS.Instruction '\n \n' TrigStr], ...
        'center', 'center', PARAMETERS.Foreground);
    
    Screen('Flip', Win);
    
    HideCursor;
    
    % Tell PTB we want to hoag a max of ressources
    Priority(MaxPriority(Win));
    
    
    %% Wait for start of experiment
    if Emulate == 1
        [~, Key, ~] = KbPressWait;
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
    rft = Screen('Flip', Win);
    
    StartExpmt = rft;
    
    
    %% Run stimulus sequence
    for Trial = 1 : length(PARAMETERS.Conditions)

        % Begin trial
        TrialOutput.TrialOnset = GetSecs - StartExpmt;
        
        % Stimulation sequence
        CURRENT.Condit = PARAMETERS.Conditions(Trial);
        
        CURRENT.Volume = 1;
        
        while CURRENT.Volume <= PARAMETERS.VolsPerCycle

            CURRENT.Time = GetSecs - StartExpmt;
            
            %% Determine current frame
            
            CURRENT.Frame = CURRENT.Frame + 1;
            
            CURRENT.BarPos = BarPos(CURRENT.Volume);
            
            if CURRENT.Frame > PARAMETERS.RefreshPerStim
                CURRENT.Frame = 1;
                CURRENT.Stim = CURRENT.Stim + 1;
            end
            
            if CURRENT.Stim > size(PARAMETERS.Stimulus, length(size(PARAMETERS.Stimulus)))
                CURRENT.Stim = 1;
            end
            
            
            %% Create Aperture
            Screen('FillRect', CircAperture, PARAMETERS.Background);
            
            Screen('FillOval', CircAperture, [0 0 0 0], CenterRect([0 0 repmat(StimRect(3), 1, 2)], Rect));
            
            if mod(CURRENT.Condit, 90) ~= 0 && CURRENT.Volume > PARAMETERS.VolsPerCycle/2
                
                Screen('FillRect', CircAperture, PARAMETERS.Background);
                
            else
                
                Screen('FillRect', CircAperture, PARAMETERS.Background, ...
                    [0 0 CURRENT.BarPos - BarWidth/2 Rect(4)]);
                
                Screen('FillRect', CircAperture, PARAMETERS.Background, ...
                    [CURRENT.BarPos + BarWidth/2 0 Rect(3) Rect(4)]);
            end
            
            
            %% Draw stimulus
            % Rotate background movie?
            BgdAngle = cos(GetSecs - TrialOutput.TrialOnset) * PARAMETERS.SineRotation;
            
            % Draw movie frame
            Screen('DrawTexture', Win, BgdTextures(CURRENT.Stim), StimRect, ...
                CenterRect(StimRect, Rect), BgdAngle + CURRENT.Condit - 90);
            
            % Draw aperture 
            Screen('DrawTexture', Win, CircAperture, Rect, Rect, CURRENT.Condit - 90);
            
            % (and save if desired)
            if SaveAps
                Screen('DrawTexture', SavWin, CircAperture, Rect, Rect, CURRENT.Condit - 90);
                CurApImg = Screen('GetImage', SavWin, CenterRect(StimRect, Rect));
                CurApImg = ~CurApImg(:,:,1);
                ApFrm(:, :, PARAMETERS.Volumes_per_Trial * (Trial-1) + CURRENT.Volume ) = ...
                    imresize(CurApImg, [100 100]);
            end
            
            
            %% Draw fixation
            
            % Draw gap around fixation
            Screen('FillOval', Win, PARAMETERS.Background, ...
                CenterRect([0 0 FixationSizePix+10 FixationSizePix+10], Rect));
            
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
            
            FrameTimesUpdate = [CURRENT.Time CURRENT.Frame CURRENT.Condit CURRENT.BarPos]; 
            
            % CURRENT Frame, time & condition (can also be valuable for debugging)
            FrameTimes = [FrameTimes; FrameTimesUpdate]; %#ok<AGROW>
            
            
            %% Behavioural response
            [BEHAVIOUR, PrevKeypr, QUIT] = ...
                GetBehResp(KeyCodes, Win, PARAMETERS, Rect, PrevKeypr, BEHAVIOUR, StartExpmt);
            
            if QUIT
                return
            end
            
            % Determine current volume
            CURRENT.Volume = floor((CURRENT.Time - TrialOutput.TrialOnset) / PARAMETERS.TR) + 1;

            
        end
        
    end
    
    
    %% Draw the fixation
    Screen('FillOval', Win, PARAMETERS.Foreground, ...
        CenterRect([0 0 FixationSizePix FixationSizePix], Rect));
    
    EndExpmt = Screen('Flip', Win);
    
   
    %% Save workspace
    BEHAVIOUR.EventTime = Events;
    BEHAVIOUR.TargetData = TargetData;
    
    Data = Save2TSV(FrameTimes, BEHAVIOUR, PARAMETERS);
    
    FeedbackScreen(Win, PARAMETERS, Rect, Data)

    % clear stim from structure and a few variables to save memory
    PARAMETERS = rmfield(PARAMETERS, 'Stimulus');
    
    if IsOctave
        save([PARAMETERS.OutputFilename '.mat'], '-mat7-binary');
    else
        save([PARAMETERS.OutputFilename '.mat'], '-v7.3');
    end
    
    WaitSecs(4);
    
    
    %% Experiment duration
    DispExpDur(EndExpmt, StartExpmt)
    
    WaitSecs(1);
    
    if Emulate ~= 1
        IOPort('ConfigureSerialPort', MyPort, 'StopBackgroundRead');
        IOPort('Close', MyPort);
    end
    
    EyeTrackStop(ivx, PARAMETERS)
    
    
    %% Farewell screen
    FarewellScreen(Win, PARAMETERS, Rect)
    
    CleanUp
    
    
    %% Save apertures
    if SaveAps
        save('pRF_Apertures', 'ApFrm');
    end

    
catch
    CleanUp
    psychrethrow(psychlasterror);
end
