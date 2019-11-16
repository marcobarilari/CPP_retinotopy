function PlotResults(Data, PARAMETERS)

if isempty(Data)
    return
end

close all

figure(1)

hold on

IsStim = Data(:,2)<3;
IsTarget = Data(:,2)==3;
IsResp = Data(:,2)==4;

% plot stim
switch PARAMETERS.Apperture
    case 'Ring'
        plot(Data(IsStim,1), Data(IsStim,9))
        plot(Data(IsStim,1), Data(IsStim,10))
        Legend = {'outer', 'inner', 'target', 'response'};
        
    case 'Wedge'
        plot(Data(IsStim,1), Data(IsStim,4))
        Legend = {'angle', 'target', 'response'};
end

% plot target and responses
stem(Data(IsTarget,1), 5*ones(sum(IsTarget),1), '-k')
stem(Data(IsResp,1), 5*ones(sum(IsResp),1), '-r')

legend(Legend)

plot([0 Data(end,1)], [0 0], '-k')

axis tight

xlabel('time (seconds)')

end