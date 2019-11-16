 % Define here the height of the screen minus a few pixels
 
Height = 1400; 

Phases = 0:10:355;

addpath(genpath(fullfile(fileparts(mfilename), '..', 'subfun')));

Stimulus = zeros(Height, Height, length(Phases));
[X, Y] = meshgrid([-Height/2:-1 1:Height/2], [-Height/2:-1 1:Height/2]);
[T, R] = cart2pol(X,Y);
Outside = R > Height/2;

f = 1;
for pha = Phases
    img = PrettyPattern(sin(pha/180*pi)/4+1/2, pha, Height);
    img(img > 0) = 255;
    img(Outside) = 127;
    Stimulus(:,:,f) = img;
    f = f + 1;
end
StimFrames = 1;

save(fullfile(fileparts(mfilename('fullpath')), '..', 'input', 'Ripples.mat'), 'Stimulus', 'StimFrames');