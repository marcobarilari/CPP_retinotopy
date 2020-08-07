function [inputStructure, isOffset]= saveOnOffset(isOffset, inputStructure, cfg, rft)
    
    if isOffset
        inputStructure.duration = (rft - cfg.experimentStart) - inputStructure.onset;
        saveEventsFile('save', cfg, inputStructure);
        
        isOffset = false;
    end
    
end