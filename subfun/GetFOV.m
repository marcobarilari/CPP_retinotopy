function FOV = GetFOV(PARAMETERS)
    % left-to-right angle of visual field in scanner in degree
    FOV = 2 * atan(PARAMETERS.xWidthScreen / 2 / PARAMETERS.viewDist) * 180 / pi;
end
