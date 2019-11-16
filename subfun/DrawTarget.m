function [TARGET] = DrawTarget(TARGET, Events, IsRing, CURRENT, RING, Win, Rect, PARAMETERS)

IsEvent = false;

TARGET.Onset = false;
TARGET.Offset = false;

WasEvent = TARGET.WasEvent;
EventSizePix = TARGET.EventSizePix;

ScaleInnerVA = [];

if IsRing
    ScalePix = RING.ScalePix;
    ScaleInnerPix = RING.ScaleInnerPix;
    ScaleInnerVA = RING.ScaleInnerVA;
end

% check that the current time is superior to the start time and inferior to the end time of at
% least one event
CurrEvents = Events - CURRENT.Time;
if  any( all( [CurrEvents > 0 , CurrEvents < PARAMETERS.EventDuration], 2 ) )
    IsEvent = true;
end

% we wait for rings to be large enough to present some targets if
% they are not just a change of color of the fixation dot
if all( [IsRing ; ScaleInnerVA < PARAMETERS.EventSize ; ~PARAMETERS.EventCentral] )
    IsEvent = false;
end

if IsEvent
    
    % make sure that we don't change the position of this target
    % for the time it is presented
    if ~WasEvent
        TARGET.RndAngle = RandOri;
        TARGET.RndScale = round(rand*(Rect(4)/2));
        TARGET.Onset = true;
        WasEvent = true;
    end
    
    % flicker the fixation dot
    if PARAMETERS.EventCentral
        X = 0;
        Y = 0;
    % or display the target in the ring or wedge
    elseif IsRing
        [X, Y] = pol2cart( TARGET.RndAngle/180*pi, (ScalePix/2 + ScaleInnerPix/2)/2 );
    else
        [X, Y] = pol2cart( (90 + CURRENT.Angle + PARAMETERS.AppertureWidth/2) / 180*pi, TARGET.RndScale );
    end
    
    TARGET.X = X;
    TARGET.Y = Y;

    % actual target position in pixel
    X = Rect(3)/2-X;
    Y = Rect(4)/2-Y;

    % Draw event
    Screen('FillOval', Win, ...
        PARAMETERS.EventColor,...
        [X-EventSizePix/2 ...
        Y-EventSizePix/2 ...
        X+EventSizePix/2 ...
        Y+EventSizePix/2]);
    
else
    
    if WasEvent
        TARGET.Offset = true;
    end
    WasEvent = false;
    
end

TARGET.IsEvent = IsEvent;
TARGET.WasEvent = WasEvent;

end