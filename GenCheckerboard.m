width = 636;    % Define here the height of the screen 


addpath('Common_Functions');
Stimulus = RadialCheckerBoard([width/2 0], [-180 180], [7 5]);
StimFrames = 8;

save('Checkerboard', 'Stimulus', 'StimFrames');
