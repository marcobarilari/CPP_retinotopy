function bgdTextures = loadBckGrnd(stimulus, win)
    bgdTextures = [];
    if length(size(stimulus)) < 4
        for f = 1:size(stimulus, 3)
            bgdTextures(f) = Screen('MakeTexture', win, stimulus(:, :, f)); %#ok<*AGROW>
        end
    else
        for f = 1:size(stimulus, 4)
            bgdTextures(f) = Screen('MakeTexture', win, stimulus(:, :, :, f));
        end
    end
end
