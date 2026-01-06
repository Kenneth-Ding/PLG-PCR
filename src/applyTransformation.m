function transformedPoints = applyTransformation(points, R, t)
    % 將變換應用於點集
    % points: N x 2 矩陣，每行是一個點的[x, y]座標
    % R: 2 x 2 旋轉矩陣
    % t: 1 x 2 平移向量
    
    % 應用旋轉和平移
    transformedPoints = (points * R) + repmat(t, size(points, 1), 1);
end