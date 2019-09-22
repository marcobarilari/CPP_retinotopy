width = 1400;  % Define here the height of the screen minus a few pixels
Phases = 0:5:355;

Stimulus = zeros(width, width, length(Phases));
[X Y] = meshgrid([-width/2:-1 1:width/2], [-width/2:-1 1:width/2]);
[T R] = cart2pol(X,Y);
Outside = R > width/2;

f = 1;
for pha = Phases
    img = PrettyPattern(sin(pha/180*pi)/4+1/2, pha, width);
    img(img > 0) = 255;
    img(Outside) = 127;
    Stimulus(:,:,f) = img;
    f = f + 1;
end
StimFrames = 1;

save('Ripples', 'Stimulus', 'StimFrames');