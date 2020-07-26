function targetsTimings = createTargetsTiming(expParameters)

    TR = expParameters.bids.MRI.RepetitionTime;
    eventDuration = expParameters.target.duration;
    cyclesPerExpmt = expParameters.cyclesPerExpmt;
    volsPerCycle = expParameters.volsPerCycle;

    e = TR:eventDuration:(cyclesPerExpmt * volsPerCycle * TR);
    tmp = rand(length(e), 1);
    targetsTimings = e(tmp < expParameters.target.probability)';

    % remove events that are less than 1.5 seconds appart
    targetsTimings(find(diff(targetsTimings) < 1) + 1) = [];

end
