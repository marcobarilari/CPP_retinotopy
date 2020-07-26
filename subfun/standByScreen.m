function standByScreen(cfg, expParameters)
    % Wait for space key to be pressed
    pressSpaceForMe();
    
    Screen('FillRect', cfg.win, cfg.backgroundColor, cfg.winRect);
    
    DrawFormattedText(cfg.win, [expParameters.instruction '\n \n' cfg.triggerString], ...
        'center', 'center', cfg.foregroundColor);
    
    Screen('Flip', cfg.win);
end