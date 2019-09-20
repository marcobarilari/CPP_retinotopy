clear
close all 
clc

width = 636;    % Define here the height of the screen 


addpath(fullfile(pwd, 'subfun'));

Stimulus = RadialCheckerBoard([width/2 0], [-180 180], [7 5]);

StimFrames = 8;

save('Checkerboard.mat', 'Stimulus', 'StimFrames');
