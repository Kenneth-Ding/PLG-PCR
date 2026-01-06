function [groups, groupStats] = clusterLinesBySlope3(slopes)
    % clusterLinesBySlope - 使用階層式分群依據線的斜率將線分群
    % 輸入:
    %   slopes - 一個向量，包含每條線的斜率
    % 輸出:
    %   groups - 一個元胞陣列，每個元素包含屬於該群組的線的索引
    %   groupStats - 一個結構陣列，包含每個群組的統計資訊（平均角度和標準差）
    
    % 將斜率轉換為角度（度數）
    angles = atan(slopes) * 180 / pi;
    
    % 處理角度的環狀特性：將角度統一到 [0, 180) 範圍
    % 注意：線的方向可以視為雙向的，所以角度範圍是 [0, 180) 而不是 [0, 360)
    angles = mod(angles, 180);
    
    n = length(angles);
    
    % 如果只有一條線，直接返回
    if n <= 1
        groups = {1:n};
        groupStats = struct('mean', angles, 'std', 0);
        return;
    end
    
    % 計算距離矩陣（角度差）
    distMatrix = zeros(n, n);
    for i = 1:n
        for j = i+1:n
            % 計算環狀角度差
            diff = min(mod(angles(i) - angles(j), 180), mod(angles(j) - angles(i), 180));
            distMatrix(i, j) = diff;
            distMatrix(j, i) = diff;
        end
    end
    
    % 使用階層式分群
    Z = linkage(squareform(distMatrix), 'complete');
    
    % 設定最大允許角度差（5度）
    maxAngleDiff = 5;
    
    % 使用 MATLAB 內建函數直接切割樹狀圖
    % 根據閾值切割樹狀圖獲得分群結果
    clusters = cluster(Z, 'Cutoff', maxAngleDiff, 'Criterion', 'distance');
    
    % 將數字標籤轉換為分群的索引集合
    uniqueClusters = unique(clusters);
    groups = cell(length(uniqueClusters), 1);
    for i = 1:length(uniqueClusters)
        groups{i} = find(clusters == uniqueClusters(i));
    end
    
    % 計算每個群組的統計資訊
    groupStats = [];% calculateGroupStats(groups, angles);
    
    % 優化群組，使每個群組內的角度差最小化
end

function groupStats = calculateGroupStats(groups, angles)
    % calculateGroupStats - 計算每個群組的統計資訊
    % 輸入:
    %   groups - 分群結果
    %   angles - 角度向量
    % 輸出:
    %   groupStats - 包含每個群組平均角度和標準差的結構陣列
    
    numGroups = length(groups);
    groupStats = struct('mean', cell(numGroups, 1), 'std', cell(numGroups, 1), 'min', cell(numGroups, 1), 'max', cell(numGroups, 1), 'range', cell(numGroups, 1));
    
    for i = 1:numGroups
        groupAngles = angles(groups{i});
        
        % 考慮環狀特性計算平均角度和標準差
        if length(groupAngles) == 1
            groupStats(i).mean = groupAngles;
            groupStats(i).std = 0;
            groupStats(i).min = groupAngles;
            groupStats(i).max = groupAngles;
            groupStats(i).range = 0;
        else
            % 處理跨越 0/180 邊界的情況
            % 將角度轉換為弧度並使用複數表示
            radAngles = groupAngles * pi / 180;
            complex_repr = exp(1i * 2 * radAngles);  % 乘以2是因為我們的範圍是[0,180)而不是[0,360)
            
            % 計算平均角度
            mean_complex = mean(complex_repr);
            mean_angle = mod(angle(mean_complex) * 180 / pi / 2, 180);  % 除以2轉回原始範圍
            groupStats(i).mean = mean_angle;
            
            % 計算角度標準差
            % 標準差計算複雜，這裡使用一種近似方法
            diffs = zeros(size(groupAngles));
            for j = 1:length(groupAngles)
                diffs(j) = min(mod(groupAngles(j) - mean_angle, 180), mod(mean_angle - groupAngles(j), 180));
            end
            groupStats(i).std = std(diffs);
            
            % 計算角度範圍
            [minAngle, maxAngle, range] = calculateAngleRange(groupAngles);
            groupStats(i).min = minAngle;
            groupStats(i).max = maxAngle;
            groupStats(i).range = range;
        end
    end
end

function [minAngle, maxAngle, range] = calculateAngleRange(angles)
    % calculateAngleRange - 計算考慮環狀特性的角度範圍
    % 輸入:
    %   angles - 角度向量
    % 輸出:
    %   minAngle - 最小角度
    %   maxAngle - 最大角度
    %   range - 角度範圍
    
    if length(angles) <= 1
        minAngle = angles(1);
        maxAngle = angles(1);
        range = 0;
        return;
    end
    
    % 排序角度
    sortedAngles = sort(angles);
    
    % 計算相鄰角度的差異
    diffs = diff(sortedAngles);
    
    % 考慮環狀特性的最後一個差異（從最大到最小的差異）
    lastDiff = 180 - (sortedAngles(end) - sortedAngles(1));
    
    % 找出最大的間隙
    [maxGap, maxGapIdx] = max([diffs; lastDiff]);
    
    if maxGapIdx <= length(diffs)
        % 如果最大間隙在中間
        minAngle = sortedAngles(1);
        maxAngle = sortedAngles(end);
        range = maxAngle - minAngle;
    else
        % 如果最大間隙跨越邊界
        minAngle = sortedAngles(1);
        maxAngle = sortedAngles(end);
        range = 180 - maxGap;
    end
end


