function [Behaviour, QUIT] = GetBehResp(KeyCodes, Win, Parameters, Rect, PrevKeypr, Behaviour, CyclingStart)
[Keypr, KeyTime, Key] = KbCheck;

QUIT = false;

if Keypr
    
    if Key(KeyCodes.Escape)
        % Abort screen
        Screen('FillRect', Win, Parameters.Background, Rect);
        DrawFormattedText(Win, 'Experiment was aborted!', 'center', 'center', ...
            Parameters.Foreground);
        CleanUp
        disp(' ');
        disp('Experiment aborted by user!');
        disp(' ');
        QUIT = true;
        return
    end
    
    if ~PrevKeypr
        PrevKeypr = 1;
        keyNum = find(Key);
        keyNum = keyNum(1);% prevent that trigger+response or double response spoil Behaviour.Response dimensions!!
        Behaviour.Response = [Behaviour.Response; keyNum];
        Behaviour.ResponseTime = [Behaviour.ResponseTime; KeyTime - CyclingStart];
    end
    
else
    if PrevKeypr
        PrevKeypr = 0;
    end
end
end