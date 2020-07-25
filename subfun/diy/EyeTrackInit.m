function ivx = EyeTrackInit(Parameters)
    % initialize iView eye tracker

    ivx = [];

    if Parameters.Eyetracker.Do == 1

        host = Parameters.Eyetracker.Host;
        port = Parameters.Eyetracker.Port;
        window = Parameters.Eyetracker.Window;

        % original: ivx=iviewxinitdefaults(window, 9 , host, port);
        ivx = iviewxinitdefaults2(window, 9, [], host, port);
        ivx.backgroundColour = 0;
        [~, ivx] = iViewX('openconnection', ivx);
        [success, ivx] = iViewX('checkconnection', ivx);
        if success ~= 1
            error('connection to eye tracker failed');
        end
    end
end
