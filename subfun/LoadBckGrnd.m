function BgdTextures = LoadBckGrnd(Parameters, Win)
BgdTextures = [];
if length(size(Parameters.Stimulus)) < 4
    for f = 1:size(Parameters.Stimulus, 3)
        BgdTextures(f) = Screen('MakeTexture', Win, Parameters.Stimulus(:,:,f)); %#ok<*AGROW>
    end
else
    for f = 1:size(Parameters.Stimulus, 4)
        BgdTextures(f) = Screen('MakeTexture', Win, Parameters.Stimulus(:,:,:,f));
    end
end
end