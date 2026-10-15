function verify_translated_probe(run_id)
% 8度中心距离点另生成x=500m的真实回波，检查四种处理入口的坐标平移。
root = boundary_setup(); out = fullfile(root,'results','exp_002_airborne_squint_boundary',run_id);
records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
validation_path = fullfile(records,'translated_processing_validation.csv');
if exist(validation_path,'file')
    previous = readtable(validation_path); if height(previous)==4 && all(previous.pass), return; end
end
key = 'sq08_r30000'; cfg = airborne_squint_boundary(8,30000,500);
id = ['echo_002_shift500_sq08_',run_id];
path = fullfile(root,'data','simulated',id,'echo.mat');
if ~exist(path,'file'), generate_stripmap_probe(cfg,root,id); end
loaded = load(path,'meta'); meta = loaded.meta;
cache = prepare_squint_spectrum(path,fullfile(root,'scratch','exp_002',run_id,'shift500_spectrum.mat'));
rows = struct([]);
for method = {'BP','RD','CS','WK'}
    if strcmp(method{1},'BP')
        shifted = measure_probe(@(xy) bp_values(path,xy),meta,true,801);
        base = load(boundary_result_path(out,key,'BP'),'bp'); original = base.bp;
    else
        switch method{1}
            case 'RD', native = run_rd_squint(cache);
            case 'CS', native = run_cs_squint(cache);
            case 'WK', native = run_wk_squint(cache);
        end
        shifted = measure_probe(@(xy) sample_squint_image(native,xy),meta,false,801);
        base = load(boundary_result_path(out,key,method{1}),'measured'); original = base.measured;
        clear native
    end
    row.method = method{1}; row.translation_m = 500;
    row.max_irw_fraction_difference = max(abs([shifted.azimuth.irw_m/original.azimuth.irw_m,shifted.range.irw_m/original.range.irw_m]-1));
    row.max_side_difference_db = max(abs([shifted.azimuth.pslr_db-original.azimuth.pslr_db,shifted.range.pslr_db-original.range.pslr_db,shifted.azimuth.islr_db-original.azimuth.islr_db,shifted.range.islr_db-original.range.islr_db]));
    row.relative_position_difference_m = max(abs([shifted.error_x_m-original.error_x_m,shifted.error_y_m-original.error_y_m]));
    row.pass = row.max_irw_fraction_difference<1e-4 && row.max_side_difference_db<0.01 && row.relative_position_difference_m<1e-4;
    if isempty(rows), rows = row; else, rows(end+1) = row; end %#ok<AGROW>
    fprintf('TRANSLATED %s pass=%d\n',method{1},row.pass);
end
writetable(struct2table(rows),validation_path);
delete(cache.path); assert(all([rows.pass]),'沿航迹平移后的成像指标不一致。');
end
function z = bp_values(path,xy)
bp = run_bp_squint(path,xy,4); z = bp.values;
end
