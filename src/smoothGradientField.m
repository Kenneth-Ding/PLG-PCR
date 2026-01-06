function [smoothGradX, smoothGradY, smoothGradMag, smoothGradDir] = smoothGradientField(gradX, gradY, gradMag, gradDir, skeletonImg, windowSize)
% smoothGradientField - 平滑細化線條的梯度場
%
% 輸入:
%   gradX, gradY    - 原始梯度場的X和Y分量
%   gradMag, gradDir - 原始梯度幅值和方向
%   skeletonImg     - 細化的二值圖像（線條寬度為1像素）
%   windowSize      - 平滑窗口大小（預設為5）
%
% 輸出:
%   smoothGradX, smoothGradY - 平滑後的梯度X和Y分量
%   smoothGradMag  - 平滑後的梯度幅值
%   smoothGradDir  - 平滑後的梯度方向(弧度)

% 預設窗口大小
if nargin < 6
    windowSize = 5;
end

% 獲取圖像尺寸
[rows, cols] = size(skeletonImg);

% 初始化輸出
smoothGradX = zeros(size(gradX));
smoothGradY = zeros(size(gradY));
smoothGradMag = zeros(size(gradMag));
smoothGradDir = zeros(size(gradDir));

% 計算半窗口大小
halfWindow = floor(windowSize / 2);

% 對每個線條上的像素進行處理
for i = 1:rows
    for j = 1:cols
        % 只處理線條上的像素
        if skeletonImg(i, j) == 1
            % 初始化加權和
            weightedSumX = 0;
            weightedSumY = 0;
            totalWeight = 0;
            
            % 在窗口內搜索其他線條像素
            for ni = max(1, i-halfWindow):min(rows, i+halfWindow)
                for nj = max(1, j-halfWindow):min(cols, j+halfWindow)
                    % 只考慮線條上的像素
                    if skeletonImg(ni, nj) == 1
                        % 計算距離權重（距離越近權重越大）
                        dist = sqrt((ni-i)^2 + (nj-j)^2);
                        
                        % 高斯權重函數
                        weight = exp(-dist^2 / (2 * (halfWindow/2)^2));
                        
                        % 累積加權梯度
                        weightedSumX = weightedSumX + gradX(ni, nj) * weight;
                        weightedSumY = weightedSumY + gradY(ni, nj) * weight;
                        totalWeight = totalWeight + weight;
                    end
                end
            end
            
            % 計算加權平均梯度
            if totalWeight > 0
                smoothGradX(i, j) = weightedSumX / totalWeight;
                smoothGradY(i, j) = weightedSumY / totalWeight;
            else
                % 如果窗口內沒有其他線條像素，保持原始梯度
                smoothGradX(i, j) = gradX(i, j);
                smoothGradY(i, j) = gradY(i, j);
            end
            
            % 計算新的梯度幅值和方向
            smoothGradMag(i, j) = sqrt(smoothGradX(i, j)^2 + smoothGradY(i, j)^2);
            smoothGradDir(i, j) = atan2(smoothGradY(i, j), smoothGradX(i, j));
        end
    end
end

% 標準化平滑後的梯度向量
nonZeroIdx = (smoothGradMag > 0);
if any(nonZeroIdx(:))
    smoothGradX(nonZeroIdx) = smoothGradX(nonZeroIdx) ./ smoothGradMag(nonZeroIdx);
    smoothGradY(nonZeroIdx) = smoothGradY(nonZeroIdx) ./ smoothGradMag(nonZeroIdx);
    smoothGradMag(nonZeroIdx) = 1; % 重置為單位梯度
end

end