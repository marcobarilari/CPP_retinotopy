function EyeTrackStart(ivx)
% start iView eye tracker
if Parameters.Eyetracker.Do == 1
    % to clear data buffer
    iViewX('clearbuffer', ivx);
    % start recording
    iViewX('startrecording', ivx);
    iViewX('message', ivx, ['Start_Ret_','Subj_', Parameters.Subj,'_','_Run', num2str(Parameters.Session(end)), Parameters.Apperture,'_',Parameters.Direction]);
    iViewX('incrementsetnumber', ivx, 0);
end
end