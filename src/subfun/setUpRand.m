function [] = setUpRand()
    % Set up the randomizers for uniform and normal distributions.
    % It is of great importance to do this before anything else!
    rand('state', sum(100, clock));
    randn('state', sum(100, clock));
end
