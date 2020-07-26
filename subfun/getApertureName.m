function apertureName = getApertureName(expParameters, apertures, iApert)

    switch expParameters.aperture
        case 'Bar'
            apertureName = sprintf('bar_angle-%i_position-%02.2f.tif', ...
                apertures.barAngle(iApert), ...
                apertures.barPostion(iApert));
        case 'Wedge'
            apertureName = sprintf('wedge_nb-%i.tif', iApert);
        case 'Ring'
            apertureName = sprintf('ring_nb-%i.tif', iApert);
    end

end
