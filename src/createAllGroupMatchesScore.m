function [scoreMatrix, bestLinePairsMatrix] = createAllGroupMatchesScore(srcPCInfo, tgtPCInfo)

    lineGroupsInfo1 = srcPCInfo.lineGroupsInfo;
    lineGroupsInfo2 = tgtPCInfo.lineGroupsInfo;
    Mlines1 = srcPCInfo.lines;
    Mlines2 = tgtPCInfo.lines;
    linesType1 = srcPCInfo.linesType;
    linesType2 = tgtPCInfo.linesType;

    scoreMatrix = zeros(length(lineGroupsInfo1), length(lineGroupsInfo1));
    bestLinePairsMatrix = cell(length(lineGroupsInfo1), length(lineGroupsInfo1));

     for i = 1:length(lineGroupsInfo1)
        for j = 1:length(lineGroupsInfo2)
            [score, bestLinePairs] = ...
                matchLineGroups(lineGroupsInfo1(i), lineGroupsInfo2(j), Mlines1, Mlines2, linesType1, linesType2);
            scoreMatrix(i, j) = score;
            bestLinePairsMatrix{i, j} = bestLinePairs;
        end
     end
end