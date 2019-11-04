clear
close all 
clc

width = 2560;    % Define here the height of the screen 

addpath(genpath(fullfile(pwd, 'subfun')));

Stimulus = RadialCheckerBoard([width/2 0], [-180 180], [7 5]);

StimFrames = 8;

save(fullfile(pwd, 'input', 'Checkerboard.mat'), 'Stimulus', 'StimFrames');
