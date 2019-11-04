function [Target] = DrawTarget(Target, Events, IsRing, Current, Ring, Win, Rect, Parameters)

IsEvent = false;

WasEvent = Target.WasEvent;
EventSizePix = Target.EventSizePix;

Time = Current.Time;
Angle = Current.Angle;

ScaleInnerVA = Ring.ScaleInnerVA;

if IsRing    
    ScalePix = Ring.ScalePix;
    ScaleInnerPix = Ring.ScaleInnerPix;
end

% check that the current time is superior to the start time and inferior to the end time of at
% least one event
CurrEvents = Events - Time;
if  any( all( [CurrEvents > 0 , CurrEvents < Parameters.EventDuration], 2 ) )
    IsEvent = true;
end

% we wait for rings to be large enough to present some targets if
% they are not just a change of color of the fixation dot
if all( [IsRing ; ScaleInnerVA < Parameters.EventSize ; ~Parameters.EventCentral] )
    IsEvent = false;
end

if IsEvent
    
    % make sure that we don't change the position of this target
    % for the time it is presented
    if ~WasEvent
        Target.RndAngle = RandOri;
        Target.RndScale = round(rand*(Rect(4)/2));
        WasEvent = true;
    end
    
    if IsRing        
        [X, Y] = pol2cart( Target.RndAngle/180*pi, (ScalePix/2 + ScaleInnerPix/2)/2 );
    else
        [X, Y] = pol2cart( (90 + Angle + Parameters.AppertureWidth/2) / 180*pi, Target.RndScale );
    end
    
    % flicker the fixation dot
    if Parameters.EventCentral
        X = 0;
        Y = 0;
    end
    
    % target position;
    X = Rect(3)/2-X;
    Y = Rect(4)/2-Y;
    
    % Draw event
    Screen('FillOval', Win, ...
        Parameters.EventColor,...
        [X-EventSizePix/2 ...
        Y-EventSizePix/2 ...
        X+EventSizePix/2 ...
        Y+EventSizePix/2]);
    
else
    
    WasEvent = false;
    
end

Target.IsEvent = IsEvent;
Target.WasEvent = WasEvent;

end