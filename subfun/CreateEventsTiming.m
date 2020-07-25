function Events = CreateEventsTiming(PARAMETERS)
    e = PARAMETERS.TR:PARAMETERS.EventDuration:(PARAMETERS.CyclesPerExpmt * PARAMETERS.VolsPerCycle * PARAMETERS.TR);
    tmp = rand(length(e), 1);
    Events = e(tmp < PARAMETERS.ProbOfEvent)';

    % remove events that are less than 1.5 seconds appart
    Events(find(diff(Events) < 1) + 1) = [];
end
