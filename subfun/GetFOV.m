function FOV = GetFOV(Parameters)
% left-to-right angle of visual field in scanner in degree
FOV = 2* atan( Parameters.xWidthScreen / 2 / Parameters.viewDist) * 180/pi; 
end