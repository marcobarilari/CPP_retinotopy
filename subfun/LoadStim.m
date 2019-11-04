function Parameters = LoadStim(Parameters)
load(Parameters.StimFile);
[~, file] = fileparts(Parameters.StimFile);
if strcmpi(file, 'Checkerboard')
    Parameters.Stimulus(:,:,1) = Stimulus;
    Parameters.Stimulus(:,:,2) = uint8(InvertContrastCogent(CogentImage(Stimulus))*255);
else
    Parameters.Stimulus = Stimulus;
end
Parameters.RefreshPerStim = StimFrames;  % Video frames per stimulus frame
end