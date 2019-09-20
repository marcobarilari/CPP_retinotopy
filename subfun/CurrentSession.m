function [Session, Sess_name] = CurrentSession(BaseName)
%[Session, Sess_name] = CurrentSession(Base_name)
%
% Returns the number and name of the current session.
%

Session = 1;
Sess_name = [BaseName '_' num2str(Session)];

while exist([ filesep Sess_name '.mat'])
    Session = Session + 1;
    Sess_name = [BaseName '_' num2str(Session)];
end

 disp(['Running session: ' Sess_name]); disp(' ');
 
end