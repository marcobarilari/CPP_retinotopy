% Display checkerboard

clear;
close all;
clc;

Cycles_per_Expmt = 9;
TimePerCycle = 60; % default is 60 secs

TR = 3;

DegPerSec = 360 / TimePerCycle;
Vols_per_Cycle = ceil(TimePerCycle / TR);

Parameters.Apperture_Width = 70; % Width of wedge in degrees

%%
addpath('Common_Functions');
load('Checkerboard.mat');

Parameters.Stimulus(:, :, 1) = Stimulus;
Parameters.Stimulus(:, :, 2) = uint8(InvertContrastCogent(CogentImage(Stimulus)) * 255);

AssertOpenGL;

figure('Color', [.5 .5 .5]);

try
    ScreenID = max(Screen('Screens'));

    White = WhiteIndex(ScreenID);
    Black = BlackIndex(ScreenID);
    Gray = (White - Black) / 2;

    [Win, Rect] = Screen('OpenWindow', ScreenID, Gray);

    Screen('BlendFunction', Win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    %% Load background movie
    StimRect = [0 0 size(Parameters.Stimulus, 2) size(Parameters.Stimulus, 1)];
    BgdTextures = [];
    for f = 1:size(Parameters.Stimulus, 3)
        BgdTextures(f) = Screen('MakeTexture', Win, Parameters.Stimulus(:, :, f));
    end

    %% Initialize apperture texture
    AppTexture = Screen('MakeTexture', Win, Gray * ones(Rect([4 3])));

    %%
    HideCursor;

    for CurrAngle = 1:1:359

        for f = 1:size(Parameters.Stimulus, 3)

            % Screen('DrawTexture', Win, BgdTextures(f), StimRect, CenterRect(StimRect, Rect), CurrAngle);
            %
            % Screen('Flip', Win);

            Screen('Fillrect', AppTexture, Gray);
            Screen('FillArc', AppTexture, [0 0 0 0], CenterRect([0 0 repmat(StimRect(4), 1, 2)], Rect), CurrAngle, Parameters.Apperture_Width);

            Screen('DrawTexture', Win, BgdTextures(f), StimRect, CenterRect(StimRect, Rect), CurrAngle);

            Screen('DrawTexture', Win, AppTexture);

            Screen('Flip', Win);

            ImageArray = Screen('GetImage', Win);
            imagesc(ImageArray);
            box off;
            axis off;
            set(gca, 'position', [0 0 1 1], 'units', 'normalized');

            print(gcf, ['Checkerboard_' sprintf('%01.0f', f) '_Angle_' sprintf('%03.0f', CurrAngle) '.tif'], '-dtiff');

        end

    end

    ShowCursor;

    % Done. Close Screen, release all ressouces:
    Screen('CloseAll');

catch

    ShowCursor;

    % Done. Close Screen, release all ressouces:
    Screen('CloseAll');

    % ... rethrow the error.
    psychrethrow(psychlasterror);
end
