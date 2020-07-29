function standByScreen(cfg)
    % Wait for space key to be pressed
    pressSpaceForMe();
    
    Screen('FillRect', cfg.screen.win, cfg.color.background, cfg.screen.winRect);
    
    DrawFormattedText(cfg.screen.win, ...
        [cfg.task.instruction '\n \n' cfg.mri.triggerString], ...
        'center', 'center', cfg.color.foreground);
    
    Screen('Flip', cfg.screen.win);
end