function [TrigStr, Parameters] = ConfigScanner(Emulate, Parameters)
if Emulate
    % Emulate scanner
    TrigStr = 'Press key to start...';
    % In manual start there are no dummies
    Parameters.Dummies = 0;
    Parameters.Overrun = 0;
else
    % Real scanner
    TrigStr = 'Stand by for scan...';
end
end