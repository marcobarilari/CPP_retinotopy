function DualPolEccMapping(Parameters, Emulate, Debug, SaveAps)
    % DualPolEcc_Mapping(Parameters, Emulate, SaveAps)
    %
    % Runs a dual polar & eccentricity mapping.
    % If SaveAps is true it saves the aperture mask for each volume (for pRF).
    %

    if nargin < 4
        SaveAps = false;
    end

    %% Fixed parameter to ensure things work
    CyclesPerExpmt = [6 10 4 5] * Parameters.Repetitions;  % Number of cycles for polar & eccentricity & their blanks
    VolumesPerCycle = [20 12 30 24];  % Duration of each cycle (polar, eccentricity, blanks) in volumes
    Wedges = repmat(1:VolumesPerCycle(1), 1, CyclesPerExpmt(1))';
    Rings = repmat(1:VolumesPerCycle(2), 1, CyclesPerExpmt(2))';
    % Whether blanks are included or not
    if Parameters.Blanks
        WedgeVisible = ~(repmat((1:VolumesPerCycle(3))', CyclesPerExpmt(3), 1) > VolumesPerCycle(1) / 2);
        RingVisible = ~(repmat((1:VolumesPerCycle(4))', CyclesPerExpmt(4), 1) > VolumesPerCycle(2) / 2 ...
            & repmat((1:VolumesPerCycle(4))', CyclesPerExpmt(4), 1) < VolumesPerCycle(4) - VolumesPerCycle(2) / 2 + 1);
    else
        WedgeVisible = ones(length(Wedges), 1);
        RingVisible = ones(length(Rings), 1);
    end
    % Direction of cycling
    if Parameters.Direction == '-'
        Wedges = flipud(Wedges);
        Rings = flipud(Rings);
    end

    % Default is without scanner!
    if nargin < 2
        Emulate = 1;
    end

    % % Create the mandatory folders if not already present
    % if ~exist([cd filesep 'Results'], 'dir')
    %     mkdir('Results');
    % end

    %% Initialize randomness & keycodes
    SetUpRand;

    Results = [];
    CurrVolume = 0;
    % Slice_Duration = Parameters.TR / Parameters.Number_of_Slices;
    StartExpmt = NaN;

    % Background variables
    CurrFrame = 0;
    CurrStim = 1;

    %% Behavioural data
    Behaviour = struct;
    Behaviour.EventTime = [];
    Behaviour.Response = [];
    Behaviour.ResponseTime = [];

    %% Event timings
    Events = CreateEventsTiming(Parameters);
    Behaviour.EventTime = Events;

    %% Configure scanner
    [TrigStr, Parameters] = ConfigScanner(Emulate, Parameters);

    try

        %% Initialize PTB
        if Debug
            PsychDebugWindowConfiguration;
        end

        KeyCodes = SetupKeyCodes;

        [Win, Rect, oldRes, ifi] = InitPTB(Parameters);

        %% Initialization
        % Load background movie
        StimRect = [0 0 repmat(size(Parameters.Stimulus, 1), 1, 2)];
        BgdTextures = LoadBckGrnd(Parameters, Win);

        % Advancement per volume
        AnglePerVol = 360 / VolumesPerCycle(1);  % Angle steps per volume
        PixelsPerVol = StimRect(3) / VolumesPerCycle(2);  % Steps in ring width per volume

        % Initialize circular Aperture
        CircAperture = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
        if SaveAps
            ApFrm = zeros(100, 100, length(Wedges));
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
            [~, ~, bk] = KbCheck;
        else
            %%% CHANGE THIS TO WHATEVER CODE YOU USE TO TRIGGER YOUR SCRIPT!!! %%%
            [MyPort] = WaitForScanTrigger(Parameters);
            bk = zeros(1, 256);
        end

        % Abort if Escape was pressed
        if bk(KeyCodes.Escape)
            % Abort screen
            Screen('FillRect', Win, Parameters.Background, Rect);
            DrawFormattedText(Win, 'Experiment was aborted!', 'center', 'center', Parameters.Foreground);
            Screen('Flip', Win);

            CleanUp;

            disp('Experiment aborted by user!');

            return
        end

        % Begin trial
        TrialOutput = struct;
        TrialOutput.TrialOnset = GetSecs;
        TrialOutput.TrialOffset = NaN;

        Screen('FillRect', Win, Parameters.Background, Rect);
        rft = Screen('Flip', Win);

        StartExpmt = rft;   % Time when cycling starts

        %% Stimulus movie
        CurrVolume = 1;
        while CurrVolume <= length(Wedges)

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
            CurrWidth = Rings(CurrVolume) * PixelsPerVol;

            if RingVisible(CurrVolume)
                Screen('FillOval', CircAperture, [0 0 0 0], CenterRect([0 0 repmat(CurrWidth, 1, 2)], Rect));
                Screen('FillOval', CircAperture, [Parameters.Background 255], CenterRect([0 0 repmat(CurrWidth - PixelsPerVol + 1, 1, 2)], Rect));
            end

            CurrAngle = Wedges(CurrVolume) * AnglePerVol - AnglePerVol * 1.5 + 90;

            if WedgeVisible(CurrVolume)
                Screen('FillArc', CircAperture, [0 0 0 0], CenterRect([0 0 repmat(StimRect(4), 1, 2)], Rect), CurrAngle, AnglePerVol);
            end
            % Rotate background movie?
            BgdAngle = cos(GetSecs - TrialOutput.TrialOnset) * Parameters.Sine_Rotation;

            % Draw movie frame
            Screen('DrawTexture', Win, BgdTextures(CurrStim), StimRect, CenterRect(StimRect, Rect), BgdAngle + CurrAngle);

            % Draw aperture
            Screen('DrawTexture', Win, CircAperture, Rect, Rect);
            if SaveAps
                Screen('DrawTexture', SavWin, CircAperture, Rect, Rect);
                CurApImg = Screen('GetImage', SavWin, CenterRect(StimRect, Rect));
                CurApImg = ~CurApImg(:, :, 1);
                ApFrm(:, :, CurrVolume) = imresize(CurApImg, [100 100]);
            end

            % Draw fixation cross
            CurrEvents = Events - (GetSecs - StartExpmt);
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
                DrawFormattedText(Win, 'Experiment was aborted mid-experiment!', 'center', 'center', Parameters.Foreground);

                CleanUp;

                disp('Experiment aborted by user mid-experiment!');

                % Experiment duration
                EndExpmt = GetSecs;

                DispExpDur(EndExpmt, StartExpmt);

                return
            end

            % Determine current volume
            CurrVolume = floor((GetSecs - StartExpmt) / Parameters.TR) + 3;
        end

        % Trial end time
        TrialOutput.TrialOffset = GetSecs;

        % Record trial results
        Results = [Results; TrialOutput];

        % Clock after experiment
        EndExpmt = GetSecs;

        %% Save results
        Parameters = rmfield(Parameters, 'Stimulus');  % Remove stimulus from data
        Screen('FillRect', Win, Parameters.Background, Rect);
        DrawFormattedText(Win, 'Saving data...', 'center', 'center', Parameters.Foreground);
        Screen('Flip', Win);
        save(['Results' filesep Parameters.Session_name]);

        %% Farewell screen
        FarewellScreen(Win, Parameters, Rect);

        CleanUp;

        %% Experiment duration
        DispExpDur(EndExpmt, StartExpmt);

        %% Save apertures
        if SaveAps
            save('Dual_Apertures', 'ApFrm');
        end

    catch
        CleanUp;
        psychrethrow(psychlasterror);
    end
