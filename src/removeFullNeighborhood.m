function cleanedImage = removeFullNeighborhood(binaryImage)
    % 創建一個與輸入影像相同大小的輸出影像
    cleanedImage = binaryImage;
    
    % 獲取影像尺寸
    [rows, cols] = size(binaryImage);
    
    % 掃描所有像素(忽略邊界)
    for i = 2:rows-1
        for j = 2:cols-1
            % 只處理二值為1的像素
            if binaryImage(i, j) == 1
                % 檢查3x3鄰域是否全為1
                neighborhood = binaryImage(i-1:i+1, j-1:j+1);
                if all(neighborhood(:) == 1)
                    % 如果九宮格內全為1，移除中心點
                    cleanedImage(i, j) = 0;
                end
            end
        end
    end
end

% function cleanedImage = removeFullNeighborhood(binaryImage)
%     % 建立全1的3x3卷積核
%     kernel = ones(3, 3);
% 
%     % 使用卷積計算每個點的鄰域和
%     neighborhoodSum = conv2(double(binaryImage), kernel, 'same');
% 
%     % 如果鄰域和等於9(表示九宮格都是1)，則將該點設為0
%     cleanedImage = binaryImage;
%     cleanedImage(neighborhoodSum == 9) = 0;
% end