function [H, H_count, maxVotes] = myHoughTransform(filteredImage, densityMap)
    % 获取图像尺寸
    [rows, cols] = size(filteredImage);
    % 计算图像对角线长度
    D = sqrt(rows^2 + cols^2);
    % disp('D是');
    % disp(D);
    % ρ的范围从 -D 到 D
    rho = -ceil(D):2:ceil(D);   %2.5
    % θ的范围从 -90 到 85 度，每5度一个步长
    theta = -90:1:89;
    % 将θ轉換為弧度
    thetaRad = deg2rad(theta);
    % 初始化累加器H，存储索引
    H = cell(length(rho), length(theta));
    % 初始化投票計數矩陣
    H_count = zeros(length(rho), length(theta));

    % disp(['Max density value: ', num2str(max(densityMap(:)))]);
    % disp(['Min density value: ', num2str(min(densityMap(:)))]);


    % 找到非零像素（边缘点）
    [yIndices, xIndices] = find(filteredImage);
    % 对每个边缘点进行处理
    for idx = 1:length(xIndices)
        x = xIndices(idx);
        y = yIndices(idx);
        densityValue = densityMap(y, x);
        for thetaIdx = 1:length(thetaRad)
            th = thetaRad(thetaIdx);

            r = x * cos(th) + y * sin(th);
            % 使用最接近的 rho 值，而不是精确匹配
            [~, rhoIdx] = min(abs(rho - r));  % 找到最接近的 rho 值的索引

            if ~isempty(rhoIdx)
                % 将点的索引（而不是具体的坐标）存储到 H 中
                if isempty(H{rhoIdx, thetaIdx})
                    H{rhoIdx, thetaIdx} = idx;  % 存储点的索引
                else
                    % 将点的索引添加到该 cell 中
                    H{rhoIdx, thetaIdx} = [H{rhoIdx, thetaIdx}, idx];
                end
                % 增加該位置的投票數
                % H_count(rhoIdx, thetaIdx) = H_count(rhoIdx, thetaIdx) + 1;
                H_count(rhoIdx, thetaIdx) = H_count(rhoIdx, thetaIdx) + densityValue;
            end
        end
    end

    % disp(['Max value in H_count: ', num2str(max(H_count(:)))]);
    % disp(['Min value in H_count: ', num2str(min(H_count(:)))]);
    [maxVotes, linearIndex] = max(H_count(:));


    % 找到 H_count 中的最大值和索引
    
    % [maxRhoIdx, maxThetaIdx] = ind2sub(size(H_count), linearIndex);
    % 
    % 
    % % 對應的 rho 和 theta 值
    % maxRho = rho(maxRhoIdx);
    % maxTheta = theta(maxThetaIdx);
    % 
    % % 顯示結果
    % disp(['最大投票數為: ', num2str(maxVotes)]);
    % disp(['最大投票數對應的 rho 值: ', num2str(maxRho)]);
    % disp(['最大投票數對應的 theta 值: ', num2str(maxTheta)]);
end