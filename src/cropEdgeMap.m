function [newEdgeMap, offset, position] = cropEdgeMap(edgeMap)
% cropEdgeMap - 裁剪二值化圖像，去除邊緣全黑區塊
%
% 語法:
%   [newEdgeMap, offset] = cropEdgeMap(edgeMap)
%
% 輸入:
%   edgeMap - 二值化圖像 (邏輯型或 0/1 值的矩陣)
%
% 輸出:
%   newEdgeMap - 裁剪後的二值化圖像，去除邊緣空白區域
%   offset - 裁剪偏移量 [x_min-1, y_min-1]，用於還原原始座標
%   position - 裁減映像在原影像位置 [min_x, min_y, max_x, max_y]
%
% 描述:
%   此函數先輸入二值化圖像，然後裁剪圖像以去除邊緣的全黑區域，
%   只保留有內容的部分。同時返回偏移量，方便還原到原始座標系。
    
    % 找出所有值為 1 的像素位置
    [y, x] = find(edgeMap);
    
    % 如果圖像中沒有任何像素為 1，返回空圖像
    if isempty(x) || isempty(y)
        newEdgeMap = false(0);
        offset = [0, 0];
        return;
    end
    
    % 計算有效區域的邊界
    min_x = min(x);
    min_y = min(y);
    max_x = max(x);
    max_y = max(y);
    
    % 裁剪圖像
    newEdgeMap = edgeMap(min_y:max_y, min_x:max_x);
    
    % 計算偏移量 (用於還原到原始座標系)
    offset = [min_x-1, min_y-1];

    position = [min_x, min_y, max_x, max_y];

end