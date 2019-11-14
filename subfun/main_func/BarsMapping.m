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

% switch PARAMETERS.Apperture
%     case 'Ring'
%         IsRing = true;
%     otherwise
%         IsRing = false;
% end

% Event timings
% Events is a vector that says when (in seconds from the start of the
% experiment) a target should be presented.
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
    
    
    %% Load background movie
    StimRect = [0 0 repmat(size(PARAMETERS.Stimulus,1), 1, 2)];
    
    BgdTextures = LoadBckGrnd(PARAMETERS, Win);
    
    DriftPerVol = StimRect(3) / PARAMETERS.VolumesPerTrial;
    BarPos = [0 : DriftPerVol : StimRect(3)-DriftPerVol] + (Rect(3)/2-StimRect(3)/2) + DriftPerVol/2;
    
    
    %% Initialize
    CircAperture = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
    if SaveAps
        ApFrm = zeros(100, 100, PARAMETERS.VolumesPerTrial * length(PARAMETERS.Conditions));
        SavWin = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
    end
    
    % Background variables
    CURRENT.Frame = 0;
    CURRENT.Stim = 1;
    
    % Behavioural
    BEHAVIOUR = struct;
    BEHAVIOUR.EventTime = [];
    BEHAVIOUR.Response = [];
    BEHAVIOUR.ResponseTime = [];
    
    % Various variables
    Results = [];
    CURRENT.Volume = 0;
    Slice_Duration = PARAMETERS.TR / PARAMETERS.NumberOfSlices;
    Start_of_Expmt = NaN;
    
    PrevKeypr = 0;
    
    HideCursor;
    Priority(MaxPriority(Win));
    
    
    %% Standby screen
    Screen('FillRect', Win, PARAMETERS.Background, Rect);
    DrawFormattedText(Win, ...
        [PARAMETERS.Welcome '\n \n' PARAMETERS.Instruction '\n \n' TrigStr], ...
        'center', 'center', PARAMETERS.Foreground);
    Screen('Flip', Win);
    
    if Emulate
        WaitSecs(0.1);
        KbWait;
        [bkp, StartExpmt, bk] = KbCheck;
    else
        %%% CHANGE THIS TO WHATEVER CODE YOU USE TO TRIGGER YOUR SCRIPT!!! %%%
        CURRENT.Slice = waitslice(Port, PARAMETERS.Dummies * PARAMETERS.Number_of_Slices + 1);
        Start_of_Expmt = GetSecs;
        bk = zeros(1,256);
    end
    
    % Abort if Escape was pressed
    if bk(KeyCodes.Escape)
        % Abort screen
        Screen('FillRect', Win, PARAMETERS.Background, Rect);
        DrawFormattedText(Win, 'Experiment was aborted!', 'center', 'center', PARAMETERS.Foreground);
        Screen('Flip', Win);
        
        CleanUp
        
        disp('Experiment aborted by user!');
        
        return
    end
    Screen('FillRect', Win, PARAMETERS.Background, Rect);
    Screen('Flip', Win);
    
    % BEHAVIOUR structure
    BEHAVIOUR.EventTime = Events;
    
    %% Run stimulus sequence
    for Trial = 1 : length(PARAMETERS.Conditions)
        % Determine next slice (depends on trigger)
        if Emulate  % Manual start
            CURRENT.SliceTime = GetSecs - Start_of_Expmt;
            CURRENT.Slice = ceil(CURRENT.SliceTime / Slice_Duration);
        else  % Triggered start
            % CURRENT.ent slice
            [CURRENT.Slice, CURRENT.SliceTime] = getslice(Port);
        end
        
        % CURRENT.ent volume
        CURRENT.Volume = ceil(CURRENT.Slice(end) / PARAMETERS.NumberSlices) - PARAMETERS.Dummies;
        
        % Begin trial
        TrialOutput = struct;
        TrialOutput.TrialOnset = GetSecs;
        TrialOutput.TrialOffset = NaN;
        
        %% Stimulation sequence
        CURRENT.Condit = PARAMETERS.Conditions(Trial);
        CURRENT.Volume = 1;
        
        while CURRENT.Volume <= PARAMETERS.VolumesPerTrial
            % Determine current frame
            CURRENT.Frame = CURRENT.Frame + 1;
            if CURRENT.Frame > PARAMETERS.RefreshPerStim
                CURRENT.Frame = 1;
                CURRENT.Stim = CURRENT.Stim + 1;
            end
            if CURRENT.Stim > size(PARAMETERS.Stimulus, length(size(PARAMETERS.Stimulus)))
                CURRENT.Stim = 1;
            end
            
            % Create Aperture
            Screen('FillRect', CircAperture, [127 127 127]);
            
            Screen('FillOval', CircAperture, [0 0 0 0], CenterRect([0 0 repmat(StimRect(3), 1, 2)], Rect));
            
            if mod(CURRENT.Condit, 90) ~= 0 && CURRENT.Volume > PARAMETERS.VolumesPerTrial/2
                Screen('FillRect', CircAperture, [127 127 127]);
            else
                Screen('FillRect', CircAperture, [127 127 127], [0 0 BarPos(CURRENT.Volume)-PARAMETERS.BarWidth/2 Rect(4)]);
                Screen('FillRect', CircAperture, [127 127 127], [BarPos(CURRENT.Volume)+PARAMETERS.BarWidth/2 0 Rect(3) Rect(4)]);
            end
            
            % Rotate background movie?
            BgdAngle = cos(GetSecs - TrialOutput.TrialOnset) * PARAMETERS.SineRotation;
            
            % Draw movie frame
            Screen('DrawTexture', Win, BgdTextures(CURRENT.Stim), StimRect, CenterRect(StimRect, Rect), BgdAngle+CURRENT.Condit-90);
            
            % Draw aperture (and save if desired)
            Screen('DrawTexture', Win, CircAperture, Rect, Rect, CURRENT.Condit-90);
            
            if SaveAps
                Screen('DrawTexture', SavWin, CircAperture, Rect, Rect, CURRENT.Condit-90);
                CurApImg = Screen('GetImage', SavWin, CenterRect(StimRect, Rect));
                CurApImg = ~CurApImg(:,:,1);
                ApFrm(:,:,PARAMETERS.Volumes_per_Trial*(Trial-1)+CURRENT.Volume) = imresize(CurApImg, [100 100]);
            end
            
            % Draw fixation cross
            CURRENT.Events = Events - (GetSecs - StartExpmt);
            
            Screen('FillOval', Win, PARAMETERS.Background, CenterRect([0 0 20 20], Rect));
            
            if sum(CURRENT.Events > 0 & CURRENT.Events < PARAMETERS.EventDuration)
                % This is an event
                Screen('FillOval', Win, [0 0 255], CenterRect([0 0 10 10], Rect));
            else
                % This is not an event
                Screen('FillOval', Win, [255 0 0], CenterRect([0 0 10 10], Rect));
            end
            
            
            % Flip screen
            Screen('Flip', Win);
            
            
            
            %% Behavioural response
            [BEHAVIOUR, PrevKeypr, QUIT] = GetBehResp(KeyCodes, Win, PARAMETERS, Rect, PrevKeypr, BEHAVIOUR, StartExpmt);
            
            if QUIT
                return
            end
            
            % Determine current volume
            CURRENT.Volume = floor((GetSecs - TrialOutput.TrialOnset) / PARAMETERS.TR) + 1;
        end
        
        % Trial end time
        TrialOutput.TrialOffset = GetSecs;
        
        % Record trial results
        Results = [Results; TrialOutput];
    end
    
    % Clock after experiment
    EndExpmt = GetSecs;
    
    %% Save results of current block
    PARAMETERS = rmfield(PARAMETERS, 'Stimulus');
    Screen('FillRect', Win, PARAMETERS.Background, Rect);
    DrawFormattedText(Win, 'Saving data...', 'center', 'center', PARAMETERS.Foreground);
    Screen('Flip', Win);
    save(['Results' filesep PARAMETERS.Session_name]);
    
    
    %% Farewell screen
    FarewellScreen(Win, PARAMETERS, Rect)
    
    CleanUp
    
    
    %% Save workspace
    BEHAVIOUR.EventTime = Events;
    
    %     BEHAVIOUR.TargetData = TargetData;
    
    % clear stim from structure and a few variables to save memory
    PARAMETERS = rmfield(PARAMETERS, 'Stimulus');
    PARAMETERS.Stimulus = [];
    clear('Apperture');
    
    if IsOctave
        save([PARAMETERS.OutputFilename '.mat'], '-mat7-binary');
    else
        save([PARAMETERS.OutputFilename '.mat'], '-v7.3');
    end
    
    
    %% Experiment duration
    DispExpDur(EndExpmt, StartExpmt)
    
    WaitSecs(1);
    
    if Emulate ~= 1
        IOPort('ConfigureSerialPort', MyPort, 'StopBackgroundRead');
        IOPort('Close', MyPort);
    end
    
    EyeTrackStop(ivx, PARAMETERS)
    
    
    %% Save apertures
    if SaveAps
        save('pRF_Apertures', 'ApFrm');
    end
    
    
catch
    CleanUp
    psychrethrow(psychlasterror);
end
