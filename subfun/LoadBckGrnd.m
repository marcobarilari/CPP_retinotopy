function BgdTextures = LoadBckGrnd(PARAMETERS, Win)
BgdTextures = [];
if length(size(PARAMETERS.Stimulus)) < 4
    for f = 1:size(PARAMETERS.Stimulus, 3)
        BgdTextures(f) = Screen('MakeTexture', Win, PARAMETERS.Stimulus(:,:,f)); %#ok<*AGROW>
    end
else
    for f = 1:size(PARAMETERS.Stimulus, 4)
        BgdTextures(f) = Screen('MakeTexture', Win, PARAMETERS.Stimulus(:,:,:,f));
    end
end
end