function BarsMapping(PARAMETERS, Emulate, Debug, SaveAps)
%Bars_Mapping(PARAMETERS, Emulate, SaveAps)
%
% Runs the drifting bar protocol for mapping population receptive fields.
% If SaveAps is true it saves the aperture mask for each volume (for pRF).
%

if nargin < 4
    SaveAps = true;
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

    BgdTextures = LoadBckGrnd(PARAMETERS, Win);
    
    
    %% Initialize
    CircAperture = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
    
    % In case we want to save the aperture to facilitate pRF modelling
    if SaveAps
        [~,~,~] = mkdir(PARAMETERS.Aperture.TargetDir);
        Apertures.Frames = zeros(...
            PARAMETERS.Aperture.Dimension, ...
            PARAMETERS.Aperture.Dimension, ...
            PARAMETERS.VolsPerCycle * length(PARAMETERS.Conditions));
        SavWin = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
    else
        Apertures = [];
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
    BarWidth = StimRect(3) / PARAMETERS.VolsPerCycle;
    BarPos = [0 : BarWidth : StimRect(3)-BarWidth] + (Rect(3)/2-StimRect(3)/2) + BarWidth/2;
    PARAMETERS.AppertureWidth = BarWidth / PPD; % Width of bar in degrees of VA (needed for saving)
    PARAMETERS.BarPos = (BarPos - Rect(3)/2) / PPD; % in VA
    
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
        TrialOnset = GetSecs - StartExpmt;
        
        % Stimulation sequence
        CURRENT.Condit = PARAMETERS.Conditions(Trial);
        
        CURRENT.Volume = 1;
        PreviousVolume = 0;
        
        while CURRENT.Volume <= PARAMETERS.VolsPerCycle

            CURRENT.Time = GetSecs - StartExpmt;
            
            % we change the aperture with every volume
            if PreviousVolume==CURRENT.Volume
                NewAperture = false;
            else
                NewAperture = true;
            end
            
            %% Determine current frame
            
            CURRENT.Frame = CURRENT.Frame + 1;
            
            CURRENT.BarPos = BarPos(CURRENT.Volume);
            
            if CURRENT.Frame > PARAMETERS.RefreshPerStim
                CURRENT.Frame = 1;
                CURRENT.Stim = CURRENT.Stim + 1;
            end
            SaveAps = true;
            if CURRENT.Stim > size(PARAMETERS.Stimulus, length(size(PARAMETERS.Stimulus)))
                CURRENT.Stim = 1;
            end
            
            
            %% Create Aperture
            % aperture is the color of the background
            
            Screen('FillRect', CircAperture, PARAMETERS.Background);
            
            % We let the stimulus through
            Screen('FillOval', CircAperture, [0 0 0 0], CenterRect([0 0 repmat(StimRect(3), 1, 2)], Rect));
            
            % Then we add the position of the bar aperture
            Screen('FillRect', CircAperture, PARAMETERS.Background, ...
                [0 0 CURRENT.BarPos - BarWidth/2 Rect(4)]);
            
            Screen('FillRect', CircAperture, PARAMETERS.Background, ...
                [CURRENT.BarPos + BarWidth/2 0 Rect(3) Rect(4)]);
            
            
            %% Draw stimulus
            % we draw the background stimulus in full and overlay an aperture
            % on top of it
        
            % Rotate background movie
            BgdAngle = cos(GetSecs - TrialOnset) * PARAMETERS.SineRotation;
            
            % Draw movie frame
            Screen('DrawTexture', Win, BgdTextures(CURRENT.Stim), StimRect, ...
                CenterRect(StimRect, Rect), BgdAngle + CURRENT.Condit - 90);
            
            % Draw aperture and we rotate to match the required condition
            Screen('DrawTexture', Win, CircAperture, Rect, Rect, CURRENT.Condit - 90);
            
            % (and save if desired)
            if SaveAps && NewAperture
                Screen('DrawTexture', SavWin, CircAperture, Rect, Rect, CURRENT.Condit - 90);
                CurApImg = Screen('GetImage', SavWin, CenterRect(StimRect, Rect));
                CurApImg = ~CurApImg(:,:,1);
                
                % store frame, its angle and its distance to the center 
                Apertures.Frames(:, :, PARAMETERS.VolsPerCycle * (Trial-1) + CURRENT.Volume ) = ...
                    imresize(CurApImg, [PARAMETERS.Aperture.Dimension PARAMETERS.Aperture.Dimension]);
                Apertures.BarAngle(PARAMETERS.VolsPerCycle * (Trial-1) + CURRENT.Volume ) = ...
                    CURRENT.Condit - 90;
                Apertures.BarPostion(PARAMETERS.VolsPerCycle * (Trial-1) + CURRENT.Volume ) = ...
                    PARAMETERS.BarPos(CURRENT.Volume);
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
            
            FrameTimesUpdate = [CURRENT.Time CURRENT.Frame CURRENT.Condit PARAMETERS.BarPos(CURRENT.Volume)]; 
            
            % CURRENT Frame, time & condition (can also be valuable for debugging)
            FrameTimes = [FrameTimes; FrameTimesUpdate]; %#ok<AGROW>
            
            
            %% Behavioural response
            [BEHAVIOUR, PrevKeypr, QUIT] = ...
                GetBehResp(KeyCodes, Win, PARAMETERS, Rect, PrevKeypr, BEHAVIOUR, StartExpmt);
            
            if QUIT
                return
            end
            
            % Determine current volume
            PreviousVolume=CURRENT.Volume;
            CURRENT.Volume = floor((CURRENT.Time - TrialOnset) / PARAMETERS.TR) + 1;

            
        end
        
    end
    
    
    %% Draw the fixation
    Screen('FillOval', Win, PARAMETERS.Foreground, ...
        CenterRect([0 0 FixationSizePix FixationSizePix], Rect));
    
    EndExpmt = Screen('Flip', Win);
    
   
    %% Save workspace
    BEHAVIOUR.EventTime = Events;
    BEHAVIOUR.TargetData = TargetData;
    
    Data = Save2TSV(FrameTimes, BEHAVIOUR, PARAMETERS, StimRect);
    
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
    
    EyeTrackStop(ivx, PARAMETERS)
    
    
    %% Farewell screen
    FarewellScreen(Win, PARAMETERS, Rect)
    
    CleanUp
    
    
    %% Save apertures
    SaveApertures(SaveAps, PARAMETERS, Apertures)

    
catch
    CleanUp
    psychrethrow(psychlasterror);
end
