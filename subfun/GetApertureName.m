function ApertureName = GetApertureName(PARAMETERS, Apertures, iApert)

switch PARAMETERS.Apperture
    case 'Bar'
        ApertureName = sprintf('bar_angle-%i_position-%02.2f.tif', ...
            Apertures.BarAngle(iApert), ...
            Apertures.BarPostion(iApert));
    case 'Wedge'
        ApertureName = sprintf('wedge_nb-%i.tif', iApert);
    case 'Ring'
        ApertureName = sprintf('ring_nb-%i.tif', iApert);        
end

end