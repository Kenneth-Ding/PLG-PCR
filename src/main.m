clc 
clear,close all;

sourcePlyFile = 'E:\Dataset\Boardroom\raw_scans_boardroom\scan_01.ply';
targetPlyFile = 'E:\Dataset\Boardroom\raw_scans_boardroom\scan_02.ply';
groundTruthDir = 'E:\Dataset\Boardroom\raw_scans_boardroom\3-GroundTruth\1-2\transformation.txt';

gridStep = 0.05;
pr = 0.025;

PCOBJ1 = pcread(sourcePlyFile); 
PCOBJ2 = pcread(targetPlyFile); 

fid = fopen(groundTruthDir, 'r');
D = textscan(fid, '%f%f%f%f');
fclose(fid);
Ttrue = [D{1} D{2} D{3} D{4}];

linepoints1 = filterLinePoints(PCOBJ1, gridStep);
linepoints2 = filterLinePoints(PCOBJ2, gridStep);

[Mlines1, Slinepoint1, edgeMap1, densityMap1, gradientAngleMap1, totalOffset1] = detectLinesFromPointCloud(PCOBJ1, gridStep);
[Mlines2, Slinepoint2, edgeMap2, densityMap2, gradientAngleMap2, totalOffset2] = detectLinesFromPointCloud(PCOBJ2, gridStep);

[yIndices1, xIndices1] = find(edgeMap1);
[meanDist1, stdDist1, meanAngle1, stdAngle1, centroidX1, centroidY1, pointCount1] = ...
    calculateWeightedLineStats(Mlines1, xIndices1, yIndices1, densityMap1, gradientAngleMap1, 3);
linesCentroid1 = [centroidX1, centroidY1];
[lineGroups1, ~] = clusterLinesBySlope(Mlines1(:, 1));
lineGroupsInfo1 = analyzeLineGroupGeometry(Mlines1, lineGroups1, linesCentroid1, pointCount1);
linesType1 = classifyLine(meanDist1, stdDist1, meanAngle1, stdAngle1);

[yIndices2, xIndices2] = find(edgeMap2);
[meanDist2, stdDist2, meanAngle2, stdAngle2, centroidX2, centroidY2, pointCount2] = ...
    calculateWeightedLineStats(Mlines2, xIndices2, yIndices2, densityMap2, gradientAngleMap2, 3);
linesCentroid2 = [centroidX2, centroidY2];
[lineGroups2, ~] = clusterLinesBySlope3(Mlines2(:, 1));
lineGroupsInfo2 = analyzeLineGroupGeometry(Mlines2, lineGroups2, linesCentroid2, pointCount2);
linesType2 = classifyLine(meanDist2, stdDist2, meanAngle2, stdAngle2);

orgMLines1 = transformLinesBackToOriginal(Mlines1, gridStep, totalOffset1);
orgMLines2 = transformLinesBackToOriginal(Mlines2, gridStep, totalOffset2);
% 
srcPCInfo = struct(                     ...
    'points2D', Slinepoint1,            ...
    'linesPoints', linepoints1,         ...
    'lineGroups', lineGroups1,          ...
    'lineGroupsInfo', lineGroupsInfo1,  ...
    'lines', Mlines1,                   ...
    'orgLines', orgMLines1,             ...
    'linesType', linesType1             ...
);

tgtPCInfo = struct(                     ...
    'points2D', Slinepoint2,            ...
    'linesPoints', linepoints2,         ...
    'lineGroups', lineGroups2,          ...
    'lineGroupsInfo', lineGroupsInfo2,  ...
    'lines', Mlines2,                   ...
    'orgLines', orgMLines2,             ...
    'linesType', linesType2             ...
);

[scoreMatrix, bestLinePairsMatrix] = createAllGroupMatchesScore(srcPCInfo, tgtPCInfo);
highestScoreGroupPairs = findGroupPairs(srcPCInfo, tgtPCInfo, scoreMatrix);
bestRegistration = registration2DbyLineGroups(srcPCInfo, tgtPCInfo, highestScoreGroupPairs, bestLinePairsMatrix);

tSrcPoints = bestRegistration.transformedPoints;
tgtPoints = linepoints2;

[idx2, dist2]=knnsearch(tgtPoints,tSrcPoints,'k',1);
idoverlap1=find(dist2<pr);
overlappoint=tSrcPoints(idoverlap1,:);
PC1 = pcdownsample(PCOBJ1, 'gridAverage', pr).Location;
PC2 = pcdownsample(PCOBJ2, 'gridAverage', pr).Location;

Mtz=[];
for j=1:50
    Sidx=randperm(length(overlappoint),1);
    [idxx1 distt1]=rangesearch(PC1(:,1:2),linepoints1(idoverlap1(Sidx),:),2*pr);
    KNN1=PC1(idxx1{1},:);
    [idxx2 distt2]=rangesearch(PC2(:,1:2),overlappoint(Sidx,:),2*pr);
    KNN2=PC2(idxx2{1},:);
    zmin1=min(KNN1(:,3));
    zmin2=min(KNN2(:,3));
    tz=zmin2-zmin1;
    Mtz=[Mtz;tz 0];
end
MStz=[];
for i=1:1000
    seed=Mtz(1,:);
    Mtz(1,:)=[];
    for j=1:1000
        [idxtz disttz]=knnsearch(Mtz,seed,'k',1);
        [mi id]=min(disttz);
        if mi<0.2*pr        
            seed=[seed;Mtz(idxtz(id),:)];
            Mtz(idxtz(id),:)=[];
        else
            break;
        end
    end
    [h l]=size(seed);
    Stz=[mean(seed(:,1)) h];
    MStz=[MStz;Stz];
    if isempty(Mtz)
        break
    end
end
[ma idStz]=max(MStz(:,2));
tz=MStz(idStz,1);

trans = eye(4);
trans(1:3, 1:3) = [bestRegistration.R' zeros(2,1); zeros(1,2) 1];
trans(1:3, 4) = [bestRegistration.t'; tz];

Rtrue = Ttrue(1:3,1:3);
ttrue = Ttrue(1:3,4);
R = trans(1:3, 1:3);     
t = trans(1:3, 4);      

errorR = real(acos((trace(Rtrue * inv(R)) - 1) / 2) * (180 / pi));  
errorH = norm(ttrue(1:2) - t(1:2));                                 
errorV = abs(ttrue(3) - t(3));                                      
errorT = norm(ttrue - t);                                           

fprintf('\n=== Registration Results ===\n');
fprintf('Rotation Error: %.3f degrees\n', errorR);
fprintf('Horizontal Translation Error: %.3f\n', errorH);
fprintf('Vertical Translation Error: %.3f\n', errorV);
fprintf('Total Translation Error: %.3f\n', errorT);