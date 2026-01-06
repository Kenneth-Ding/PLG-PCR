function bestRegistration = registration2DbyLineGroups(srcPCInfo, tgtPCInfo, highestScoreGroupPairs, bestLinePairsMatrix)
% registration2DbyLineGroups - 使用成對的線組執行2D剛性配準
%
% 輸入:
%   srcPCInfo - 源點雲信息結構體，包含:
%       - points2D: 2D點座標
%       - lineGroups: 線組分組
%       - lineGroupsInfo: 線組幾何信息
%       - lines: 偵測到的線參數
%       - orgLines: 原始空間中的線參數
%       - linesType: 線的類型
%   tgtPCInfo - 目標點雲信息結構體，與srcPCInfo結構相同
%   highestScoreGroupPairs - 包含得分最高的組合，每個元素是一個2x2矩陣
%                           第一列是源點雲的組索引，第二列是目標點雲的組索引
%   bestLinePairsMatrix - 包含每對線組的最佳線對匹配
%
% 輸出:
%   bestRegistration - 最佳配準結果結構體，包含:
%       - R: 旋轉矩陣 (2x2)
%       - t: 平移向量 (1x2)
%       - score: 配準評分
%       - matchCount: 匹配點數量
%       - overlapRatio: 重疊比率
%       - transformedPoints: 變換後的源點座標

    % 初始化結果結構體
    bestRegistration = struct('R', [], 't', [], 'score', -1, 'matchCount', 0, ...
                             'overlapRatio', 0, 'transformedPoints', [], 'groupPair', []);

    bestRegistration.R = eye(2);
    bestRegistration.t = [0, 0];
    bestRegistration.transformedPoints = srcPCInfo.linesPoints;
    
    % 如果沒有高分組合，返回空結果
    if isempty(highestScoreGroupPairs)
        return;
    end
    
    % 獲取源點雲和目標點雲的2D點
    srcPoints = srcPCInfo.linesPoints;
    tgtPoints = tgtPCInfo.linesPoints;
    
    % 對每個高分組合進行處理
    for pairIdx = 1:length(highestScoreGroupPairs)
        % 獲取當前組合
        currentPair = highestScoreGroupPairs{pairIdx};
        
        % 獲取源點雲和目標點雲的組索引
        srcGroup1Idx = currentPair(1, 1);
        tgtGroup1Idx = currentPair(1, 2);
        srcGroup2Idx = currentPair(2, 1);
        tgtGroup2Idx = currentPair(2, 2);
        
        % 獲取對應的線對集合
        linePairSets1 = bestLinePairsMatrix{srcGroup1Idx, tgtGroup1Idx};
        linePairSets2 = bestLinePairsMatrix{srcGroup2Idx, tgtGroup2Idx};
        
        % 如果沒有有效的線對集合，繼續下一個組合
        if isempty(linePairSets1) || isempty(linePairSets2)
            continue;
        end
        
        % 有多組可能的線對匹配，對每組都嘗試計算變換
        for pairSet1Idx = 1:length(linePairSets1)
            for pairSet2Idx = 1:length(linePairSets2)
                % 獲取當前線對集合
                currentLinePairs1 = linePairSets1{pairSet1Idx};
                currentLinePairs2 = linePairSets2{pairSet2Idx};
                
                % 將兩組線對合併
                allLinePairs = [currentLinePairs1; currentLinePairs2];
                
                % 從線對中計算交點
                [srcIntersections, tgtIntersections] = computeLinePairIntersections(srcPCInfo, tgtPCInfo, currentLinePairs1, currentLinePairs2);
                
                % 如果沒有找到足夠的交點，繼續下一個組合
                if size(srcIntersections, 1) <= 1 || size(tgtIntersections, 1) <= 1
                    continue;
                end
                
                % 計算剛性變換 (旋轉矩陣和平移向量)
                [R, t] = computeRigidTransformation(srcIntersections, tgtIntersections);
                
                % 應用變換到源點雲
                transformedSrcPoints = applyTransformation(srcPoints, R, t);
                
                % 評估配準質量
                [score, matchCount, overlapRatio] = evaluateRegistration(transformedSrcPoints, tgtPoints);
                
                % 如果當前得分更高，更新最佳配準
                % if score > bestRegistration.score
                if matchCount > bestRegistration.matchCount
                    bestRegistration.R = R;
                    bestRegistration.t = t;
                    bestRegistration.score = score;
                    bestRegistration.matchCount = matchCount;
                    bestRegistration.overlapRatio = overlapRatio;
                    bestRegistration.transformedPoints = transformedSrcPoints;
                    bestRegistration.groupPair = currentPair;
                end
            end
        end
    end
end

