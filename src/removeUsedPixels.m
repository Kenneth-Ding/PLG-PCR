function updatedImage = removeUsedPixels(image, used_pixels)
    updatedImage = image;
    
    % 將所有使用過的像素點設為0
    for i = 1:size(used_pixels, 1)
        x = used_pixels(i, 1);
        y = used_pixels(i, 2);
        % 確保座標在圖像範圍內
        if x > 0 && x <= size(image, 2) && y > 0 && y <= size(image, 1)
            updatedImage(y, x) = 0;
        end
    end
end