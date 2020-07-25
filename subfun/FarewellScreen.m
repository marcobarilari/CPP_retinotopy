function FarewellScreen(Win, PARAMETERS, Rect)
    Screen('FillRect', Win, PARAMETERS.Background, Rect);
    DrawFormattedText(Win, 'Thank you!', 'center', 'center', PARAMETERS.Foreground);
    Screen('Flip', Win);
    WaitSecs(PARAMETERS.TR * PARAMETERS.Overrun);
end
