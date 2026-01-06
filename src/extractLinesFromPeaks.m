function [Mline, usedPixels] = extractLinesFromPeaks(peaks, H, xIndices, yIndices, densityMap, firstOffset, refine)
    % 初始化擴展的 peaks 結構
    extendedPeaks(length(peaks)) = struct('rhoIdx', [], 'thetaIdx', [], 'a', [], 'b', [], 'c', [], 'pixel_points', []);
    validPeakCount = 0;
    weights = densityMap(sub2ind(size(densityMap), yIndices, xIndices));

    for k = 1:length(peaks)
        % 提取當前 peak 的 rhoIdx 和 thetaIdx
        rhoIdx = peaks(k).rhoIdx;
        thetaIdx = peaks(k).thetaIdx;
        
        % 從累加矩陣 H 提取對應點的索引
        pointIdx = H{rhoIdx, thetaIdx};
        
        % 從 xIndices 和 yIndices 中獲取對應的點座標
        pixel_points = [xIndices(pointIdx), yIndices(pointIdx)];
        
        % disp(['📍 pixel_points X 範圍: 最小值 = ', num2str(min(pixel_points(:,1))), ', 最大值 = ', num2str(max(pixel_points(:,1)))]);
        % disp(['📍 pixel_points Y 範圍: 最小值 = ', num2str(min(pixel_points(:,2))), ', 最大值 = ', num2str(max(pixel_points(:,2)))]);

        % 提取 x 和 y 座標
        x = pixel_points(:, 1);
        y = pixel_points(:, 2);
        
        % 計算權重（基於 densityMap）
        % weights = zeros(size(real_x));
        pointsWeights = weights(pointIdx);

        if all(pointsWeights == 0)
            disp("pointsWeights == 0");
        end

        % 去除權重為 0 的點
        validIndices = pointsWeights > 0;
        x = x(validIndices);
        y = y(validIndices);
        pointsWeights = pointsWeights(validIndices);

        % 如果沒有有效點，跳過此 peak
        if isempty(x)
            continue;
        end
        validPeakCount = validPeakCount + 1; 
        

        % 加權最小二乘法擬合直線 y = mx + b
        X = [x, ones(size(x))];  % 構造 [x 1] 的矩陣
        % beta = X \ real_y;

        beta = lscov(X, y, pointsWeights);  % beta(1) 是斜率 m，beta(2) 是截距 b
        
        % 計算直線參數
        a = -beta(1);  % 法向量的 x 成分
        b = 1;         % 法向量的 y 成分
        c = -beta(2);  % 常數項
        
        % 將計算出的參數加入到 peaks 結構中
        extendedPeaks(validPeakCount).rhoIdx = rhoIdx;
        extendedPeaks(validPeakCount).thetaIdx = thetaIdx;
        extendedPeaks(validPeakCount).a = a;
        extendedPeaks(validPeakCount).b = b;
        extendedPeaks(validPeakCount).c = c;
        extendedPeaks(validPeakCount).pixel_points = pixel_points;
    end

    % [Mline, usedPixels] = mergeSimilarLines(extendedPeaks, 5, densityMap, firstOffset);
    [mergedLines, ~] = mergeSimilarLines(extendedPeaks, 5, densityMap, firstOffset);

    Mline = zeros(0, 3);
    usedPixels = [];
    for lineIdx = 1:size(mergedLines, 1)
        firstTime = 1;
        prevLineSlot = 0;
        predLine = mergedLines(lineIdx, :);
        % predLineUsedPixels = [];

        iter = 1;
        while refine && (firstTime || angleDiffFromSlope(prevLineSlot, predLine(1)) > 0.1) && iter <= 2
            % if iter > 1
            %     break
            % end

            iter = iter + 1;
            firstTime = 0;

            angleDiffFromSlope(prevLineSlot, predLine(1));
            pointsIdxOnLine = findPointsOnLine(predLine, 3, [xIndices, yIndices]);   %3.5
            x = xIndices(pointsIdxOnLine);
            y = yIndices(pointsIdxOnLine);

            % 計算權重（基於 densityMap）
            pointsWeights = weights(pointsIdxOnLine);

            if all(pointsWeights == 0)
                disp("pointsWeights == 0");
            end

            % 去除權重為 0 的點
            validIndices = pointsWeights > 0;
            x = x(validIndices);
            y = y(validIndices);
            pointsWeights = pointsWeights(validIndices);

            % 如果沒有有效點，跳過此 peak
            if isempty(x)
                continue;
            end

            % 加權最小二乘法擬合直線 y = mx + b
            X = [x, ones(size(x))];  % 構造 [x 1] 的矩陣
            beta = lscov(X, y, pointsWeights);  % beta(1) 是斜率 m，beta(2) 是截距 b

            % 計算直線參數
            a = -beta(1);  % 法向量的 x 成分
            b = 1;         % 法向量的 y 成分
            c = -beta(2);  % 常數項

            prevLineSlot = predLine(1);
            predLine = [a, b, c];
            % predLineUsedPixels = [x, y];
            % angleDiffFromSlope(prevLineSlot, predLine(1))
        end

        Mline = [Mline; predLine];
        pointsIdxOnLine = findPointsOnLine(predLine, 4, [xIndices, yIndices]);   % 4
        predLineUsedPixels = [xIndices(pointsIdxOnLine), yIndices(pointsIdxOnLine)];
        usedPixels = [usedPixels; predLineUsedPixels];
    end

    usedPixels = unique(usedPixels, "rows");
end