function [srcIntersections, tgtIntersections] = computeLinePairIntersections(srcPCInfo, tgtPCInfo, linePairs1, linePairs2)
    % 計算兩組線對之間的所有交點
    % linePairs1, linePairs2: Nx2矩陣，每行是一對匹配線的索引[srcIdx, tgtIdx]
    
    % 獲取源點雲和目標點雲中的線參數
    srcLines = srcPCInfo.orgLines;
    tgtLines = tgtPCInfo.orgLines;
    
    % 初始化交點矩陣
    maxPossibleIntersections = size(linePairs1, 1) * size(linePairs2, 1);
    srcIntersections = zeros(maxPossibleIntersections, 2);
    tgtIntersections = zeros(maxPossibleIntersections, 2);
    
    % 計數器
    intersectionCount = 0;
    
    % 對每對線對進行遍歷
    for i = 1:size(linePairs1, 1)
        srcLineIdx1 = linePairs1(i, 1);
        tgtLineIdx1 = linePairs1(i, 2);
        
        for j = 1:size(linePairs2, 1)
            srcLineIdx2 = linePairs2(j, 1);
            tgtLineIdx2 = linePairs2(j, 2);
            
            % 跳過相同的線
            if srcLineIdx1 == srcLineIdx2 || tgtLineIdx1 == tgtLineIdx2
                continue;
            end
            
            % 獲取源點雲中的線參數
            srcLine1 = srcLines(srcLineIdx1, :);
            srcLine2 = srcLines(srcLineIdx2, :);
            
            % 獲取目標點雲中的線參數
            tgtLine1 = tgtLines(tgtLineIdx1, :);
            tgtLine2 = tgtLines(tgtLineIdx2, :);
            
            % 計算源點雲中線的交點
            srcIntersection = computeLineIntersection(srcLine1(1), srcLine1(2), srcLine1(3), ...
                                                    srcLine2(1), srcLine2(2), srcLine2(3));
            
            % 計算目標點雲中線的交點
            tgtIntersection = computeLineIntersection(tgtLine1(1), tgtLine1(2), tgtLine1(3), ...
                                                    tgtLine2(1), tgtLine2(2), tgtLine2(3));
            
            % 確認兩個交點都有效
            if ~isempty(srcIntersection) && ~any(isnan(srcIntersection)) && ...
               ~isempty(tgtIntersection) && ~any(isnan(tgtIntersection))
                
                intersectionCount = intersectionCount + 1;
                srcIntersections(intersectionCount, :) = srcIntersection;
                tgtIntersections(intersectionCount, :) = tgtIntersection;
            end
        end
    end
    
    % 裁剪到實際的交點數量
    srcIntersections = srcIntersections(1:intersectionCount, :);
    tgtIntersections = tgtIntersections(1:intersectionCount, :);
end

function intersection = computeLineIntersection(a1, b1, c1, a2, b2, c2)
    % 計算兩條線的交點
    % 線的方程式為 a*x + b*y + c = 0
    
    % 計算行列式
    det = a1 * b2 - a2 * b1;
    
    % 如果行列式接近於零，則線是平行的或重合的
    if abs(det) < 1e-10
        intersection = [NaN, NaN];
        return;
    end
    
    % 計算交點
    x = (b1 * c2 - b2 * c1) / det;
    y = (a2 * c1 - a1 * c2) / det;
    
    intersection = [x, y];
end

function [R, t] = computeRigidTransformation(p, q)
    % tform = fitgeotrans(p, q, 'nonreflectivesimilarity');  % 無反射、無縮放
    % R = tform.T(1:2, 1:2);  % 旋轉
    % t = tform.T(3, 1:2);    % 平移
    [~, ~, transform] = procrustes(q, p, 'Scaling', false, 'Reflection', false);
    R = transform.T;
    t = transform.c(1, :);
end

function [score, matchCount, overlapRatio] = evaluateRegistration(srcPoints, tgtPoints)
    % 評估註冊質量
    % srcPoints, tgtPoints: N x 2 矩陣，每行是一個點的[x, y]座標
    
    % 設定距離閾值來確定點匹配
    distanceThreshold = 0.2; % 可以根據數據調整
    
    % 如果點雲為空，返回零分
    if isempty(srcPoints) || isempty(tgtPoints)
        score = 0;
        matchCount = 0;
        overlapRatio = 0;
        return;
    end
    
    % 構建KD樹用於快速最近鄰搜索
    kdtree = KDTreeSearcher(tgtPoints);
    
    % 對源點雲中的每個點找到最近的目標點
    [~, distances] = knnsearch(kdtree, srcPoints);
    
    % 計算匹配點的數量 (距離小於閾值的點)
    matchCount = sum(distances < distanceThreshold);
    
    % 計算重疊比率
    totalPoints = size(srcPoints, 1);
    overlapRatio = matchCount / totalPoints;
    
    % 計算得分 - 使用更全面的評估標準
    % 考慮匹配點數量、重疊比例和平均匹配距離
    avgMatchDistance = mean(distances(distances < distanceThreshold));
    if isnan(avgMatchDistance)
        avgMatchDistance = Inf;
    end
    
    % 計算得分，給予匹配點數量和低距離更高的權重
    distanceScore = 1 / (1 + avgMatchDistance);  % 距離越小分數越高
    score = matchCount * overlapRatio * distanceScore;
end