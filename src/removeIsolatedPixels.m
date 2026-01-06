function outputImage = removeIsolatedPixels(inputImage)
% removeIsolatedPixels - 移除二值化圖像中孤立的像素點
%
% 語法:
%   outputImage = removeIsolatedPixels(inputImage)
%
% 輸入:
%   inputImage - 二值化圖像 (邏輯型或 0/1 值的矩陣)
%
% 輸出:
%   outputImage - 處理後的二值化圖像，其中孤立的 1 點被設為 0
%
% 描述:
%   此函數識別並移除二值化圖像中的孤立像素點。
%   孤立像素點定義為：值為 1 且其 8 鄰居都是 0 的像素點。
%
% 範例:
%   img = logical([0 0 0 0 0; 
%                  0 1 0 0 0; 
%                  0 0 0 1 0; 
%                  0 0 0 0 0; 
%                  0 0 1 0 0]);
%   result = removeIsolatedPixels(img);

    % 確保輸入圖像是二值化的
    inputImage = logical(inputImage);
    
    % 建立輸出圖像的副本
    outputImage = inputImage;
    
    % 獲取圖像尺寸
    [rows, cols] = size(inputImage);
    
    % 尋找所有值為 1 的像素位置
    [y, x] = find(inputImage);
    
    % 處理每個值為 1 的像素
    for i = 1:length(y)
        row = y(i);
        col = x(i);
        
        % 檢查是否為圖像邊界
        if row > 1 && row < rows && col > 1 && col < cols
            % 獲取 8 鄰居
            neighborhood = inputImage(row-1:row+1, col-1:col+1);
            
            % 計算除了中心點外的鄰居和
            neighborSum = sum(neighborhood(:)) - 1; % 減去中心點自身
            
            % 如果所有鄰居都是 0，則設置當前點為 0
            if neighborSum <= 1   % == 0
                outputImage(row, col) = 0;
            end
        else
            % 處理邊界情況
            neighborSum = 0;
            
            % 檢查所有 8 個方向的鄰居
            for dr = -1:1
                for dc = -1:1
                    % 跳過中心點
                    if dr == 0 && dc == 0
                        continue;
                    end
                    
                    % 計算鄰居的位置
                    r = row + dr;
                    c = col + dc;
                    
                    % 確保鄰居在圖像範圍內
                    if r >= 1 && r <= rows && c >= 1 && c <= cols
                        neighborSum = neighborSum + double(inputImage(r, c));
                    end
                end
            end
            
            %%%%%%%% 如果所有鄰居都是 0，則設置當前點為 0
            if neighborSum <= 1
                outputImage(row, col) = 0;
            end
        end
    end
end