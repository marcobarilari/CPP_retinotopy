function [inputStructure, isOffset]= saveOnOffset(isOffset, inputStructure, cfg, rft)
    
    if isOffset
        inputStructure.duration = (rft - cfg.experimentStart) - inputStructure.onset;
        
        inputStructure.bar_angle = barInfo.bar_angle * cfg.magnify.scalingFactor;
        inputStructure.bar_position = barInfo.bar_angle * cfg.magnify.scalingFactor;
        
        saveEventsFile('save', cfg, inputStructure);
        
        isOffset = false;
    end
    
end