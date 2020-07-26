function [target] = drawTarget(target, events, current, ring, cfg, expParameters)

    win = cfg.win;
    winRect =  cfg.winRect ;

    isTarget = false;

    target.isOnset = false;
    target.isOffset = false;

    wasTarget = target.wasTarget;
    target_width = target.target_widthPix;

    innerRimVA = [];

    switch expParameters.aperture.type
        case 'Ring'
            isRing = true;
        otherwise
            isRing = false;
    end

    if isRing
        outerRimPix = ring.outerRimPix;
        innerRimPix = ring.innerRimPix;
        innerRimVA = ring.ring_inner_rim;
    end

    % check that the current time is superior to the start time and inferior to the end time of at
    % least one event
    currTargets = events - current.time;
    if  any(all([currTargets > 0, currTargets < expParameters.target.duration], 2))
        isTarget = true;
    end

    % we wait for rings to be large enough to present some targets if
    % they are not just a change of color of the fixation dot
    if all([isRing ; innerRimVA < expParameters.target.size ; ~expParameters.target.central])
        isTarget = false;
    end

    if isTarget

        % make sure that we don't change the position of this target
        % for the time it is presented
        if ~wasTarget
            target.rndAngle = randOri;
            target.rndScale = round(rand * (winRect(4) / 2));
            target.isOnset = true;
            wasTarget = true;
        end

        % flicker the fixation dot
        if expParameters.target.central
            X = 0;
            Y = 0;
            % or display the target in the ring or wedge
        elseif isRing
            [X, Y] = pol2cart(target.rndAngle / 180 * pi, (outerRimPix / 2 + innerRimPix / 2) / 2);
        else
            [X, Y] = pol2cart((90 + current.angle + expParameters.apperture.width / 2) ...
                / 180 * pi, target.rndScale);
        end

        target.x_target_pos = X;
        target.y_target_pos = Y;

        % actual target position in pixel
        X = winRect(3) / 2 - X;
        Y = winRect(4) / 2 - Y;

        % Draw event
        Screen('FillOval', win, ...
            expParameters.target.color, ...
            [X - target_width / 2 ...
            Y - target_width / 2 ...
            X + target_width / 2 ...
            Y + target_width / 2]);

    else

        if wasTarget
            target.isOffset = true;
        end
        wasTarget = false;

    end

    target.isTarget = isTarget;
    target.wasTarget = wasTarget;

end
