function angleDifference = slopeAngleDifference(m1, m2)
    % 檢查是否有垂直線（斜率無窮大，在MATLAB中可用Inf表示）
    if isinf(m1) || isinf(m2)
        if isinf(m1) && isinf(m2)
            % 兩條線都是垂直的，它們平行，角度為0
            angle_deg = 0;
        else
            % 一條線垂直，一條不垂直，角度為90度個鬼啦
            m_ = min(m1, m2);
            angle_deg = 90 - atand(m_);
        end
    else
        % 使用標準公式計算角度
        angle_rad = abs(atan(abs((m2 - m1) / (1 + m1 * m2))));
        angle_deg = angle_rad * 180 / pi;
    end
    
    % 返回角度差異
    angleDifference = angle_deg;
end
