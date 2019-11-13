function Events = CreateEventsTiming(Parameters)
e = Parameters.TR : Parameters.EventDuration : (Parameters.CyclesPerExpmt * Parameters.VolsPerCycle * Parameters.TR);
tmp = rand(length(e),1);
Events = e(tmp < Parameters.ProbOfEvent)';

% remove events that are less than 1.5 seconds appart
Events( find(diff(Events)<1)+1 ) = [];
end