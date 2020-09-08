function [] = optimRetMapping()

    TR = 1.63;
    timeSpan = 0:TR:10 * 60;
    widthFOV = 39;
    eccVox = 5;
    widthRingRange = [0.5:0.5:39]; % in degree in FOV
    cycleDurRange = [10:0.5:80];
    [time, widthRing, cycleDur] = ndgrid(timeSpan, widthRingRange, cycleDurRange);

    ringSpeed = widthFOV ./ cycleDur;
    stayRingSec =  widthRing ./ ringSpeed; % time ring needs to pass a voxel
    stickFct = mod(time, cycleDur) < stayRingSec;
    [hrf, p] = spm_hrf(TR);
    Y = filter(hrf', 1, stickFct);
    Y = Y + randn(length(timeSpan), length(widthRingRange), length(cycleDurRange));
    for iWidth = 1:length(widthRingRange)
        for iCycle = 1:length(cycleDurRange)
            X = [sin(time(:, iWidth, iCycle) * 2 * pi / cycleDur(1, iWidth, iCycle)), ...
                cos(time(:, iWidth, iCycle) * 2 * pi / cycleDur(1, iWidth, iCycle)), ...
                ones(length(timeSpan), 1)];
            [param, dev, stats] = glmfit(X, Y(:, iWidth, iCycle), 'normal');
            ResVar = dev * 1 / (length(timeSpan) - 3);
            F(iWidth, iCycle) = (sum(param(1:2).^2) / 3) / ResVar;
            power(iWidth, iCycle) = abs(param(2) + i * param(1));
        end
    end
    surf(squeeze(widthRing(1, :, :)), squeeze(cycleDur(1, :, :)), power);
    surf(squeeze(widthRing(1, :, :)), squeeze(cycleDur(1, :, :)), F);
