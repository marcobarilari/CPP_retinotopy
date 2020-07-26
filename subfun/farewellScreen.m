function farewellScreen(cfg, expParameters)
    Screen('FillRect', cfg.win, cfg.backgroundColor, cfg.winRect);
    DrawFormattedText(cfg.win, 'Thank you!', 'center', 'center', cfg.foregroundColor);
    Screen('Flip', cfg.win);
    WaitSecs(expParameters.bids.MRI.RepetitionTime * 2);
end
