function refine_boundary_scan(run_id)
% 在连续合格区间的首次失效边界细化到1度；不假设更高角度一定单调失效。
s = summarize_boundary(run_id); extra = [];
for method = ["RD","CS","WK","BP"]
    m = s(string(s.method)==method,:); m = sortrows(m,'angle_deg');
    j = find(~m.all_probes_pass,1);
    if ~isempty(j) && j>1
        % 本实验首次失败低于15度，补齐此前整数角，排查粗网格内非单调失效。
        extra = [extra,1:min(15,m.angle_deg(j)-1),m.angle_deg(j-1)+1:m.angle_deg(j)-1]; %#ok<AGROW>
    end
end
extra = setdiff(unique(extra),s.angle_deg);
if ~isempty(extra), run_boundary_scan(run_id,extra); end
summarize_boundary(run_id);
end
