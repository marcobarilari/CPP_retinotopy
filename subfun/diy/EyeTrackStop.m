function EyeTrackStop(ivx)
% stop iView eye tracker
if Parameters.Eyetracker.Do == 1
    % stop tracker
    iViewX('stoprecording', ivx);
    % save data file
    thedatestr = datestr(now, 'yyyy-mm-dd_HH.MM');
    strFile = ['"D:\Data\trohe\Ret_Subj_', Parameters.Subj, '_Run', num2str(Parameters.Session(end)),'_', Parameters.Apperture,'_',Parameters.Direction,'_',thedatestr, '.idf"'];
    iViewX('datafile', ivx,strFile); % gaensefuessc hen important!
    %close iView connection
    iViewX('closeconnection', ivx);
end
end