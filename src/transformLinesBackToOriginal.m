function originalLines = transformLinesBackToOriginal(lines, gridStep, offset)
% 將多條經過縮放和平移的直線轉換回原始空間。
%
% 輸入：
%   lines     - Nx3 的矩陣，每列為一條線 [a b c]
%   gridStep  - scalar，縮放係數
%   offset    - 1x2 向量 [ox, oy]，平移量
%
% 輸出：
%   originalLines - Nx3 的矩陣，轉換後的直線參數

    % if size(lines, 1) == 2
    %     disp('2');
    % end
    ox = offset(1);
    oy = offset(2);
    s = gridStep;

    a = lines(:, 1);
    b = lines(:, 2);
    c = lines(:, 3);

    % a_new = a / s;
    % b_new = b / s;
    % c_new = c - (a * ox + b * oy);

    a_new = a ./ b;
    b_new = ones(size(b));
    c_new = (c - a .* ox - b .* oy) .* s ./ b;

    originalLines = [a_new, b_new, c_new];
end
