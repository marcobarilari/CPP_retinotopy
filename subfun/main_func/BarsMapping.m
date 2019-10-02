function BarsMapping(Parameters, Emulate, Debug, SaveAps)
%Bars_Mapping(Parameters, Emulate, SaveAps)
%
% Runs the drifting bar protocol for mapping population receptive fields.
% If SaveAps is true it saves the aperture mask for each volume (for pRF).
%

if nargin < 4
    SaveAps = false;
end

% % Create the mandatory folders if not already present
% if ~exist([cd filesep 'Results'], 'dir')
%     mkdir('Results');
% end

%% Initialize
SetUpRand

% Background variables
CurrFrame = 0;
CurrStim = 1;

% Behavioural
Behaviour = struct;
Behaviour.EventTime = [];
Behaviour.Response = [];
Behaviour.ResponseTime = [];

% Various variables
Results = [];
CurrVolume = 0;
Slice_Duration = Parameters.TR / Parameters.NumberOfSlices;
Start_of_Expmt = NaN;


%% Event timings
Events = CreateEventsTiming(Parameters);


%% Configure scanner
[TrigStr, Parameters] = ConfigScanner(Emulate, Parameters);


try
    
    %% Initialize PTB
    if Debug
        PsychDebugWindowConfiguration
    end
    
    KeyCodes = SetupKeyCodes;
    
    [Win, Rect, oldRes, ifi] = InitPTB(Parameters);
    
    
    %% Load background movie
    StimRect = [0 0 repmat(size(Parameters.Stimulus,1), 1, 2)];
    DriftPerVol = StimRect(3) / Parameters.VolumesPerTrial;
    BarPos = [0 : DriftPerVol : StimRect(3)-DriftPerVol] + (Rect(3)/2-StimRect(3)/2) + DriftPerVol/2;
    BgdTextures = LoadBckGrnd(Parameters, Win);
    
    
    
    %% Initialize circular Aperture
    CircAperture = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
    if SaveAps
        ApFrm = zeros(100, 100, Parameters.VolumesPerTrial * length(Parameters.Conditions));
        SavWin = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
    end
    
    HideCursor;
    Priority(MaxPriority(Win));
    
    %% Standby screen
    Screen('FillRect', Win, Parameters.Background, Rect);
    DrawFormattedText(Win, ...
        [Parameters.Welcome '\n \n' Parameters.Instruction '\n \n' TrigStr], ...
        'center', 'center', Parameters.Foreground);
    Screen('Flip', Win);
    
    if Emulate
        WaitSecs(0.1);
        KbWait;
        [bkp, StartExpmt, bk] = KbCheck;
    else
        %%% CHANGE THIS TO WHATEVER CODE YOU USE TO TRIGGER YOUR SCRIPT!!! %%%
        CurrSlice = waitslice(Port, Parameters.Dummies * Parameters.Number_of_Slices + 1);
        Start_of_Expmt = GetSecs;
        bk = zeros(1,256);
    end
    
    % Abort if Escape was pressed
    if bk(KeyCodes.Escape)
        % Abort screen
        Screen('FillRect', Win, Parameters.Background, Rect);
        DrawFormattedText(Win, 'Experiment was aborted!', 'center', 'center', Parameters.Foreground);
        Screen('Flip', Win);
        
        CleanUp
        
        disp('Experiment aborted by user!');
        
        return
    end
    Screen('FillRect', Win, Parameters.Background, Rect);
    Screen('Flip', Win);
    
    % Behaviour structure
    Behaviour.EventTime = Events;
    
    %% Run stimulus sequence
    for Trial = 1 : length(Parameters.Conditions)
        % Determine next slice (depends on trigger)
        if Emulate  % Manual start
            CurrSliceTime = GetSecs - Start_of_Expmt;
            CurrSlice = ceil(CurrSliceTime / Slice_Duration);
        else  % Triggered start
            % Current slice
            [CurrSlice, CurrSliceTime] = getslice(Port);
        end
        
        % Current volume
        CurrVolume = ceil(CurrSlice(end) / Parameters.NumberSlices) - Parameters.Dummies;
        
        % Begin trial
        TrialOutput = struct;
        TrialOutput.TrialOnset = GetSecs;
        TrialOutput.TrialOffset = NaN;
        
        %% Stimulation sequence
        CurrCondit = Parameters.Conditions(Trial);
        CurrVolume = 1;
        
        while CurrVolume <= Parameters.VolumesPerTrial
            % Determine current frame
            CurrFrame = CurrFrame + 1;
            if CurrFrame > Parameters.RefreshPerStim
                CurrFrame = 1;
                CurrStim = CurrStim + 1;
            end
            if CurrStim > size(Parameters.Stimulus, length(size(Parameters.Stimulus)))
                CurrStim = 1;
            end
            
            % Create Aperture
            Screen('FillRect', CircAperture, [127 127 127]);
            
            Screen('FillOval', CircAperture, [0 0 0 0], CenterRect([0 0 repmat(StimRect(3), 1, 2)], Rect));
            
            if mod(CurrCondit, 90) ~= 0 && CurrVolume > Parameters.VolumesPerTrial/2
                Screen('FillRect', CircAperture, [127 127 127]);
            else
                Screen('FillRect', CircAperture, [127 127 127], [0 0 BarPos(CurrVolume)-Parameters.BarWidth/2 Rect(4)]);
                Screen('FillRect', CircAperture, [127 127 127], [BarPos(CurrVolume)+Parameters.BarWidth/2 0 Rect(3) Rect(4)]);
            end
            
            % Rotate background movie?
            BgdAngle = cos(GetSecs - TrialOutput.TrialOnset) * Parameters.SineRotation;
            
            % Draw movie frame
            Screen('DrawTexture', Win, BgdTextures(CurrStim), StimRect, CenterRect(StimRect, Rect), BgdAngle+CurrCondit-90);
            
            % Draw aperture (and save if desired)
            Screen('DrawTexture', Win, CircAperture, Rect, Rect, CurrCondit-90);
            
            if SaveAps
                Screen('DrawTexture', SavWin, CircAperture, Rect, Rect, CurrCondit-90);
                CurApImg = Screen('GetImage', SavWin, CenterRect(StimRect, Rect));
                CurApImg = ~CurApImg(:,:,1);
                ApFrm(:,:,Parameters.Volumes_per_Trial*(Trial-1)+CurrVolume) = imresize(CurApImg, [100 100]);
            end
            
            % Draw fixation cross
            CurrEvents = Events - (GetSecs - StartExpmt);
            
            Screen('FillOval', Win, Parameters.Background, CenterRect([0 0 20 20], Rect));
            
            if sum(CurrEvents > 0 & CurrEvents < Parameters.EventDuration)
                % This is an event
                Screen('FillOval', Win, [0 0 255], CenterRect([0 0 10 10], Rect));
            else
                % This is not an event
                Screen('FillOval', Win, [255 0 0], CenterRect([0 0 10 10], Rect));
            end
            
            % Flip screen
            Screen('Flip', Win);
            
            % Behavioural response
            [Keypr, KeyTime, Key] = KbCheck;
            
            if Keypr
                Behaviour.Response = [Behaviour.Response; find(Key)];
                Behaviour.ResponseTime = [Behaviour.ResponseTime; KeyTime - StartExpmt];
            end
            
            TrialOutput.Key = Key;
            
            % Abort if Escape was pressed
            if find(TrialOutput.Key) == KeyCodes.Escape
                % Abort screen
                Screen('FillRect', Win, Parameters.Background, Rect);
                DrawFormattedText(Win, 'Experiment was aborted mid-block!', 'center', 'center', Parameters.Foreground);
                
                CleanUp
                
                disp('Experiment aborted by user mid-block!');
                
                return
            end
            
            % Determine current volume
            CurrVolume = floor((GetSecs - TrialOutput.TrialOnset) / Parameters.TR) + 1;
        end
        
        % Trial end time
        TrialOutput.TrialOffset = GetSecs;
        
        % Record trial results
        Results = [Results; TrialOutput];
    end
    
    % Clock after experiment
    EndExpmt = GetSecs;
    
    %% Save results of current block
    Parameters = rmfield(Parameters, 'Stimulus');
    Screen('FillRect', Win, Parameters.Background, Rect);
    DrawFormattedText(Win, 'Saving data...', 'center', 'center', Parameters.Foreground);
    Screen('Flip', Win);
    save(['Results' filesep Parameters.Session_name]);
    
    
    %% Farewell screen
    FarewellScreen(Win, Parameters, Rect)
    
    CleanUp
    
    %% Experiment duration
    DispExpDur(EndExpmt, StartExpmt)
    
    %% Save apertures
    if SaveAps
        save('pRF_Apertures', 'ApFrm');
    end
    
catch
    CleanUp
    psychrethrow(psychlasterror);
end
