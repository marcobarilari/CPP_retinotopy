function SaveToMat(PARAMETERS, FrameTimes, BEHAVIOUR, KeyCodes, StartExpmt) %#ok<INUSD>

if IsOctave
    save([PARAMETERS.OutputFilename '.mat'], '-mat7-binary', ...
        'FrameTimes', 'BEHAVIOUR', 'PARAMETERS', 'KeyCodes', 'StartExpmt');
else
    save([PARAMETERS.OutputFilename '.mat'], '-v7.3', ...
        'FrameTimes', 'BEHAVIOUR', 'PARAMETERS', 'KeyCodes', 'StartExpmt');
end

end