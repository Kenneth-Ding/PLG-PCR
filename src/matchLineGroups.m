function [maxScore, bestMatches] = matchLineGroups(lineGroupInfo1, lineGroupInfo2, Mlines1, Mlines2, linesType1, linesType2)
% matchLineGroups - 找出兩個line group之間最佳的匹配組合
%
% 輸入:
%   lineGroupInfo1 - 點雲1的一個line group的資訊結構體
%   lineGroupInfo2 - 點雲2的一個line group的資訊結構體
%   Mlines1 - 點雲1的所有線參數矩陣
%   Mlines2 - 點雲2的所有線參數矩陣
%   linesType1 - 點雲1的線類別向量
%   linesType2 - 點雲2的線類別向量
%
% 輸出:
%   maxScore - 最高匹配分數
%   bestMatches - 達到最高分數的所有匹配組合，每個元素為N*2矩陣，
%                第一列為Mlines1的線索引，第二列為Mlines2的線索引

    % 獲取兩個group中的sortedLines
    lines1 = lineGroupInfo1.sortedLines;
    lines2 = lineGroupInfo2.sortedLines;

    % 獲取兩個group中的lineDists
    dists1 = lineGroupInfo1.lineDists;
    dists2 = lineGroupInfo2.lineDists;
    
    % 若其中一個group沒有線，則無法匹配
    if isempty(lines1) || isempty(lines2)
        maxScore = 0;
        bestMatches = {};
        return;
    end
    
    % 初始化最高分數和最佳匹配
    maxScore = 0;
    bestMatches = {};
    
    % 嘗試所有可能的起始匹配
    for start1 = 1:length(lines1)
        for start2 = 1:length(lines2)
            % 嘗試正向匹配
            [score, matches] = ...
                matchSequence(lines1, lines2, start1, start2, dists1, dists2, linesType1, linesType2);
            if score > maxScore
                maxScore = score;
                bestMatches = {matches};
            elseif score == maxScore && score > 0
                if ~any(cellfun(@(x) isequal(x, matches), bestMatches))
                    bestMatches{end+1} = matches;
                end
            end
            
            % 嘗試反向匹配（第二個序列倒序）
            lines2 = lines2(end:-1:1);
            dists2 = dists2(end:-1:1);
            [score, matches] = ...
                matchSequence(lines1, lines2, start1, start2, dists1, dists2, linesType1, linesType2);
            if score > maxScore
                maxScore = score;
                bestMatches = {matches};
            elseif score == maxScore && score > 0
                if ~any(cellfun(@(x) isequal(x, matches), bestMatches))
                    bestMatches{end+1} = matches;
                end
            end
        end
    end
end

function [score, matches] = matchSequence(lines1, lines2, start1, start2, dist1, dist2, linesType1, linesType2)
    % 嘗試從給定的起點開始匹配兩個序列
    % 輸入:
    %   lines1, lines2 - 兩個線序列
    %   start1, start2 - 起始索引
    %   dist1, dist2 - 距離
    %   linesType1, linesType2 - 線類型
    % 輸出:
    %   score - 匹配分數
    %   matches - 匹配的線對 [line1_idx, line2_idx]

    matches = [lines1(start1), lines2(start2)];

    % 獲取序列長度
    end1 = length(lines1);
    end2 = length(lines2);

    % 初始化當前索引
    current1 = start1 + 1;
    current2 = start2 + 1;

    if current1 <= end1 && current2 <= end2
        curTotalDist1 = dist1(current1 - 1);
        curTotalDist2 = dist2(current2 - 1);
    end

    while current1 <= end1 && current2 <= end2
        if isSimilarDist(curTotalDist1, curTotalDist2)
            matches(end + 1, :) = [lines1(current1), lines2(current2)];

            current1 = current1 + 1;
            current2 = current2 + 1;

            if current1 <= end1 && current2 <= end2
                curTotalDist1 = curTotalDist1 + dist1(current1 - 1);
                curTotalDist2 = curTotalDist2 + dist2(current2 - 1);
            end
        else
            if curTotalDist1 < curTotalDist2
                current1 = current1 + 1;
                if current1 <= end1
                    curTotalDist1 = curTotalDist1 + dist1(current1 - 1);
                end
            else
                current2 = current2 + 1;
                if current2 <= end2
                    curTotalDist2 = curTotalDist2 + dist2(current2 - 1);
                end
            end
        end
    end

    % 初始化當前索引
    current1 = start1 - 1;
    current2 = start2 - 1;

    if current1 >= 1 && current2 >= 1
        curTotalDist1 = dist1(current1);
        curTotalDist2 = dist2(current2);
    end

    while current1 >= 1 && current2 >= 1
        if isSimilarDist(curTotalDist1, curTotalDist2)
            matches(end + 1, :) = [lines1(current1), lines2(current2)];

            current1 = current1 - 1;
            current2 = current2 - 1;

            if current1 >= 1 && current2 >= 1
                curTotalDist1 = curTotalDist1 + dist1(current1);
                curTotalDist2 = curTotalDist2 + dist2(current2);
            end
        else
            if curTotalDist1 < curTotalDist2
                current1 = current1 - 1;
                if current1 >= 1
                    curTotalDist1 = curTotalDist1 + dist1(current1);
                end
            else
                current2 = current2 - 1;
                if current2 >= 1
                    curTotalDist2 = curTotalDist2 + dist2(current2);
                end
            end
        end
    end

    matches = unique(matches, 'rows');
    matches = sortrows(matches, 1);
    
    % 計算匹配分數
    score = calculateMatchScore(matches, linesType1, linesType2);
end

function [isSimilar] = isSimilarDist(dist1, dist2)
    % isSimilar = abs(dist1 - dist2) < 5;
    if dist1 == 0 && dist2 == 0
        isSimilar = true;
        return;
    end

    maxDist = max(dist1, dist2);
    distRatio1 = dist1 / maxDist;
    distRatio2 = dist2 / maxDist;
    isSimilar = abs(distRatio1 - distRatio2) < 0.05;
end



function score = calculateMatchScore(matches, linesType1, linesType2)
    % 計算匹配分數
    % 每對匹配線為1分，如果類型相同且為真，則為3分
    score = 0;
    for i = 1:size(matches, 1)
        % 每對匹配線加1分
        score = score + 1;
        
        % % 如果兩條線都是相同類型且為真，則加2分（總共3分）
        % if linesType1(matches(i, 1)) && linesType2(matches(i, 2))
        %     score = score + 2;
        % end
    end
end