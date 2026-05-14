%% 0. 설정 ────────────────────────────────────────────────────────────────
fileIn  = "D:\race\기술 아이디어\test data\6060_regen70 데이터\6060bms데이터.csv";
fileOut = "D:\race\기술 아이디어\test data\6060_regen70 데이터\resampled_6060.xlsx";
want    = ["Current","Temp1","Temp2","Temp4"];   % 필요 열(대소문자 무시)

%% 1. CSV 로드 (헤더 보존) ────────────────────────────────────────────────
T = readtable(fileIn, "VariableNamingRule","preserve");

%% 2. 원하는 열 인덱스 찾기 ───────────────────────────────────────────────
colIdx = zeros(size(want));
for i = 1:numel(want)
    idx = find(contains(lower(T.Properties.VariableNames), lower(want(i))),1);
    if isempty(idx)
        error("열 '%s'을(를) 찾지 못했습니다.", want(i));
    end
    colIdx(i) = idx;
end

%% 3. 숫자 아닌 문자 제거 → double 변환 ───────────────────────────────────
for i = 1:numel(colIdx)
    varName = T.Properties.VariableNames{colIdx(i)};   % 열 이름

    s = string(T{:, varName});      % (1) 문자열화
    s = replace(s, ",", "");        % (2) 콤마 제거
    s = regexprep(s,"[^0-9\.\-Ee]","");  % (3) 단위·공백 삭제
    numCol = str2double(s);         % (4) double, 실패 시 NaN

    T.(varName) = numCol;           % ★ 점 인덱싱으로 통째로 교체 ★
end
Yorig = T{:, colIdx};               % (N×M) double 행렬

%% 4. A열 시간 문자열 → 초(sec) 변환 ──────────────────────────────────────
timeStr    = string(T{:,1});
unitFactor = struct('d',86400,'h',3600,'m',60,'s',1);
tSec       = zeros(numel(timeStr),1);

for k = 1:numel(timeStr)
    tok = regexp(timeStr(k),"(\d+)([dhms])","tokens");
    if isempty(tok),  continue,  end         % 파싱 실패 → 0 s
    total = 0;
    for p = 1:numel(tok)
        v = str2double(tok{p}{1});
        u = tok{p}{2};
        total = total + v*unitFactor.(u);
    end
    tSec(k) = total;
end
tSec = tSec - tSec(1);                       % 시작 0 s

%% 5. 시간 정렬·중복 제거 ────────────────────────────────────────────────
[tsSorted, ord]       = sort(tSec);
Ysorted               = Yorig(ord,:);
[tsUnique, firstIdx]  = unique(tsSorted,"stable");
Yunique               = Ysorted(firstIdx,:);

%% 6. 0.1 s 간격 선형 보간 ───────────────────────────────────────────────
dt      = 0.1;
tTarget = (0:dt:tsUnique(end)).';
Yinterp = interp1(tsUnique, Yunique, tTarget, "linear", "extrap");

%% 7. 결과 저장 ──────────────────────────────────────────────────────────
varNames = ["Time_s", matlab.lang.makeValidName(want)];
outTbl   = array2table([tTarget, Yinterp], "VariableNames", varNames);
writetable(outTbl, fileOut);

fprintf("✅ 완료! → %s (%d 행) 생성\n", fileOut, height(outTbl));  