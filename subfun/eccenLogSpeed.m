function [ring] = eccenLogSpeed(expParameters, PPD, ring, time)
    % vary CurrScale so that expansion speed is log over eccentricity
    % cf. Tootell 1997; Swisher 2007; Warnking 2002 etc

    TR = expParameters.bids.MRI.RepetitionTime;
    cycleDuration = TR * expParameters.volsPerCycle;

    switch expParameters.aperture.type
        case 'Ring'
            isRing = true;
        otherwise
            isRing = false;
    end

    % CurrScale only influences  ring
    if isRing

        csFuncFact = ring.csFuncFact;
        ringWidthVA = ring.ringWidthVA;
        maxEcc = ring.maxEcc;

        switch expParameters.direction
            case '+'
                % current visual angle linear in time
                outerRimVA = 0 + mod(time, cycleDuration) / cycleDuration * maxEcc;
                % ensure some foveal stimulation at beginning (which is hidden by fixation cross otherwise)
                if outerRimVA < expParameters.fixationSize
                    outerRimVA = expParameters.fixationSize + .1;
                end
            case '-'
                outerRimVA = maxEcc - mod(time, cycleDuration) / cycleDuration * maxEcc;
                if outerRimVA > maxEcc
                    outerRimVA = maxEcc;
                end
        end

        % near-exp visual angle
        newOuterRimVA = ((outerRimVA + exp(1)) * log(outerRimVA + exp(1)) - ...
            (outerRimVA + exp(1))) * maxEcc * csFuncFact;
        outerRimPix = newOuterRimVA * PPD; % in pixel

        % width of apperture changes logarithmically with eccentricity of inner ring
        oldScaleInnerVA = outerRimVA - ringWidthVA;
        if oldScaleInnerVA < 0
            oldScaleInnerVA = 0;
        end

        % growing with inner ring ecc
        ringWidthVA = expParameters.aperture.width + log(oldScaleInnerVA + 1);
        innerRimVA = newOuterRimVA - ringWidthVA;

        if innerRimVA < 0
            innerRimVA = 0;
        end

        innerRimPix =  innerRimVA * PPD; % in pixel

        ring.outerRimPix = outerRimPix;
        ring.innerRimPix = innerRimPix;
        ring.ring_outer_rim = newOuterRimVA;
        ring.ring_inner_rim = innerRimVA;

    end

end
