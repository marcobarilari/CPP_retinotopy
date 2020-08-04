function [data, cfg] = retinotopicMapping(cfg)
    % retinotopicMapping(cfg, expParameters)
    %
    % Cyclic presentation with a rotating and/or expanding aperture.
    % Behind the aperture a background is displayed as a movie.

    % current: structure to keep track of which frame, refreshcycle, time, angle...
    % ring: structure to keep of several information about the annulus size

    cfg = userInputs(cfg);
    [cfg] = createFilename(cfg);

    % Prepare for the output logfiles with all
    logFile.extraColumns = cfg.extraColumns;
    logFile = saveEventsFile('open', cfg, logFile);

    disp(cfg);

    %% Initialize
    data = [];
    frameTimes = [];  % To collect info about the frames

    % current stimulus Frame
    thisEvent.frame = 1;
    % current video Refresh
    thisEvent.refresh = 0;
    % current Angle of wedge
    thisEvent.angle = 0;
    thisEvent.time = 0;

    % current inner radius of ring
    ring.ringWidthVA = cfg.aperture.width;

    target.wasTarget = false;
    target.trial_type = 'target';
    target.fileID = logFile.fileID;
    target.extraColumns = logFile.extraColumns;
    target.target_width = cfg.target.size;

    cycleDuration = cfg.mri.repetitionTime * cfg.volsPerCycle;
    cyclingEnd = cycleDuration * cfg.cyclesPerExpmt;

    switch cfg.aperture.type
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
    targetsTimings = createTargetsTiming(cfg);

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
        cfg.fixation = degToPix('size', cfg.fixation, cfg);

        % Load background movie
        cfg = loadStim(cfg);
        stimRect = [0 0 size(cfg.stimulus, 2) size(cfg.stimulus, 1)];
        bgdTextures = loadBckGrnd(cfg.stimulus, cfg.screen.win);

        % Set parameters for rings
        if isRing
            % currentScale is scale of outer ring (exceeding screen until
            % inner ring reaches window boarder)
            ring.maxEcc = ...
                cfg.screen.FOV / 2 + ...
                cfg.aperture.width + ...
                log(cfg.screen.FOV / 2 + 1) ;
            % ring.CsFuncFact is used to expand with log increasing speed so
            % that ring is at ring.maxEcc at end of cycle
            ring.csFuncFact = ...
                1 / ...
                ((ring.maxEcc + exp(1)) * log(ring.maxEcc + exp(1)) - (ring.maxEcc + exp(1))) ;
        end

        % Create aperture texture
        cfg = apertureTexture('init', cfg);

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

        %% Loop until the end of last cycle
        while thisEvent.time < cyclingEnd

            checkAbort(cfg);

            %% Update Frame number
            thisEvent.refresh = thisEvent.refresh + 1;
            if thisEvent.refresh == cfg.refreshPerStim

                thisEvent.refresh = 0;
                thisEvent.frame = thisEvent.frame + 1;

                if thisEvent.frame > size(cfg.stimulus, ndims(cfg.stimulus))
                    thisEvent.frame = 1;
                end

            end

            % current Time stamp
            thisEvent.time = GetSecs - cfg.experimentStart;

            %% Create apperture texture

            frameTimesUpdate = [thisEvent.time];

            if isRing

                % expansion speed is log over eccentricity
                [ring] = eccenLogSpeed(cfg, cfg.screen.ppd, ring, thisEvent.time);

                Screen('FillOval', cfg.aperture.texture, [0 0 0 0], ...
                    CenterRectOnPoint( ...
                    [0 0 repmat(ring.outerRimPix, 1, 2)], ...
                    cfg.screen.winRect(3) / 2, cfg.screen.winRect(4) / 2));

                Screen('FillOval', cfg.aperture.texture, [cfg.color.background 255], ...
                    CenterRectOnPoint( ...
                    [0 0 repmat(ring.innerRimPix, 1, 2)], ...
                    cfg.screen.winRect(3) / 2, cfg.screen.winRect(4) / 2));

                % frameTimesUpdate = [frameTimesUpdate, ...
                %  ring.scalePix ring.scaleVA2 ring.scaleInnerPix ring.scaleInnerVA];

            else

                % Update angle for rotation of background and for apperture for wedge
                switch cfg.direction

                    case '+'
                        thisEvent.angle = 90 - ...
                            cfg.aperture.width / 2 + ...
                            (thisEvent.time / cycleDuration) * 360;
                    case '-'
                        thisEvent.angle = 90 - ...
                            cfg.aperture.width / 2 - ...
                            (thisEvent.time / cycleDuration) * 360;

                end

                Screen('FillArc', cfg.aperture.texture, [0 0 0 0], ...
                    CenterRect([0 0 repmat(stimRect(4), 1, 2)], cfg.screen.winRect), ...
                    thisEvent.angle, cfg.aperture.width);

                %                 frameTimesUpdate = [frameTimesUpdate, current.angle];

            end

            % current Frame, time & condition (can also be valuable for debugging)
            frameTimes = [frameTimes; frameTimesUpdate]; %#ok<AGROW>

            %% Draw stimulus
            % we draw the background stimulus in full and overlay an aperture on top of it

            % Display background
            if cfg.rotateStimulus
                bgdAngle = thisEvent.angle;
            else
                bgdAngle = 0;
            end

            % Rotate background movie
            sineRotate = cos(thisEvent.time) * cfg.sineRotation;

            Screen('DrawTexture', cfg.screen.win, bgdTextures(thisEvent.frame), stimRect, ...
                CenterRect(stimRect, cfg.screen.winRect), bgdAngle + sineRotate);

            % Draw aperture
            apertureTexture('draw', cfg);

            drawFixation(cfg);

            %% Draw target
            [target] = drawTarget(target, targetsTimings, thisEvent, ring, cfg);

            %% Flip current frame
            rft = Screen('Flip', cfg.screen.win, rft + cfg.screen.ifi);

            %% Collect and save target info
            if target.isOnset
                target.onset = rft - cfg.experimentStart;
            elseif target.isOffset
                target.duration = (rft - cfg.experimentStart) - target.onset;
                saveEventsFile('save', cfg, target);
            end

            collectAndSaveResponses(cfg, cfg, logFile, cfg.experimentStart);

        end

        %% End the experiment
        cfg = getExperimentEnd(cfg);

        getResponse('stop', cfg.keyboard.responseBox);
        getResponse('release', cfg.keyboard.responseBox);

        saveEventsFile('close', cfg, logFile);

        eyeTracker('StopRecordings', cfg);
        eyeTracker('Shutdown', cfg);

        %       data = feedbackScreen(cfg, expParameters);

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
