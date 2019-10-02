function EyeTrackStop(ivx, Parameters)
% stop iView eye tracker

if Parameters.Eyetracker.Do == 1
    
    % stop tracker
    iViewX('stoprecording', ivx);
    
    % save data file
    thedatestr = datestr(now, 'yyyy-mm-dd_HH.MM');
    strFile = fullfile(OutputDir, ...
        [Parameters.Subj, ...
        '_run', num2str(Parameters.Session(end)), '_', ...
        Parameters.Apperture, '_', ...
        Parameters.Direction,'_',...
        thedatestr, '.idf"']);
    iViewX('datafile', ivx, strFile); 
    
    %close iView connection
    iViewX('closeconnection', ivx);
end
end