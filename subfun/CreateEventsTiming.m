function Events = CreateEventsTiming(Parameters)
e = Parameters.TR : Parameters.EventDuration : (Parameters.CyclesPerExpmt * Parameters.VolsPerCycle * Parameters.TR);
tmp = rand(length(e),1);
Events = e(tmp < Parameters.ProbOfEvent)';
% Add a dummy event at the end of the Universe
Events = [Events; Inf];
end