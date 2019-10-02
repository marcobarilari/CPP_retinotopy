function DrawCross(Win, Parameters, FixCrossTexture, fh, fw, FixCrossRect)
if strcmp(Parameters.Apperture,'Wedge')
    % Draw the fixation cross
    Screen('DrawTexture', Win, FixCrossTexture);
elseif strcmp(Parameters.Apperture,'Ring')
    % Draw the fixation cross
    Screen('DrawTexture', Win, FixCrossTexture, [0 0 fh fw], FixCrossRect);
end
end