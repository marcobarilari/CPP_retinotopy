function Parameters = LoadStim(Stim, Parameters)
load(Stim);
if strcmpi(Stim, 'Checkerboard')
    Parameters.Stimulus(:,:,1) = Stimulus;
    Parameters.Stimulus(:,:,2) = uint8(InvertContrastCogent(CogentImage(Stimulus))*255);
else
    Parameters.Stimulus=Stimulus;
end
Parameters.RefreshsPerStim=StimFrames;  % Video frames per stimulus frame
end