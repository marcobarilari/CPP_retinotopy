width = 1400;  % Define here the height of the screen minus a few pixels
Phases = 0:10:350;

addpath(fullfile(pwd, 'subfun'));

Stim = zeros(width, width, length(Phases));
[X, Y] = meshgrid([-width/2:-1 1:width/2], [-width/2:-1 1:width/2]);
[T, R] = cart2pol(X,Y);
Outside = R > width/2;

f = 1;
for pha = Phases
    img = PrettyPattern(sin(pha/180*pi)/2+1, pha, width);
    img(img > 0) = 255;
    img(Outside) = 127;
    Stim(:,:,f) = img;
    f = f + 1;
end
StimFrames = 2;

Stimulus = zeros([size(Stim,1) size(Stim,2) 3 size(Stim,3)]);
frames = size(Stim,3);
Stimulus(:,:,1,:) = Stim;
Stimulus(:,:,2,:) = Stim(:,:,[frames/2+1:frames 1:frames/2]);
Stimulus(:,:,3,:) = Stim(:,:,[frames*(3/4)+1:frames 1:frames*(3/4)]);

save('ColRipples.mat', 'Stimulus', 'StimFrames');

