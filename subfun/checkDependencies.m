function checkDependencies()
% Checks that that the right dependencies are installed.

% Version
Major =  3;
Minor = 0;
Point =  15;

fprintf('Checking dependencies\n')

% check spm version
try
[~, versionStructure] = PsychtoolboxVersion;
catch
    error('Failed to check the Psychtoolbox version: Are you sure that Psychtoolbox is installed?')
end

if versionStructure.major<Major || versionStructure.major<Minor || versionStructure.point<Point
    warning('You are running an older version of Psychtoolbox: some things might not work')
end


end