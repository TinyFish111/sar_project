function audit_boundary_outputs(run_id)
% 收尾数据门禁：逐份读取实际MAT，核查维度、时轴、轨迹、距离和复样本。
root = boundary_setup(); records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
folders = dir(fullfile(root,'data','simulated',['echo_002_*',run_id])); folders = folders([folders.isdir]);
rows = struct([]);
for k = 1:numel(folders)
    path = fullfile(folders(k).folder,folders(k).name,'echo.mat');
    saved = load(path,'meta'); m = saved.meta; validate_stripmap_probe(path,m);
    dt = 1/m.radar.range_sample_rate_hz; deta = 1/m.radar.prf_hz;
    fast_error = max(abs(diff(m.fast_time_s)-dt)); slow_error = max(abs(diff(m.slow_time_s)-deta));
    assert(fast_error<dt*1e-7 && slow_error<deta*1e-9);
    xyz = m.geometry.platform_position_m;
    difference = xyz-m.targets.position_m;
    predicted_range = sqrt(sum(difference.^2,2));
    range_error = max(abs(predicted_range-m.geometry.slant_range_m));
    assert(range_error<1e-7 && all(isfinite(xyz(:))));
    velocity_error = max(abs(diff(xyz(:,1))./diff(m.slow_time_s)-m.configuration.geometry.speed_mps));
    assert(velocity_error<1e-6);
    active = m.geometry.illuminated;
    arrival = 2*m.geometry.slant_range_m(active)/m.configuration.c_mps;
    contained = all(arrival-m.radar.pulse_duration_s/2>=m.fast_time_s(1)) && all(arrival+m.radar.pulse_duration_s/2<=m.fast_time_s(end));
    assert(contained);
    row.dataset_id = m.id; row.schema_version = m.schema_version;
    row.slow_samples = numel(m.slow_time_s); row.fast_samples = numel(m.fast_time_s);
    row.fast_interval_error_s = fast_error; row.slow_interval_error_s = slow_error;
    row.range_geometry_error_m = range_error; row.velocity_error_mps = velocity_error;
    row.chirp_window_complete = contained; row.sample_phase_check = true;
    if isempty(rows), rows = row; else, rows(end+1) = row; end %#ok<AGROW>
end
writetable(struct2table(rows),fullfile(records,'raw_dataset_checks.csv'));
summary.raw_datasets_checked = numel(rows);
summary.metric_records = height(readtable(fullfile(records,'metrics.csv')));
summary.nine_position_records = height(readtable(fullfile(records,'nine_position_metrics.csv')));
summary.png_figures = numel(dir(fullfile(root,'results','exp_002_airborne_squint_boundary',run_id,'**','*.png')));
summary.chinese_font = sar_chinese_font(); summary.actual_matlab_release = version('-release');
summary.checked_at = char(datetime('now','TimeZone','Asia/Shanghai','Format','yyyy-MM-dd HH:mm:ss Z'));
summary.all_checks_passed = true;
f = fopen(fullfile(records,'artifact_audit.json'),'w','n','UTF-8'); assert(f>=0); clean = onCleanup(@() fclose(f));
fprintf(f,'%s\n',jsonencode(summary,'PrettyPrint',true));
fprintf('ARTIFACT_AUDIT %d raw datasets, %d metric records, %d figures passed\n',summary.raw_datasets_checked,summary.metric_records,summary.png_figures);
end
