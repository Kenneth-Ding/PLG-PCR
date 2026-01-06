function lineGroupsInfo = analyzeLineGroupGeometry(lines, lineGroups, linesCentroid, linesPointCount)
    % 分析line groups的幾何特性和線條間距
    %
    % 輸入:
    %   lines: N x 3 矩陣，每行表示一條線 [a, b, c]，其中ax + by + c = 0
    %   lineGroups: G個元素的cell，每個元素為vector，存儲該group的line的index
    %   linesCentroid: N x 2 矩陣，表示每條線的質心座標[x, y]
    %   linesPointCount: N x 1 矩陣，表示每條線的點數
    %
    % 輸出:
    %   lineGroupsInfo: G個元素的array，每個元素為struct，包含:
    %       - sortedLines: 依x軸先後排序的線的索引
    %       - lineDists: 排序後相鄰線之間的距離
    %       - centroid: 群組質心[x, y]
    %       - normVector: 群組法向量[x, y]
    %       - normLine: 用於計算距離的垂直線[a, b, c]
    %       - avgSlope: 群組的加權平均斜率

    % 獲取群組數量
    numGroups = length(lineGroups);
    
    % 初始化輸出
    lineGroupsInfo = struct('sortedLines', [], 'lineDists', [], 'centroid', [], 'normVector', [], 'normLine', [], 'avgSlope', []);
    lineGroupsInfo = repmat(lineGroupsInfo, numGroups, 1);
    
    % 處理每個群組
    for g = 1:numGroups
        % 獲取當前群組的線索引
        groupLineIndices = lineGroups{g};
        numLinesInGroup = length(groupLineIndices);
        
        if numLinesInGroup <= 1
            % 如果群組只有一條線或沒有線，設置默認值
            lineGroupsInfo(g).sortedLines = groupLineIndices;
            lineGroupsInfo(g).lineDists = [];
            
            if numLinesInGroup == 1
                lineGroupsInfo(g).centroid = linesCentroid(groupLineIndices, :);
                
                % 根據線參數計算法向量
                line_params = lines(groupLineIndices, :);
                lineGroupsInfo(g).normVector = [line_params(1), line_params(2)] / norm([line_params(1), line_params(2)]);
                
                % 對於單條線，法線即垂直於該線並通過其質心的線
                a = line_params(1);
                b = line_params(2);
                centroid = linesCentroid(groupLineIndices, :);
                if abs(b) < 1e-10
                    % 如果線是垂直的，法線是水平的
                    lineGroupsInfo(g).normLine = [0, 1, -centroid(2)];
                    lineGroupsInfo(g).avgSlope = Inf; % 垂直線斜率為無窮大
                else
                    % 垂直線: a' = b, b' = -a
                    perpA = b;
                    perpB = -a;
                    perpC = -(perpA * centroid(1) + perpB * centroid(2));
                    lineGroupsInfo(g).normLine = [perpA, perpB, perpC];
                    lineGroupsInfo(g).avgSlope = -a / b; % 斜率 = -a/b
                end
            else
                lineGroupsInfo(g).centroid = [NaN, NaN];
                lineGroupsInfo(g).normVector = [NaN, NaN];
                lineGroupsInfo(g).normLine = [NaN, NaN, NaN];
                lineGroupsInfo(g).avgSlope = NaN;
            end
            
            continue;
        end
        
        % 獲取群組中的線
        groupLines = lines(groupLineIndices, :);
        groupCentroids = linesCentroid(groupLineIndices, :);
        groupPointCounts = linesPointCount(groupLineIndices);
        
        % 計算群組的加權平均斜率
        % 從ax + by + c = 0得到斜率 m = -a/b
        slopes = -groupLines(:, 1) ./ groupLines(:, 2);
        
        % 處理垂直線(b=0)的情況
        verticalLines = (abs(groupLines(:, 2)) < 1e-10);
        if any(verticalLines)
            slopes(verticalLines) = Inf;
        end
        
        % 加權平均斜率
        avgSlope = sum(slopes .* groupPointCounts) / sum(groupPointCounts);
        
        % 儲存平均斜率
        lineGroupsInfo(g).avgSlope = avgSlope;
        
        % 計算群組的加權質心
        groupCentroid = sum(groupCentroids .* groupPointCounts) / sum(groupPointCounts);
        
        % 計算垂直於平均斜率的線 (perpendicular slope = -1/avgSlope)
        if isinf(avgSlope)
            perpSlope = 0;  % 如果平均斜率是垂直的，垂直線是水平的
        elseif abs(avgSlope) < 1e-10
            perpSlope = Inf;  % 如果平均斜率是水平的，垂直線是垂直的
        else
            perpSlope = -1 / avgSlope;
        end
        
        % 計算垂直線的參數 (y - y0) = m(x - x0) 轉換為 ax + by + c = 0
        if isinf(perpSlope)
            perpLine = [1, 0, -groupCentroid(1)];  % 垂直線: x = x0
        else
            % y = m(x - x0) + y0 => y = m*x - m*x0 + y0 => -m*x + y + (m*x0 - y0) = 0
            perpLine = [-perpSlope, 1, perpSlope * groupCentroid(1) - groupCentroid(2)];
        end
        
        % 計算每條線與垂直線的交點
        intersections = zeros(numLinesInGroup, 2);
        for i = 1:numLinesInGroup
            line = groupLines(i, :);
            
            % 計算交點
            A = [line(1), line(2); perpLine(1), perpLine(2)];
            b = [-line(3); -perpLine(3)];
            
            % 檢查是否有唯一解
            if abs(det(A)) < 1e-10
                % 如果線是平行的，使用該線的質心作為交點
                intersections(i, :) = groupCentroids(i, :);
            else
                % 求解交點
                intersection = A \ b;
                intersections(i, :) = intersection';
            end
        end
        
        % 計算交點在垂直線上的投影距離
        % 使用歐氏距離直接計算交點之間的距離
        if numLinesInGroup > 1
            % 先計算垂直線的方向向量
            if isinf(perpSlope)
                % 垂直線: 方向是(0, 1)
                directionVector = [0, 1];
            elseif abs(perpSlope) < 1e-10
                % 水平線: 方向是(1, 0)
                directionVector = [1, 0];
            else
                % 一般線: 方向是標準化的(1, perpSlope)
                directionVector = [1, perpSlope];
                directionVector = directionVector / norm(directionVector);
            end
            
            % 計算交點沿著垂直線方向的投影值
            % 使用點積來計算投影
            projections = zeros(numLinesInGroup, 1);
            for i = 1:numLinesInGroup
                % 從原點到交點的向量
                pointVector = intersections(i, :);
                
                % 計算點積 (投影)
                projections(i) = dot(pointVector, directionVector);
            end
        else
            projections = [0];  % 只有一條線的情況
        end
        
        % 根據投影排序線
        [~, sortOrder] = sort(projections);
        sortedLineIndices = groupLineIndices(sortOrder);
        
        % 排序後，計算實際的歐氏距離作為線之間的距離
        sortedIntersections = intersections(sortOrder, :);
        lineDists = zeros(length(sortedLineIndices)-1, 1);
        for i = 1:(length(sortedLineIndices)-1)
            lineDists(i) = norm(sortedIntersections(i+1, :) - sortedIntersections(i, :));
        end
        
        % 保存結果
        lineGroupsInfo(g).sortedLines = sortedLineIndices;
        lineGroupsInfo(g).lineDists = lineDists;
        lineGroupsInfo(g).centroid = groupCentroid;
        lineGroupsInfo(g).normLine = perpLine;  % 儲存用於計算距離的垂直線
        
        % 計算群組的法向量 (垂直於平均斜率的方向)
        if isinf(avgSlope)
            % 如果平均斜率是垂直的，法向量是水平的
            normVector = [1, 0];
        elseif abs(avgSlope) < 1e-10
            % 如果平均斜率是水平的，法向量是垂直的
            normVector = [0, 1];
        else
            % 從線方程 ax + by + c = 0, 法向量是 [a, b]
            normVector = [-avgSlope, 1];
            normVector = normVector / norm(normVector);
        end
        
        lineGroupsInfo(g).normVector = normVector;
    end
end