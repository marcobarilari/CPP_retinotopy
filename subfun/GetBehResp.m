function [BEHAVIOUR, PrevKeypr, QUIT] = GetBehResp(KeyCodes, Win, PARAMETERS, Rect, PrevKeypr, BEHAVIOUR, StartExpmt)

    [Keypr, KeyTime, Key] = KbCheck;

    QUIT = false;

    if Keypr

        QUIT = ExperimentAborted(Key, KeyCodes, Win, PARAMETERS, Rect);

        if ~PrevKeypr
            PrevKeypr = 1;
            if Key(KeyCodes.Resp)
                keyNum = find(Key);
                % prevent that trigger+response or double response spoil Behaviour.Response dimensions!!
                keyNum = keyNum(1);
                BEHAVIOUR.Response = [BEHAVIOUR.Response; keyNum];
                BEHAVIOUR.ResponseTime = [BEHAVIOUR.ResponseTime; KeyTime - StartExpmt];
            end
        end

    else
        if PrevKeypr
            PrevKeypr = 0;
        end
    end
end
