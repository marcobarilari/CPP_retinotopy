clear
close all 
clc

height = 1440;    % Define here the height of the screen 

addpath(genpath(fullfile(fileparts(mfilename), '..', 'subfun')));

Stimulus = RadialCheckerBoard([height/2 0], [-180 180], [7 5]);

StimFrames = 8;

save(fullfile(fileparts(mfilename('fullpath')), '..', 'input', 'Checkerboard.mat'), 'Stimulus', 'StimFrames');

fprintf('Done\n')
