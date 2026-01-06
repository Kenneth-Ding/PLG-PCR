function [gradientX, gradientY, gradientMag, gradientDir, miMap] = computeExtendedNeighborhoodGradient(skeletonImage, neighborhoodSize)
% computeExtendedNeighborhoodGradient - 使用擴大鄰域計算細化線條梯度
%
% 輸入:
%   skeletonImage   - 已經細化的二值圖像，線條寬度為1像素
%   neighborhoodSize - 鄰域大小（預設為3，表示使用3x3鄰域）
%                      可以設為5表示5x5鄰域，7表示7x7鄰域等
%
% 輸出:
%   gradientX    - X方向梯度
%   gradientY    - Y方向梯度
%   gradientMag  - 梯度幅值
%   gradientDir  - 梯度方向(弧度)

% 預設鄰域大小
if nargin < 2
    neighborhoodSize = 3; % 預設為8-鄰域(3x3)
end

% 獲取圖像尺寸
[rows, cols] = size(skeletonImage);

% 初始化輸出
gradientX = zeros(size(skeletonImage));
gradientY = zeros(size(skeletonImage));
gradientMag = zeros(size(skeletonImage));
gradientDir = zeros(size(skeletonImage));
miMap = zeros(size(skeletonImage));

% 計算半鄰域大小
halfSize = floor(neighborhoodSize / 2);

% 對每個線條上的像素進行處理
for i = halfSize+1:rows-halfSize
    for j = halfSize+1:cols-halfSize
        % 只處理線條上的像素
        if skeletonImage(i, j) == 1
            % 擷取擴大鄰域
            neighborhood = skeletonImage(i-halfSize:i+halfSize, j-halfSize:j+halfSize);
            
            % 找出鄰域中的前景像素位置（相對中心點）
            [foregroundY, foregroundX] = find(neighborhood == 1);
            foregroundY = foregroundY - (halfSize + 1); % 轉換為相對坐標
            foregroundX = foregroundX - (halfSize + 1);
            
            % 去除中心點自身
            centerIdx = (foregroundY == 0 & foregroundX == 0);
            foregroundY(centerIdx) = [];
            foregroundX(centerIdx) = [];
            
            % 如果鄰域中沒有其他前景像素（孤立點），跳過處理
            if isempty(foregroundY)
                continue;
            end
            
            % 計算主方向向量 - 使用主成分分析(PCA)
            points = [foregroundX, foregroundY];
            
            % 根據前景像素數量選擇合適的方法
            numPoints = length(foregroundX);
            
            if numPoints >= 3
                % 使用PCA找出主方向 - 適用於有多個點的情況
                [coeff, ~, latent] = pca(points);
                principalDirection = coeff(:, 1)'; % 第一主成分方向
                
                % 計算梯度方向（與主方向垂直）
                gradVector = [-principalDirection(2), principalDirection(1)];
                mi = latent(2) / latent(1);
            elseif numPoints == 2
                % 兩點連線方向 - 簡單情況
                lineVector = [foregroundX(2) - foregroundX(1), foregroundY(2) - foregroundY(1)];
                lineDirection = lineVector / norm(lineVector);
                
                % 梯度方向與線條方向垂直
                gradVector = [-lineDirection(2), lineDirection(1)];
                mi = 0;
            else % numPoints == 1
                % 端點 - 梯度指向唯一的鄰域點
                gradVector = [foregroundX, foregroundY];
                gradVector = gradVector / norm(gradVector);
                mi = 0;
            end
            
            % 存儲梯度信息
            gradientX(i, j) = gradVector(1);
            gradientY(i, j) = gradVector(2);
            gradientMag(i, j) = 1; % 二值圖像中梯度幅值設為1
            gradientDir(i, j) = atan2(gradVector(2), gradVector(1));
            miMap(i, j) = mi;
        end
    end
end

end