function [MyPort] = WaitForScanTrigger(Parameters)

    %% Opening IOPort
    PortSettings = sprintf('BaudRate=115200 InputBufferSize=10000 ReceiveTimeout=60');
    PortSpec = FindSerialPort([], 1);
    
    % Open port portSpec with portSettings, return handle:
    MyPort = IOPort('OpenSerialPort', PortSpec, PortSettings);
    
    % Start asynchronous background data collection and timestamping. Use
    % blocking mode for reading data -- easier on the system:
    AsyncSetup = sprintf('BlockingBackgroundRead=1 ReadFilterFlags=0 StartBackgroundRead=1');
    IOPort('ConfigureSerialPort', MyPort, AsyncSetup);
    
    % Read once to warm up
    WaitSecs(1);
    IOPort('Read', MyPort);
    
    nTrig = 0;
    
    %% waiting for dummie triggers from the scanner
    while (nTrig <= Parameters.Dummies)
        
        [PktData, TReceived] = IOPort('Read', MyPort);
        
        % it is checked if something was received via trigger_port
        % oldtrigger is there so 'number' is only updated when something new is
        % received via trigger_port (normally you receive a "small series" of data at
        % a time)
        if isempty(PktData)
            TReceived = 0;
        end
        
        if TReceived && (oldtrigger == 0)
            Number = 1;
        else
            Number = 0;
        end
        
        oldtrigger = TReceived;
        
        if Number
            nTrig = nTrig + 1;
            Number = 0; %#ok<NASGU>
        end
        
    end

end