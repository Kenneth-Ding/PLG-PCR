function linesType = classifyLine(meanDist1, stdDist1, meanAngle1, stdAngle1)
    linesType = (meanDist1 < 1) & (stdAngle1 < 20);
end