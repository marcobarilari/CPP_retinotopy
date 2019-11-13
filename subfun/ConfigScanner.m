function [TrigStr, PARAMETERS] = ConfigScanner(Emulate, PARAMETERS)
if Emulate
    % Emulate scanner
    TrigStr = 'Press key to start...';
    % In manual start there are no dummies
    PARAMETERS.Dummies = 0;
    PARAMETERS.Overrun = 0;
else
    % Real scanner
    TrigStr = 'Stand by for scan...';
end
end