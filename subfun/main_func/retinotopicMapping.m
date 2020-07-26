function [data, expParameters] = retinotopicMapping(cfg, expParameters)
    % retinotopicMapping(cfg, expParameters)
    %
    % Cyclic presentation with a rotating and/or expanding aperture.
    % Behind the aperture a background is displayed as a movie.

    % current: structure to keep track of which frame, refreshcycle, time, angle...
    % ring: structure to keep of several information about the annulus size

    expParameters = userInputs(cfg, expParameters);
    [cfg, expParameters] = createFilename(cfg, expParameters);

    % Prepare for the output logfiles with all
    logFile.extraColumns = expParameters.extraColumns;
    logFile = saveEventsFile('open', expParameters, logFile);

    disp(expParameters);
    disp(cfg);

    %% Initialize
    data = [];
    frameTimes = [];  % To collect info about the frames

    % current stimulus Frame
    current.frame = 1;
    % current video Refresh
    current.refresh = 0;
    % current Angle of wedge
    current.angle = 0;
    current.time = 0;

    % current inner radius of ring
    ring.ringWidthVA = expParameters.aperture.width;

    target.wasTarget = false;
    target.trial_type = 'target';
    target.fileID = logFile.fileID;
    target.extraColumns = logFile.extraColumns;
    target.target_width = expParameters.target.size;

    cycleDuration = expParameters.bids.MRI.RepetitionTime * expParameters.volsPerCycle;
    cyclingEnd = cycleDuration * expParameters.cyclesPerExpmt;

    switch expParameters.aperture.type
        case 'Ring'
            isRing = true;
        otherwise
            isRing = false;
    end

    %% Set up

    % TODO
    % Randomness
    %     setUpRand;

    % targetsTimings is a vector that says when (in seconds from the start of the
    % experiment) a target should be presented.
    targetsTimings = createTargetsTiming(expParameters);

    %% Start
    try

        %% Initialize PTB
        [cfg] = initPTB(cfg);

        % TODO
        %         if ismac && noScreens > 1 % only if projector is also a screen
        %             oldRes = Screen('Resolution', screenid, ...
        %                 PARAMETERS.Resolution(1), PARAMETERS.Resolution(2), ...
        %                   PARAMETERS.Resolution(3));
        %         end

        % apply pixels per degree conversion
        target = degToPix('target_width', target, cfg);
        expParameters = degToPix('fixationSize', expParameters, cfg);

        % Load background movie
        expParameters = loadStim(expParameters);
        stimRect = [0 0 size(expParameters.stimulus, 2) size(expParameters.stimulus, 1)];
        bgdTextures = loadBckGrnd(expParameters.stimulus, cfg.win);

        % Set parameters for rings
        if isRing
            % currentScale is scale of outer ring (exceeding screen until
            % inner ring reaches window boarder)
            ring.maxEcc = ...
                cfg.FOV / 2 + ...
                expParameters.aperture.width + ...
                log(cfg.FOV / 2 + 1) ;
            % ring.CsFuncFact is used to expand with log increasing speed so
            % that ring is at ring.maxEcc at end of cycle
            ring.csFuncFact = ...
                1 / ...
                ((ring.maxEcc + exp(1)) * log(ring.maxEcc + exp(1)) - (ring.maxEcc + exp(1))) ;
        end

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

        %% Loop until the end of last cycle
        while current.time < cyclingEnd

            checkAbort(cfg);

            %% Update Frame number
            current.refresh = current.refresh + 1;
            if current.refresh == expParameters.refreshPerStim

                current.refresh = 0;
                current.frame = current.frame + 1;

                if current.frame > size(expParameters.stimulus, ndims(expParameters.stimulus))
                    current.frame = 1;
                end

            end

            % current Time stamp
            current.time = GetSecs - cfg.experimentStart;

            %% Create apperture texture
            Screen('Fillrect', apertTexture, cfg.backgroundColor);

            frameTimesUpdate = [current.time];

            if isRing

                % expansion speed is log over eccentricity
                [ring] = eccenLogSpeed(expParameters, cfg.ppd, ring, current.time);

                Screen('FillOval', apertTexture, [0 0 0 0], ...
                    CenterRectOnPoint( ...
                    [0 0 repmat(ring.outerRimPix, 1, 2)], ...
                    cfg.winRect(3) / 2, cfg.winRect(4) / 2));

                Screen('FillOval', apertTexture, [cfg.backgroundColor 255], ...
                    CenterRectOnPoint( ...
                    [0 0 repmat(ring.innerRimPix, 1, 2)], ...
                    cfg.winRect(3) / 2, cfg.winRect(4) / 2));

                %                 frameTimesUpdate = [frameTimesUpdate, ...
                %                     ring.scalePix ring.scaleVA2 ring.scaleInnerPix ring.scaleInnerVA];

            else

                % Update angle for rotation of background and for apperture for wedge
                switch expParameters.direction

                    case '+'
                        current.angle = 90 - ...
                            expParameters.aperture.width / 2 + ...
                            (current.time / cycleDuration) * 360;
                    case '-'
                        current.angle = 90 - ...
                            expParameters.aperture.width / 2 - ...
                            (current.time / cycleDuration) * 360;

                end

                Screen('FillArc', apertTexture, [0 0 0 0], ...
                    CenterRect([0 0 repmat(stimRect(4), 1, 2)], cfg.winRect), ...
                    current.angle, expParameters.aperture.width);

                %                 frameTimesUpdate = [frameTimesUpdate, current.angle];

            end

            % current Frame, time & condition (can also be valuable for debugging)
            frameTimes = [frameTimes; frameTimesUpdate]; %#ok<AGROW>

            %% Draw stimulus
            % we draw the background stimulus in full and overlay an aperture on top of it

            % Display background
            if expParameters.rotateStimulus
                bgdAngle = current.angle;
            else
                bgdAngle = 0;
            end

            % Rotate background movie
            sineRotate = cos(current.time) * expParameters.sineRotation;

            Screen('DrawTexture', cfg.win, bgdTextures(current.frame), stimRect, ...
                CenterRect(stimRect, cfg.winRect), bgdAngle + sineRotate);

            % Draw aperture
            Screen('DrawTexture', cfg.win, apertTexture);

            drawFixation(cfg, expParameters);

            %% Draw target
            [target] = drawTarget(target, targetsTimings, current, ring, cfg, expParameters);

            %% Flip current frame
            rft = Screen('Flip', cfg.win, rft + cfg.ifi);

            %% Collect and save target info
            if target.isOnset
                target.onset = rft - cfg.experimentStart;
            elseif target.isOffset
                target.duration = (rft - cfg.experimentStart) - target.onset;
                saveEventsFile('save', expParameters, target);
            end

            collectAndSaveResponses(cfg, expParameters, logFile, cfg.experimentStart);

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
