function dispExpDur(endExpmt, startExpmt)
    disp(' ');
    ExpmtDur = endExpmt - startExpmt;
    ExpmtDurMin = floor(ExpmtDur / 60);
    ExpmtDurSec = mod(ExpmtDur, 60);
    disp(['Experiment lasted ' n2s(ExpmtDurMin) ' minutes, ' n2s(ExpmtDurSec) ' seconds']);
    disp(' ');
end
