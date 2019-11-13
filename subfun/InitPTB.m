function [Win, Rect, oldRes, ifi] = InitPTB(PARAMETERS)

screenid = PARAMETERS.Screen;

noScreens = length(Screen('Screens'));
if ismac && noScreens > 1 % only if projector is also a screen
    oldRes = Screen('Resolution', screenid, ...
    PARAMETERS.Resolution(1), PARAMETERS.Resolution(2), PARAMETERS.Resolution(3));
end

[Win, Rect] = Screen('OpenWindow', PARAMETERS.Screen, PARAMETERS.Background);
Screen('TextFont', Win, PARAMETERS.FontName);
Screen('TextSize', Win, PARAMETERS.FontSize);
Screen('BlendFunction', Win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% interframe interval
ifi = Screen('GetFlipInterval', Win);

end