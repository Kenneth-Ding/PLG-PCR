function [linepoints] = filterLinePoints(PCOBJ, gridStep)
    PC = pcdownsample(PCOBJ, 'gridAverage', 0.2).Location;
    PC2D = PC(:, 1:2);
    [n, ~] = size(PC2D);
    [idx, ~] = rangesearch(PC2D, PC2D, 0.3 * gridStep);
    density = zeros(1, n);
    for i=1:n
        density(i) = length(idx{i});
    end
    numden = 5;
    linepoints = PC2D(density > numden, :);
end