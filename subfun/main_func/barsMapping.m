function barsMapping(cfg)
    % barsMapping(cfg, expParameters)
    %
    % Runs the drifting bar protocol for mapping population receptive fields.
    % If SaveAps is true it saves the aperture mask for each volume (for pRF).

    cfg = userInputs(cfg);
    cfg = createFilename(cfg);

    % Prepare for the output logfiles with all
    logFile.extraColumns = cfg.extraColumns;
    logFile = saveEventsFile('open', cfg, logFile);

    disp(cfg);

    %% Initialize

    % current stimulus Frame
    current.frame = 1;
    current.time = 0;
    current.volume = 0;
    current.barPos = [];

    ring = [];

    target.wasTarget = false;
    target.trial_type = 'target';
    target.fileID = logFile.fileID;
    target.extraColumns = logFile.extraColumns;
    target.target_width = cfg.target.size;

    frameTimes = [];

    %% Set up

    % TODO
    % Randomness
    %     setUpRand;

    % targetsTimings is a vector that says when (in seconds from the start of the
    % experiment) a target should be presented.
    cfg.cyclesPerExpmt = length(cfg.conditions);
    targetsTimings = createTargetsTiming(cfg);

    try

        %% Initialize PTB

        [cfg] = initPTB(cfg);

        % apply pixels per degree conversion
        target = degToPix('target_width', target, cfg);
        cfg.fixation = degToPix('size', cfg.fixation, cfg);

        % Load background movie
        cfg = loadStim(cfg);
        stimRect = [0 0 repmat(size(cfg.stimulus, 1), 1, 2)];
        bgdTextures = loadBckGrnd(cfg.stimulus, cfg.screen.win);

        % Set parameters drifting bars
        barWidth = stimRect(3) / cfg.volsPerCycle;
        barPos = [0:barWidth:stimRect(3) - barWidth] + ...
            (cfg.screen.winRect(3) / 2 - stimRect(3) / 2) + ...
            barWidth / 2;

        % Width of bar in degrees of VA (needed for saving)
        cfg.aperture.width = barWidth / cfg.screen.ppd;
        cfg.barPos = (barPos - cfg.screen.winRect(3) / 2) / cfg.screen.ppd; % in VA

        % Create aperture texture
        apertTexture = Screen('MakeTexture', cfg.screen.win, 127 * ones(cfg.screen.winRect([4 3])));

        % prepare the KbQueue to collect responses
        getResponse('init', cfg.keyboard.responseBox, cfg);

        [el] = eyeTracker('Calibration', cfg); %#ok<*NASGU>

        standByScreen(cfg);

        %% Wait for start of experiment
        waitForTrigger(cfg);

        eyeTracker('StartRecording', cfg);
        getResponse('start', cfg.keyboard.responseBox);

        %% Start cycling the stimulus
        rft = Screen('Flip', cfg.screen.win);
        cfg.experimentStart = rft;

        %% Run stimulus sequence
        for iTrial = 1:length(cfg.conditions)

            % Begin trial
            trialOnset = GetSecs - cfg.experimentStart;

            % Stimulation sequence
            current.condition = cfg.conditions(iTrial);

            current.volume = 1;
            previousVolume = 0;
            current.stim = 1;

            while current.volume <= cfg.volsPerCycle

                checkAbort(cfg);
                
                current.time = GetSecs - cfg.experimentStart;

                %% Determine current frame

                current.frame = current.frame + 1;

                current.barPos = barPos(current.volume);

                if current.frame > cfg.refreshPerStim
                    current.frame = 1;
                    current.stim = current.stim + 1;
                end

                if current.stim > size(cfg.stimulus, ...
                        length(size(cfg.stimulus)))
                    current.stim = 1;
                end

                %% Create Aperture
                % aperture is the color of the background
                Screen('FillRect', apertTexture, cfg.color.background);

                % We let the stimulus through
                Screen('FillOval', apertTexture, [0 0 0 0], ...
                    CenterRect([0 0 repmat(stimRect(3), 1, 2)], cfg.screen.winRect));

                % Then we add the position of the bar aperture
                Screen('FillRect', apertTexture, cfg.color.background, ...
                    [0 0 current.barPos - barWidth / 2 cfg.screen.winRect(4)]);

                Screen('FillRect', apertTexture, cfg.color.background, ...
                    [current.barPos + barWidth / 2 0 cfg.screen.winRect(3) cfg.screen.winRect(4)]);

                %% Draw stimulus
                % we draw the background stimulus in full and overlay an aperture
                % on top of it

                % Rotate background movie
                bgdAngle = cos(GetSecs - trialOnset) * cfg.sineRotation;

                % Draw movie frame
                Screen('DrawTexture', cfg.screen.win, bgdTextures(current.stim), stimRect, ...
                    CenterRect(stimRect, cfg.screen.winRect), bgdAngle + current.condition - 90);

                % Draw aperture and we rotate to match the required condition
                Screen('DrawTexture', cfg.screen.win, apertTexture, cfg.screen.winRect, ...
                    cfg.screen.winRect, current.condition - 90);

                drawFixation(cfg);

                %% Draw target
                [target] = drawTarget(target, targetsTimings, current, ring, cfg);

                %% Flip current frame
                rft = Screen('Flip', cfg.screen.win, rft + cfg.screen.ifi);

                %% Collect and save target info
                if target.isOnset
                    target.onset = rft - cfg.experimentStart;
                elseif target.isOffset
                    target.duration = (rft - cfg.experimentStart) - target.onset;
                    saveEventsFile('save', cfg, target);
                end

                frameTimesUpdate = [current.time current.frame ...
                    current.condition cfg.barPos(current.volume)];

                % CURRENT Frame, time & condition (can also be valuable for debugging)
                frameTimes = [frameTimes; frameTimesUpdate]; %#ok<AGROW>

                collectAndSaveResponses(cfg, logFile, cfg.experimentStart);

                %% Determine current volume
                previousVolume = current.volume;
                current.volume = floor((current.time - trialOnset) / ...
                    cfg.mri.repetitionTime) + 1;

            end

        end

        %% End the experiment
        drawFixation(cfg);
        endExpmt = Screen('Flip', cfg.screen.win);

        dispExpDur(endExpmt, cfg.experimentStart);

        getResponse('stop', cfg.keyboard.responseBox);
        getResponse('release', cfg.keyboard.responseBox);

        saveEventsFile('close', cfg, logFile);

        eyeTracker('StopRecordings', cfg);
        eyeTracker('Shutdown', cfg);

        %       data = feedbackScreen(cfg);

        WaitSecs(1);

        %% Save
        % TODO
        %         data = save2TSV(frameTimes, behavior, expParameters);

        % clear stim from structure and a few variables to save memory
        cfg = rmfield(cfg, 'stimulus');

        matFile = fullfile( ...
            cfg.dir.output, ...
            strrep(cfg.fileName.events, 'tsv', 'mat'));
        if IsOctave
            save(matFile, '-mat7-binary');
        else
            save(matFile, '-v7.3');
        end

        output = bids.util.tsvread( ...
            fullfile(cfg.dir.outputSubject, cfg.fileName.modality, ...
            cfg.fileName.events));

        disp(output);

        WaitSecs(4);

        %% Farewell screen
        farewellScreen(cfg);

        cleanUp;

    catch
        cleanUp;
        psychrethrow(psychlasterror);
    end

end
