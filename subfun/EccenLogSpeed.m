function [Ring] = EccenLogSpeed(PARAMETERS, PPD, Ring, Time)
%vary CurrScale so that expansion speed is log over eccentricity
% cf. Tootell 1997; Swisher 2007; Warnking 2002 etc


CycleDuration = PARAMETERS.TR * PARAMETERS.VolsPerCycle;

switch PARAMETERS.Apperture
    case 'Ring'
        IsRing = true;
    otherwise
        IsRing = false;
end


% CurrScale only influences  ring
if IsRing
    
    CsFuncFact = Ring.CsFuncFact;
    RingWidthVA = Ring.RingWidthVA;
    MaxEcc = Ring.MaxEcc;
    
    switch PARAMETERS.Direction
        case '+'
            % current visual angle linear in time
            CurrScaleVA = 0 + mod(Time, CycleDuration)/CycleDuration * MaxEcc;
            % ensure some foveal stimulation at beginning (which is hidden by fixation cross otherwise)
            if CurrScaleVA < PARAMETERS.FixationSize + .1
                CurrScaleVA = 0.6;
            end
        case '-'
            CurrScaleVA = MaxEcc - mod(Time, CycleDuration)/CycleDuration * MaxEcc;
            if CurrScaleVA > MaxEcc - 0.1
                CurrScaleVA = MaxEcc - 0.1;
            end
    end
    
    % near-exp visual angle
    ScaleVA2 = ((CurrScaleVA+exp(1)) * log(CurrScaleVA+exp(1)) - (CurrScaleVA+exp(1))) * MaxEcc * CsFuncFact;
    ScalePix = ScaleVA2 * PPD; % in pixel
    
    %width of apperture changes logarithmically with eccentricity of inner ring
    oldScaleInnerVA = CurrScaleVA - RingWidthVA;
    if oldScaleInnerVA < 0
        oldScaleInnerVA = 0;
    end
    
    % growing with inner ring ecc
    RingWidthVA = PARAMETERS.AppertureWidth + log(oldScaleInnerVA+1);
    ScaleInnerVA = ScaleVA2 - RingWidthVA;
    ScaleInnerPix =  ScaleInnerVA * PPD; % in pixel
    
    if ScaleInnerPix < 0
        ScaleInnerPix = 0;
    end
    
    Ring.ScalePix = ScalePix;
    Ring.ScaleInnerPix = ScaleInnerPix;
    Ring.ScaleVA2 = ScaleVA2;
    Ring.ScaleInnerVA = ScaleInnerVA;
    
end


end