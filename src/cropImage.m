function croppedImage = cropImage(image, bounds)
% cropImage - 根據邊界裁剪影像
%
% 語法:
%   croppedImage = cropImage(image, bounds)
%
% 輸入:
%   image - 要裁剪的影像 (可以是任何格式：RGB, 灰階或二值)
%   bounds - 裁剪邊界 [x_min, y_min, x_max, y_max]，其中 y 軸為 row
%
% 輸出:
%   croppedImage - 裁剪後的影像
%
% 描述:
%   此函數根據指定的邊界裁剪影像。邊界以 [x_min, y_min, x_max, y_max] 的形式給出，
%   其中 y 軸對應於影像的 row，x 軸對應於影像的 column。
%
% 範例:
%   img = imread('example.jpg');
%   bounds = [100, 50, 300, 200];  % [x_min, y_min, x_max, y_max]
%   croppedImg = cropImage(img, bounds);
%   imshow(croppedImg);

    % 檢查輸入參數
    if length(bounds) ~= 4
        error('裁剪邊界參數必須是 [x_min, y_min, x_max, y_max] 的形式');
    end
    
    % 解構邊界參數
    x_min = bounds(1);
    y_min = bounds(2);
    x_max = bounds(3);
    y_max = bounds(4);
    
    % 檢查邊界範圍是否有效
    [img_height, img_width, ~] = size(image);
    
    % 確保邊界在影像範圍內
    x_min = max(1, x_min);
    y_min = max(1, y_min);
    x_max = min(img_width, x_max);
    y_max = min(img_height, y_max);
    
    % 檢查裁剪區域是否有效
    if x_min > x_max || y_min > y_max
        error('無效的裁剪邊界：起始位置大於結束位置');
    end
    
    % 執行裁剪 (注意：在 MATLAB 中，第一個索引是 row (y)，第二個是 column (x))
    croppedImage = image(y_min:y_max, x_min:x_max);

end