function [Win, Rect, oldRes, ifi] = InitPTB(Parameters)

screenid = Parameters.Screen;

noScreens = length(Screen('Screens'));
if ismac && noScreens > 1 % only if projector is also a screen
    oldRes = Screen('Resolution', screenid, ...
    Parameters.Resolution(1), Parameters.Resolution(2), Parameters.Resolution(3));
end

[Win, Rect] = Screen('OpenWindow', Parameters.Screen, Parameters.Background);
Screen('TextFont', Win, Parameters.FontName);
Screen('TextSize', Win, Parameters.FontSize);
Screen('BlendFunction', Win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% interframe interval
ifi = Screen('GetFlipInterval', Win);

end