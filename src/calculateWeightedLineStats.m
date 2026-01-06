function [meanDist, stdDist, meanAngle, stdAngle, centroidX, centroidY, totalWeights] = ...
    calculateWeightedLineStats(lines, x, y, densityMap, gradientAngleMap, lineWidth)
    % 計算線周圍指定距離內的點的加權距離和斜率的統計量
    %
    % 輸入:
    %   lines: N x 3 矩陣，每行表示一條線 [a, b, c]，其中ax + by + c = 0
    %   x: 1 x L 矩陣，所有點的x座標
    %   y: 1 x L 矩陣，所有點的y座標
    %   densityMap: 權重地圖，densityMap(y, x)代表點(x, y)的權重
    %   gradientAngleMap: 斜率角度地圖，gradientAngleMap(y, x)代表點(x, y)的斜率角度(0~179度)
    %   lineWidth: 要考慮的線寬範圍
    %
    % 輸出:
    %   meanDist: N x 1 向量，每條線的加權距離平均值
    %   stdDist: N x 1 向量，每條線的加權距離標準差
    %   meanAngle: N x 1 向量，每條線上點的加權斜率角度平均值
    %   stdAngle: N x 1 向量，每條線上點的加權斜率角度標準差
    %   centroidX: N x 1 向量，每條線上點的加權質心X座標
    %   centroidY: N x 1 向量，每條線上點的加權質心Y座標
    %   totalWeights: N x 1 向量，每條線上點的總權重

    % 獲取線的數量和點的數量
    numLines = size(lines, 1);
    % numPoints = length(x);
    
    % 初始化輸出
    meanDist = zeros(numLines, 1);
    stdDist = zeros(numLines, 1);
    totalWeights = zeros(numLines, 1);
    meanAngle = zeros(numLines, 1);
    stdAngle = zeros(numLines, 1);
    centroidX = zeros(numLines, 1);
    centroidY = zeros(numLines, 1);
    
    % 確保 x 和 y 是列向量
    % x 和 y 已經 round 過，這裡只確保它們是列向量
    x = x(:)';
    y = y(:)';
    
    % 對每條線進行計算
    for i = 1:numLines
        a = lines(i, 1);
        b = lines(i, 2);
        c = lines(i, 3);
        
        % 計算每個點到直線的距離
        % 距離公式: d = |ax + by + c| / sqrt(a^2 + b^2)
        distances = abs(a*x + b*y + c) / sqrt(a^2 + b^2);
        
        % 篩選在指定線寬內的點
        validPointsIndices = find(distances <= lineWidth);
        
        if isempty(validPointsIndices)
            % 若無點在線寬範圍內，則設置為NaN
            meanDist(i) = NaN;
            stdDist(i) = NaN;
            totalWeights(i) = 0;
            meanAngle(i) = NaN;
            stdAngle(i) = NaN;
            centroidX(i) = NaN;
            centroidY(i) = NaN;
            continue;
        end
        
        % 提取有效點的距離和座標
        validDistances = distances(validPointsIndices);
        validX = round(x(validPointsIndices));  % 確保座標為整數用於索引
        validY = round(y(validPointsIndices));  % 確保座標為整數用於索引
        
        % 獲取這些點的權重，使用矩陣索引而非迴圈
        % 由於 x, y 已經 round 過，且不會超出 densityMap 範圍，可直接索引
        % 將 validX 和 validY 轉換為索引
        xIdx = validX;
        yIdx = validY;
        
        % 使用 sub2ind 將行列索引轉換為線性索引
        linearIdx = sub2ind(size(densityMap), yIdx, xIdx);
        
        % 直接從 densityMap 中獲取權重
        weights = densityMap(linearIdx);
        
        % 直接從 gradientAngleMap 中獲取斜率角度
        angles = gradientAngleMap(linearIdx);
        
        % 計算總權重
        totalWeight = sum(weights);
        totalWeights(i) = totalWeight;
        
        if totalWeight == 0
            % 若總權重為0，則設置為NaN
            meanDist(i) = NaN;
            stdDist(i) = NaN;
            meanAngle(i) = NaN;
            stdAngle(i) = NaN;
            centroidX(i) = NaN;
            centroidY(i) = NaN;
            continue;
        end
        
        % 計算加權平均距離
        meanDist(i) = sum(validDistances .* weights) / totalWeight;
        
        % 計算加權標準差
        variance = sum(weights .* ((validDistances - meanDist(i)).^2)) / totalWeight;
        stdDist(i) = sqrt(variance);
        
        % 計算加權平均斜率角度
        meanAngle(i) = sum(angles .* weights) / totalWeight;
        
        % 計算加權斜率角度標準差
        angleVariance = sum(weights .* ((angles - meanAngle(i)).^2)) / totalWeight;
        stdAngle(i) = sqrt(angleVariance);
        
        % 計算加權質心
        centroidX(i) = sum(validX .* weights) / totalWeight;
        centroidY(i) = sum(validY .* weights) / totalWeight;
    end
end
