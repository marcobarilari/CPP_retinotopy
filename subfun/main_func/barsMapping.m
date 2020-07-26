function barsMapping(cfg, expParameters)
    % barsMapping(cfg, expParameters)
    %
    % Runs the drifting bar protocol for mapping population receptive fields.
    % If SaveAps is true it saves the aperture mask for each volume (for pRF).

    expParameters = userInputs(cfg, expParameters);
    [cfg, expParameters] = createFilename(cfg, expParameters);

    % Prepare for the output logfiles with all
    logFile.extraColumns = expParameters.extraColumns;
    logFile = saveEventsFile('open', expParameters, logFile);

    disp(expParameters);
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
    target.target_width = expParameters.target.size;

    frameTimes = [];

    %% Set up

    % TODO
    % Randomness
    %     setUpRand;

    % targetsTimings is a vector that says when (in seconds from the start of the
    % experiment) a target should be presented.
    expParameters.cyclesPerExpmt = length(expParameters.conditions);
    targetsTimings = createTargetsTiming(expParameters);

    try

        %% Initialize PTB

        [cfg] = initPTB(cfg);

        % apply pixels per degree conversion
        target = degToPix('target_width', target, cfg);
        expParameters = degToPix('fixationSize', expParameters, cfg);

        % Load background movie
        expParameters = loadStim(expParameters);
        stimRect = [0 0 repmat(size(expParameters.stimulus, 1), 1, 2)];
        bgdTextures = loadBckGrnd(expParameters.stimulus, cfg.win);

        % Set parameters drifting bars
        barWidth = stimRect(3) / expParameters.volsPerCycle;
        barPos = [0:barWidth:stimRect(3) - barWidth] + ...
            (cfg.winRect(3) / 2 - stimRect(3) / 2) + ...
            barWidth / 2;

        % Width of bar in degrees of VA (needed for saving)
        expParameters.aperture.width = barWidth / cfg.ppd;
        expParameters.barPos = (barPos - cfg.winRect(3) / 2) / cfg.ppd; % in VA

        % Create aperture texture
        apertTexture = Screen('MakeTexture', cfg.win, 127 * ones(cfg.winRect([4 3])));

        % prepare the KbQueue to collect responses
        getResponse('init', cfg.keyboard.responseBox, cfg);

        [el] = eyeTracker('Calibration', cfg, expParameters); %#ok<*NASGU>

        standByScreen(cfg, expParameters);

        %% Wait for start of experiment
        waitForTrigger(cfg);

        eyeTracker('StartRecording', cfg, expParameters);
        getResponse('start', cfg.keyboard.responseBox);

        %% Start cycling the stimulus
        rft = Screen('Flip', cfg.win);
        cfg.experimentStart = rft;

        %% Run stimulus sequence
        for iTrial = 1:length(expParameters.conditions)

            % Begin trial
            trialOnset = GetSecs - cfg.experimentStart;

            % Stimulation sequence
            current.condition = expParameters.conditions(iTrial);

            current.volume = 1;
            previousVolume = 0;
            current.stim = 1;

            while current.volume <= expParameters.volsPerCycle

                checkAbort(cfg);
                
                current.time = GetSecs - cfg.experimentStart;

                %% Determine current frame

                current.frame = current.frame + 1;

                current.barPos = barPos(current.volume);

                if current.frame > expParameters.refreshPerStim
                    current.frame = 1;
                    current.stim = current.stim + 1;
                end

                if current.stim > size(expParameters.stimulus, ...
                        length(size(expParameters.stimulus)))
                    current.stim = 1;
                end

                %% Create Aperture
                % aperture is the color of the background
                Screen('FillRect', apertTexture, cfg.backgroundColor);

                % We let the stimulus through
                Screen('FillOval', apertTexture, [0 0 0 0], ...
                    CenterRect([0 0 repmat(stimRect(3), 1, 2)], cfg.winRect));

                % Then we add the position of the bar aperture
                Screen('FillRect', apertTexture, cfg.backgroundColor, ...
                    [0 0 current.barPos - barWidth / 2 cfg.winRect(4)]);

                Screen('FillRect', apertTexture, cfg.backgroundColor, ...
                    [current.barPos + barWidth / 2 0 cfg.winRect(3) cfg.winRect(4)]);

                %% Draw stimulus
                % we draw the background stimulus in full and overlay an aperture
                % on top of it

                % Rotate background movie
                bgdAngle = cos(GetSecs - trialOnset) * expParameters.sineRotation;

                % Draw movie frame
                Screen('DrawTexture', cfg.win, bgdTextures(current.stim), stimRect, ...
                    CenterRect(stimRect, cfg.winRect), bgdAngle + current.condition - 90);

                % Draw aperture and we rotate to match the required condition
                Screen('DrawTexture', cfg.win, apertTexture, cfg.winRect, ...
                    cfg.winRect, current.condition - 90);

                drawFixation(cfg, expParameters);

                %% Draw target
                [target] = drawTarget(target, targetsTimings, current, ring, cfg, ...
                    expParameters);

                %% Flip current frame
                rft = Screen('Flip', cfg.win, rft + cfg.ifi);

                %% Collect and save target info
                if target.isOnset
                    target.onset = rft - cfg.experimentStart;
                elseif target.isOffset
                    target.duration = (rft - cfg.experimentStart) - target.onset;
                    saveEventsFile('save', expParameters, target);
                end

                frameTimesUpdate = [current.time current.frame ...
                    current.condition expParameters.barPos(current.volume)];

                % CURRENT Frame, time & condition (can also be valuable for debugging)
                frameTimes = [frameTimes; frameTimesUpdate]; %#ok<AGROW>

                collectAndSaveResponses(cfg, expParameters, logFile, cfg.experimentStart);

                %% Determine current volume
                previousVolume = current.volume;
                current.volume = floor((current.time - trialOnset) / ...
                    expParameters.bids.MRI.RepetitionTime) + 1;

            end

        end

        %% End the experiment
        drawFixation(cfg, expParameters);
        endExpmt = Screen('Flip', cfg.win);

        dispExpDur(endExpmt, cfg.experimentStart);

        getResponse('stop', cfg.keyboard.responseBox);
        getResponse('release', cfg.keyboard.responseBox);

        saveEventsFile('close', expParameters, logFile);

        eyeTracker('StopRecordings', cfg, expParameters);
        eyeTracker('Shutdown', cfg, expParameters);

        %       data = feedbackScreen(cfg, expParameters);

        WaitSecs(1);

        %% Save
        % TODO
        %         data = save2TSV(frameTimes, behavior, expParameters);

        % clear stim from structure and a few variables to save memory
        expParameters = rmfield(expParameters, 'stimulus');

        matFile = fullfile( ...
            expParameters.outputDir, ...
            strrep(expParameters.fileName.events, 'tsv', 'mat'));
        if IsOctave
            save(matFile, '-mat7-binary');
        else
            save(matFile, '-v7.3');
        end

        output = bids.util.tsvread( ...
            fullfile(expParameters.subjectOutputDir, expParameters.modality, ...
            expParameters.fileName.events));

        disp(output);

        WaitSecs(4);

        %% Farewell screen
        farewellScreen(cfg, expParameters);

        cleanUp;

    catch
        cleanUp;
        psychrethrow(psychlasterror);
    end

end
