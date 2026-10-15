function verify_boundary_numerics(run_id,angles)
% 验证实际回波BP插值收敛及条带平移协变；只检查与本研究有关的科学风险。
if nargin < 2, angles = [0,8,70]; end
root = boundary_setup();
out = fullfile(root,'results','exp_002_airborne_squint_boundary',run_id);
records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
validation_path = fullfile(records,'numerical_validation.csv');
if exist(validation_path,'file')
    rows = table2struct(readtable(validation_path)); rows = rows(:).';
else
    rows = struct([]);
end
for angle = angles
    for range = [25000,30000,35000]
        key = sprintf('sq%02d_r%05d',angle,range);
        if ~isempty(rows) && any([rows.angle_deg]==angle & [rows.closest_range_m]==range), continue; end
        path = boundary_result_path(out,key,'BP');
        if ~exist(path,'file'), continue; end
        saved = load(path,'bp','meta'); baseline = saved.bp; meta = saved.meta;
        dataset_path = fullfile(root,'data','simulated',meta.id,'echo.mat');
        finer = measure_probe(@(xy) bp_values(dataset_path,xy,8),meta,true,801);
        row.angle_deg = angle; row.closest_range_m = range;
        row.irw_change_x_fraction = finer.azimuth.irw_m/baseline.azimuth.irw_m-1;
        row.irw_change_y_fraction = finer.range.irw_m/baseline.range.irw_m-1;
        row.pslr_change_x_db = finer.azimuth.pslr_db-baseline.azimuth.pslr_db;
        row.pslr_change_y_db = finer.range.pslr_db-baseline.range.pslr_db;
        row.islr_change_x_db = finer.azimuth.islr_db-baseline.azimuth.islr_db;
        row.islr_change_y_db = finer.range.islr_db-baseline.range.islr_db;
        row.converged = max(abs([row.irw_change_x_fraction,row.irw_change_y_fraction]))<0.01 ...
            && max(abs([row.pslr_change_x_db,row.pslr_change_y_db,row.islr_change_x_db,row.islr_change_y_db]))<0.2;
        % 独立重算平移后的几何距离和照射门，不能只比较相同数组的副本。
        translated = airborne_squint_boundary(angle,range,500);
        g = stripmap_probe_geometry(translated);
        row.translation_max_range_error_m = max(abs(g.slant_range_m-meta.geometry.slant_range_m));
        row.translation_gate_identical = isequal(g.illuminated,meta.geometry.illuminated);
        row.translation_pass = row.translation_max_range_error_m<1e-8 && row.translation_gate_identical;
        if isempty(rows), rows = row; else, rows(end+1) = row; end %#ok<AGROW>
        fprintf('VERIFY %s BP converged=%d translation=%d\n',key,row.converged,row.translation_pass);
    end
end
if ~isempty(rows)
    writetable(struct2table(rows),validation_path);
    assert(all([rows.converged]) && all([rows.translation_pass]),'BP插值或平移协变尚未验证。');
end
end
function z = bp_values(path,xy,up)
r = run_bp_squint(path,xy,up); z = r.values;
end
