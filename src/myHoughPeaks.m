function peaks = myHoughPeaks(H_count, Threshold)
    % 找出所有大於閾值的元素
    [rhoIndices, thetaIndices] = find(H_count > Threshold);
    % fprintf('rhoIndices:');
    % fprintf('%d ', rhoIndices)
    % fprintf('\nthetaIndices:');
    % fprintf('%d ', thetaIndices)

    % 初始化 peaks 結構陣列
    peaks = struct('rhoIdx', num2cell(rhoIndices), 'thetaIdx', num2cell(thetaIndices));
end

% function peaks = myHoughPeaks(H_count, Threshold)
%     % 初始化 peaks 結構陣列
%     peaks = [];
% 
%     % 遍歷 H 的累加矩陣
%     for i = 1:size(H_count, 1)  % 遍歷 rho 索引
%         for j = 1:size(H_count, 2)  % 遍歷 theta 索引
%             % 如果該 cell 的值大於 Threshold
%             if H_count(i, j) > Threshold
%                 % 儲存 rhoIdx 和 thetaIdx 到 peaks 中
%                 peaks = [peaks; struct('rhoIdx', i, 'thetaIdx', j)];
%             end
%         end
%     end
% end
