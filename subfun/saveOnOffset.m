function [inputStructure, isOffset]= saveOnOffset(isOffset, inputStructure, cfg, rft)
    
    if isOffset
        inputStructure.duration = (rft - cfg.experimentStart) - inputStructure.onset;
        
%         inputStructure.bar_width = inputStructure.bar_width * cfg.magnify.scalingFactor;
%         inputStructure.bar_position = inputStructure.bar_position * cfg.magnify.scalingFactor;
        
        saveEventsFile('save', cfg, inputStructure);
        
        isOffset = false;
    end
    
end