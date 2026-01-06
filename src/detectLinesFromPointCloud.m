function [Mlines, Slinepoint, edgeMap, densityMap, gradientAngleMap, totalOffset] = detectLinesFromPointCloud(PCOBJ1, gridStep)

    dspc1 = pcdownsample(PCOBJ1, 'gridAverage', gridStep);
    PC1 = dspc1.Location;
    
    % % 2. 顯示下採樣結果
    % disp(['Original Point Cloud Size: ', num2str(size1(1))]);
    
    PC2D = PC1(:, 1:2);
    PC2D_int = round(PC2D / gridStep);
    %PC2D_int = round(linepoint / gridStep);

    Slinepoint = PC2D;
    
    % 3. 計算影像的大小，找到整數座標中最大的 x 和 y 值（確定影像範圍）
    max_x = max(PC2D_int(:, 1));
    max_y = max(PC2D_int(:, 2));
    min_x = min(PC2D_int(:, 1));
    min_y = min(PC2D_int(:, 2));
    
    firstOffset = [min_x, max_x, min_y, max_y];
    offset1 = [min_x - 1, min_y - 1];
    
    % 3. 建立一個密度統計矩陣densityMap，densityMap 的大小等於 x, y 座標範圍（確保所有點在影像中）
    densityMap = zeros(max_y - min_y + 1, max_x - min_x + 1);
    
    % 4. 統計每個像素格上有多少點雲被投影到上面
    for i = 1:size(PC2D_int, 1)
        % 調整所有點的 x, y 座標，使之從 (1, 1) 開始
        x = PC2D_int(i, 1) - min_x + 1;
        y = PC2D_int(i, 2) - min_y + 1;
        densityMap(y, x) = densityMap(y, x) + 1;  % 計數每個像素格上的點數
    end
    
    % disp(['Max density value: ', num2str(max(densityMap(:)))]);
    % disp(['Min density value: ', num2str(min(densityMap(:)))]);
    
    normalizedDensityMap = mat2gray(densityMap);
    normalizedDensityMap(densityMap < 8) = 0;
    densityMap(densityMap < 8) = 0;
    
    %edgeMap_ = densityMap~=0;
    %edgeMap_ = bwmorph(densityMap~=0, "thin", Inf);
    
    grayImage = uint8((1 - normalizedDensityMap) * 255);
    
    edgeMap = edge(grayImage, 'canny');
    edgeMap = imdilate(edgeMap, strel('disk', 2, 8));
    edgeMap = imerode(edgeMap, strel('disk', 3, 8)); % & edgeMap_;
    
    % figure;
    % imshow(edgeMap);
    % title("Closing");
    
    edgeMap = bwmorph(edgeMap, "thin", Inf);
    
    % figure;
    % imshow(edgeMap);
    % title("Skeleton");
    
    % edgeMap = edgeMap_ & edgeMap;
    edgeMap = removeFullNeighborhood(edgeMap);
    edgeMap = removeIsolatedPixels(edgeMap);
    [edgeMap, offset2, secondOffset] = cropEdgeMap(edgeMap);
    
    % figure;
    % imshow(edgeMap);
    % title("Crop edgeMap");
    
    % grayImage = cropImage(grayImage, secondOffset);

    densityMap = cropImage(densityMap, secondOffset);
    
    totalOffset = offset1 + offset2;
    % 找出為1的點
    [row, col] = find(edgeMap == 1);
    % disp(nnz(edgeMap));

    
    [extGradX, extGradY, extGradMag, extGradDir] = computeExtendedNeighborhoodGradient(edgeMap, 5);
    [extSmoothGradX, extSmoothGradY, ~, ~] = smoothGradientField(extGradX, extGradY, extGradMag, extGradDir, edgeMap, 5);
    Ix = extSmoothGradX;
    Iy = extSmoothGradY;
    % disp(['Grad Compute time: ' num2str(toc)]);
    
    % 僅處理有值的點
    Ix_edge = Ix(sub2ind(size(Ix), row, col));
    Iy_edge = Iy(sub2ind(size(Iy), row, col));
    
    % 計算梯度幅值和角度
    gradientAngle = atan(Iy_edge ./ Ix_edge);
    
    % 將角度映射到 [-π/2, π/2) 範圍ab
    gradientAngleWrapped = gradientAngle .* 180 ./ pi;
    
    % 找出哪些角度為 NaN，並將它們移除
    validIndices = ~isnan(gradientAngleWrapped);
    
    % 根據有效的角度，篩選對應的座標和梯度角度
    row = row(validIndices);
    col = col(validIndices);
    gradientAngleWrapped = gradientAngleWrapped(validIndices);
    
    gradientAngleMap = zeros(size(edgeMap));
    gradientAngleMap(sub2ind(size(Ix), row, col)) = gradientAngleWrapped; 
    
    
    % 用 Weighted Hough Transform 測線
    numLine = 12;
    updatedImage = edgeMap;
    % globalExtendedPeaks = [];
    
    Mlines = [];
    
    for i = 1:numLine
        % tic;
    
        [yIndices, xIndices] = find(updatedImage);
        [H, H_count, maxVotes] = myHoughTransform(updatedImage, densityMap);
        peaks = myHoughPeaks(H_count, maxVotes - 1);  % * 0.97         * 0.995
        [pixelLines, used_pixels] = extractLinesFromPeaks(peaks, H, xIndices, yIndices, densityMap, firstOffset, true);

        % extendedPeaks = extendPeaksWithLineParams(peaks, H, xIndices, yIndices, densityMap, gridStep, totalOffset);
        % [mergedLines, used_pixels] = mergeSimilarLines(extendedPeaks, 5, densityMap, gridStep, totalOffset, firstOffset);
        updatedImage = removeUsedPixels(updatedImage, used_pixels);
    
        Mlines = [Mlines; pixelLines];
    
        % figure;
        % imshow(ones(size(updatedImage)));
        % hold on;
        % [row_, col_] = find(updatedImage);
        % plot(col_, row_, 'r.', 'MarkerSize', 2);
        % hold off;
        
        mergedLines = transformLinesBackToOriginal(pixelLines, gridStep, totalOffset);
        
        % disp(['Iter Time: ' num2str(toc)]);
    end
end