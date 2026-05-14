%───────────────────────────────────────────────────────────────────────────
% interpolate_tctemp.m  (TCTemp3 열만 0.1 s 보간)
%───────────────────────────────────────────────────────────────────────────


%% 1. 설정 -----------------------------------------------------------------
fileIn  = "D:\race\기술 아이디어\test data\7060_regen70 데이터\Tc_temp_7060regen70.csv";
fileOut = "D:\race\기술 아이디어\test data\7060_regen70 데이터\resampled_7060tctemp.xlsx";
dt      = 0.1;                     % 보간 간격 [s]

%% 2. CSV 로드 (헤더 보존) --------------------------------------------------
T = readtable(fileIn, "VariableNamingRule","preserve");
% 파일을 먼저 읽어 둔 상태라고 가정

%% 3. TCTemp3 열 → 무조건 E열(5열)로 지정 -----------------------------------
idxTemp = 5;  % A:1, B:2, C:3, D:4, E:5
fprintf("✓ 보간 대상 열: %s (열 번호 %d)\n", T.Properties.VariableNames{idxTemp}, idxTemp);

%% 4. 시간 문자열 → 초(sec) 변환 -------------------------------------------
timeStr    = string(T{:,1});                        % A열(1열) 기준
unitFactor = struct('d',86400,'h',3600,'m',60,'s',1);
tSec       = zeros(numel(timeStr),1);
for k = 1:numel(timeStr)
    tok = regexp(timeStr(k),"(\d+)([dhms])","tokens");
    if isempty(tok), continue, end
    tSec(k) = sum(cellfun(@(x) str2double(x{1})*unitFactor.(x{2}), tok));
end
tSec = tSec - tSec(1);                              % 시작 0 s

%% 5. E열 값 숫자 변환 -------------------------------------------------------
s = string(T{:, idxTemp});
s = replace(s, ",", "");
s = regexprep(s,"[^0-9.\-Ee]","");                  % 영숫자만 남김
Temp = str2double(s);                               % double, NaN 허용


%% 6. 시간 정렬·중복 제거 ----------------------------------------------------
[tsSorted, ord]       = sort(tSec);
TempSorted            = Temp(ord);
[tsUnique, firstIdx]  = unique(tsSorted,"stable");
TempUnique            = TempSorted(firstIdx);

%% 7. 0.1 s 선형 보간 -------------------------------------------------------
tTarget  = (0:dt:tsUnique(end)).';
TempIntp = interp1(tsUnique, TempUnique, tTarget, "linear","extrap");

%% 8. 저장 ------------------------------------------------------------------
outTbl = table(tTarget, TempIntp, "VariableNames",{"Time_s","TCTemp3"});
writetable(outTbl, fileOut);
fprintf("✅ 완료! %s (%d 행) 저장\n", fileOut, height(outTbl));
