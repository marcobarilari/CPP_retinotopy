function ppd = GetPPD(rect, mon_width, view_dist)
    % compute pixels per degree
    ppd = pi * (rect(3) - rect(1)) / atan(mon_width / view_dist / 2) / 360;
end
