function Generic_Experiment(Parameters, Emulate)
%Generic_Experiment(Parameters, Emulate)
%
% Runs a generic psychophysics experiment. Originally this was conceived 
% for the method of constant stimuli, but it may also adapted for the
% use of staircase procedures. It should also be usable in the scanner.
%

% Default is without scanner!
if nargin < 2
    Emulate = 1;
end

% Create the mandatory folders if not already present 
if ~exist([cd filesep 'Results'], 'dir')
    mkdir('Results');
end

%% Initialize randomness & keycodes
SetupRand;
SetupKeyCodes;

%% Configure scanner 
[TrigStr, Parameters] = ConfigScanner(Emulate, Parameters);

%% Initialize PTB
[Win, Rect] = Screen('OpenWindow', Parameters.Screen, Parameters.Background, Parameters.Resolution, 32); 
Screen('TextFont', Win, Parameters.FontName);
Screen('TextSize', Win, Parameters.FontSize);
Screen('BlendFunction', Win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
HideCursor;
RefreshDur = Screen('GetFlipInterval',Win);
Slack = RefreshDur / 2;

%% Various variables
Results = [];
CurrVolume = 0;
Slice_Duration = Parameters.TR / Parameters.Number_of_Slices;
StartExpmt = NaN;


%% Loop through blocks
for Block = 0 : Parameters.Blocks_per_Expmt-1
    if Parameters.Shuffle_Conditions
        %% Reshuffle the conditions for this block
        Reshuffling = randperm(length(Parameters.Conditions));
    else
        %% Conditions in pre-defined order
        Reshuffling = 1 : length(Parameters.Conditions);
    end
    
    %% Standby screen
    Screen('FillRect', Win, Parameters.Background, Rect);
    DrawFormattedText(Win, [Parameters.Welcome '\n \n' Parameters.Instruction '\n \n' ... 
                                            'Block ' num2str(Block+1) ' of ' num2str(Parameters.Blocks_per_Expmt) '\n \n' ...
                                            TrigStr], 'center', 'center', Parameters.Foreground); 
    Screen('Flip', Win);
    if Emulate
        WaitSecs(0.1);
        KbWait;
        [bkp, Start_of_Block(Block+1), bk] = KbCheck;           
    else
        %%% CHANGE THIS TO WHATEVER CODE YOU USE TO TRIGGER YOUR SCRIPT!!! %%% 
        Start_of_Block(Block+1) = GetSecs;
        bk = zeros(1,256);
    end
    if isnan(StartExpmt)
        StartExpmt = Start_of_Block(Block+1);
    end
    
    % Abort if Escape was pressed
    if bk(KeyCodes.Escape) 
        % Abort screen
        Screen('FillRect', Win, Parameters.Background, Rect);
        DrawFormattedText(Win, 'Experiment was aborted!', 'center', 'center', Parameters.Foreground); 
        Screen('Flip', Win);

        CleanUp
        
        disp('Experiment aborted by user!'); 

        % Experiment duration
        EndExpmt = GetSecs;

        DispExpDur(EndExpmt, StartExpmt)

        return
    end
    Screen('FillRect', Win, Parameters.Background, Rect);
    Screen('Flip', Win);

    %% Run stimulus sequence 
    for Trial = 1 : length(Parameters.Conditions)    
    	% Current volume 
    	CurrVolume = ceil((GetSecs - Start_of_Block(Block+1)) / Parameters.Number_of_Slices) - Parameters.Dummies;
        
        % Begin trial
        TrialOutput = struct;
        TrialOutput.TrialOnset = GetSecs;
        TrialOutput.TrialOffset = NaN;

        % Call stimulation sequence
        CurrCondit = Parameters.Conditions(Reshuffling(Trial));
        eval(Parameters.Stimulus_Sequence);  % Custom script for each experiment!
              
        % Abort if Escape was pressed
        if find(TrialOutput.Key) == KeyCodes.Escape
            % Abort screen
            Screen('FillRect', Win, Parameters.Background, Rect);
            DrawFormattedText(Win, 'Experiment was aborted mid-block!', 'center', 'center', Parameters.Foreground); 
            
            CleanUp
            
            disp('Experiment aborted by user mid-block!'); 
            
            % Experiment duration
            EndExpmt = GetSecs;
            DispExpDur(EndExpmt, StartExpmt)
            return
        end
        
        % Reaction to response
        if exist('Feedback.m') == 2
            Feedback;
        end
        TrialOutput.TrialOffset = GetSecs;

        % Record trial results   
        Results = [Results; TrialOutput];
    end
    
    % Clock after experiment
    EndExpmt = GetSecs;

    %% Save results of current block
    Screen('FillRect', Win, Parameters.Background, Rect);
    DrawFormattedText(Win, 'Saving data...', 'center', 'center', Parameters.Foreground); 
    Screen('Flip', Win);
    save(['Results' filesep Parameters.Session_name]);
end


%% Farewell screen
Screen('FillRect', Win, Parameters.Background, Rect);
DrawFormattedText(Win, 'Thank you!', 'center', 'center', Parameters.Foreground); 
Screen('Flip', Win);
WaitSecs(Parameters.TR * Parameters.Overrun);

CleanUp

%% Experiment duration
DispExpDur(EndExpmt, StartExpmt)

