clear;
close all;
clc;

Height = 1080;    % Define here the height of the screen

addpath(genpath(fullfile(fileparts(mfilename), '..', 'subfun')));

Stimulus = radialCheckerBoard([Height / 2 0], [-180 180], [7 5]);

StimFrames = 8;

save(fullfile(fileparts(mfilename('fullpath')), '..', 'input', 'Checkerboard.mat'), ...
    'Stimulus', 'StimFrames');

fprintf('Done\n');
