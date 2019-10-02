function [Session, SessName] = CurrentSession(BaseName, OutputDir)
%[Session, Sess_name] = CurrentSession(Base_name)
%
% Returns the number and name of the current session.


Session = 1;
SessName = [BaseName '_' num2str(Session)];

while exist(fullfile(OutputDir, [SessName '.mat']), 'file')
    Session = Session + 1;
    SessName = [BaseName '_' num2str(Session)];
end

disp(['Running session: ' SessName]);
disp(' ');

end