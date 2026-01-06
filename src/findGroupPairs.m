function [highestScoreGroupPairs] = ...
findGroupPairs(srcPCInfo, tgtPCInfo, scoreMatrix)
    highestScoreGroupPairs = {};
    lineGroupsInfo1 = srcPCInfo.lineGroupsInfo;
    lineGroupsInfo2 = tgtPCInfo.lineGroupsInfo;

    avgSlope1 = [lineGroupsInfo1.avgSlope];
    avgSlope2 = [lineGroupsInfo2.avgSlope];
    % Mlines1 = srcPCInfo.Mlines;
    % Mlines2 = tgtPCInfo.Mlines;
    % linesType1 = srcPCInfo.linesType;
    % linesType2 = tgtPCInfo.linesType;

    group1Num = length(lineGroupsInfo1);
    group2Num = length(lineGroupsInfo2);

    maxPairScore = 0;

    for idx1 = 1:group1Num
        for idx2 = idx1+1:group1Num
            for i = 1:group2Num
                for j = 1:group2Num
                    if i == j
                        continue
                    end

                    curScore = scoreMatrix(idx1, i) + scoreMatrix(idx2, j);
                    if curScore <= 2
                        continue
                    end

                    if abs(slopeAngleDifference(avgSlope1(idx1), avgSlope1(idx2)) - slopeAngleDifference(avgSlope2(i), avgSlope2(j))) > 5
                        continue
                    end

                    if curScore > maxPairScore
                        maxPairScore = curScore;
                        highestScoreGroupPairs = {[idx1, i; idx2, j]};
                    elseif curScore == maxPairScore
                        highestScoreGroupPairs{end+1} = [idx1, i; idx2, j];
                    end
                end
            end
        end
    end
end