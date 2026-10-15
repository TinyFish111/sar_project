function write_boundary_report(run_id)
root = boundary_setup();
records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
t = readtable(fullfile(records,'metrics.csv'),'TextType','string');
angles = unique(t.angle_deg); rows = struct([]);
for tolerance = [1,2,3]
 for center_only = [false,true]
  for method = ["RD","CS","WK","BP"]
    passes = false(size(angles));
    for j = 1:numel(angles)
        m = t(t.angle_deg==angles(j) & t.method==method,:);
        if center_only, m = m(m.closest_range_m==30000,:); end
        width = max(abs([m.irw_ratio_x,m.irw_ratio_y]-1),[],2)<=0.15;
        side = max([m.pslr_loss_x_db,m.pslr_loss_y_db,m.islr_loss_x_db,m.islr_loss_y_db],[],2)<=tolerance;
        position = max([m.position_error_x_cells,m.position_error_y_cells],[],2)<=0.5;
        passes(j) = height(m)==(3-2*center_only) && all(m.valid & width & side & position);
    end
    fail = find(~passes,1);
    row.method = char(method); row.side_tolerance_db = tolerance; row.center_only = center_only;
    if isempty(fail)
        row.last_continuous_sampled_pass_deg = max(angles); row.first_fail_deg = NaN; row.verified_to_70 = true;
    elseif fail==1
        row.last_continuous_sampled_pass_deg = NaN; row.first_fail_deg = angles(fail); row.verified_to_70 = false;
    else
        row.last_continuous_sampled_pass_deg = angles(fail-1); row.first_fail_deg = angles(fail); row.verified_to_70 = false;
    end
    if isempty(rows), rows = row; else, rows(end+1) = row; end %#ok<AGROW>
  end
 end
end
writetable(struct2table(rows),fullfile(records,'boundary_and_sensitivity.csv'));
criteria = struct([]);
for method = ["RD","CS","WK","BP"]
 for criterion = ["IRW","PSLR","ISLR","position"]
    passes = false(size(angles));
    for j = 1:numel(angles)
        m = t(t.angle_deg==angles(j) & t.method==method,:);
        switch criterion
            case "IRW", good = max(abs([m.irw_ratio_x,m.irw_ratio_y]-1),[],2)<=0.15;
            case "PSLR", good = max([m.pslr_loss_x_db,m.pslr_loss_y_db],[],2)<=2;
            case "ISLR", good = max([m.islr_loss_x_db,m.islr_loss_y_db],[],2)<=2;
            case "position", good = max([m.position_error_x_cells,m.position_error_y_cells],[],2)<=0.5;
        end
        passes(j) = height(m)==3 && all(m.valid & good);
    end
    ix = find(~passes,1); item.method = char(method); item.criterion = char(criterion);
    if isempty(ix)
        item.last_sampled_pass_deg = max(angles); item.first_fail_deg = NaN;
    elseif ix==1
        item.last_sampled_pass_deg = NaN; item.first_fail_deg = angles(ix);
    else
        item.last_sampled_pass_deg = angles(ix-1); item.first_fail_deg = angles(ix);
    end
    if isempty(criteria), criteria = item; else, criteria(end+1) = item; end %#ok<AGROW>
 end
end
writetable(struct2table(criteria),fullfile(records,'criterion_failure_brackets.csv'));
main = struct2table(rows); main = main(main.side_tolerance_db==2 & ~main.center_only,:);
method_names = string(main.method);
f = fopen(fullfile(records,'conclusions.md'),'w','n','UTF-8'); assert(f>=0); clean = onCleanup(@() fclose(f)); %#ok<NASGU>
fprintf(f,'# 本次实测边界\n\n运行：%s。实际角网格：%s deg。三种距离位置分别激励，另验证三方位位置的平移协变。\n\n',run_id,mat2str(angles'));
fprintf(f,'固定最近斜距30km、10km最近斜距带、1km方位测试段、1m有效天线矩形角域照射，平地stop-go理想回波。\n\n');
fprintf(f,'判据：两向IRW与同角同位置参照相差<=15%%；PSLR/ISLR恶化<=2dB；定位误差<=0.5个参照分辨率单元。BP另对连续有限LFM解析PSF校验。\n\n');
fprintf(f,'| 方法 | 最大连续已测合格角 / deg | 首次不合格角 / deg | 解释 |\n|---|---:|---:|---|\n');
for k = 1:height(main)
    if main.verified_to_70(k), explanation = '已验证至70deg，尚未找到上限'; else, explanation = '本场景及本实现的经验边界'; end
    if isnan(main.first_fail_deg(k)), first_failure = '未观察到'; else, first_failure = num2str(main.first_fail_deg(k)); end
    fprintf(f,'| %s | %g | %s | %s |\n',method_names(k),main.last_continuous_sampled_pass_deg(k),first_failure,explanation);
end
fprintf(f,'\n边界由所有探测点共同决定。中心点可能在更高角度通过，且某些指标随角度非单调；详见angle_summary.csv和boundary_and_sensitivity.csv。\n\n');
fprintf(f,'各判据单独首次失败的区间见criterion_failure_brackets.csv：旁瓣不合格不等于完全无法形成主瓣。未经另外细化的区间仍按实际角网格报告。\n\n');
fprintf(f,'1dB/3dB旁瓣容差只作阈值敏感性分析，未在其每个首次失败区间另行全部细化。不能将离散网格上的首次失败当作严格解析角度极限。\n\n');
fprintf(f,'## 数值与复现核查\n\n');
validation_names = {'numerical_validation.csv','wk_numerical_validation.csv','boundary_sampling_validation.csv','translated_processing_validation.csv','final_source_reproduction.csv'};
validation_labels = {'BP距离插值加密与几何平移','70deg最远距WK抽头及网格加密','首次边界Fr从120到240MHz','独立平移回波的四法处理','最终源文件低角度复现'};
for j = 1:numel(validation_names)
    file = fullfile(records,validation_names{j});
    if ~exist(file,'file'), continue; end
    checked = readtable(file);
    if ismember('converged',checked.Properties.VariableNames), success = all(checked.converged); else, success = all(checked.pass); end
    fprintf(f,'- %s：%d项，全部通过=%d（%s）。\n',validation_labels{j},height(checked),success,validation_names{j});
end
fprintf(f,'\nPSF主瓣检验：BP相对连续有限LFM解析参照的最大宽度差异为%.3f%%。BP采用解析带限LFM匹配，相比有限时宽信号仍有小的模型/匹配差异。\n\n',100*max(abs([t.irw_ratio_x(t.method=="BP");t.irw_ratio_y(t.method=="BP")]-1)));
fprintf(f,'原始数据：data/simulated/echo_002_*_%s/echo.mat。复数局部图与剖面：results/exp_002_airborne_squint_boundary/%s/<方法>/。各方法图片在其figures/，跨方法汇总在运行目录figures/。\n\n',run_id,run_id);
fprintf(f,'本实验不包括分布式强弱目标串扰、真实天线电子扫描损失、运动误差、噪声、地球曲率或连续全幅聚焦证明。代码版本见source_manifest.json及completion.md。\n');
end
