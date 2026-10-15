function run_id = run_boundary_scan(run_id, angles_override)
% 正式批处理，可用同一run_id恢复未完成任务。正式数据文件从不覆盖。
% 每个距离位置独立激励；匀速条带系统沿航迹平移不变，因此三方位位置共享
% 等价冲激响应。全场景通过取近/中/远三类最差值，另作平移数值检查。
root = boundary_setup(); cfg = boundary_config();
if nargin < 1 || isempty(run_id)
    run_id = ['run_',char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))];
end
if nargin > 1, cfg.angles_deg = angles_override; end
out = fullfile(root,'results','exp_002_airborne_squint_boundary',run_id);
records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
work = fullfile(root,'scratch','exp_002',run_id);
for folder = {out,records,work}
    if ~exist(folder{1},'dir'), mkdir(folder{1}); end
end
state_path = fullfile(out,'state.mat');
if exist(state_path,'file')
    loaded = load(state_path,'rows','cases'); rows = loaded.rows; cases = loaded.cases;
else
    rows = struct([]); cases = struct([]);
end
if ~exist(fullfile(records,'experiment_config.json'),'file')
    write_json(fullfile(records,'experiment_config.json'),boundary_config());
end
request_name = ['scan_request_',char(datetime('now','Format','yyyyMMdd_HHmmss_SSS')),'.json'];
write_json(fullfile(records,request_name),cfg);
fprintf('RUN_ID=%s\n',run_id);
for angle = cfg.angles_deg
    for range = cfg.closest_ranges_m
        key = sprintf('sq%02d_r%05d',angle,range);
        completed = fullfile(out,[key,'_complete.mat']);
        if exist(completed,'file'), continue; end
        fprintf('START %s %s\n',key,char(datetime('now')));
        generation = airborne_squint_boundary(angle,range,0);
        dataset_id = sprintf('echo_002_%s_%s',key,run_id);
        dataset_path = fullfile(root,'data','simulated',dataset_id,'echo.mat');
        if ~exist(dataset_path,'file')
            generate_stripmap_probe(generation,root,dataset_id);
        end
        loaded = load(dataset_path,'meta'); meta = loaded.meta;
        case_record.key = key; case_record.dataset_id = dataset_id;
        case_record.dataset_path = dataset_path;
        case_record.angle_deg = angle; case_record.closest_range_m = range;
        case_record.prf_hz = generation.radar.prf_hz;
        case_record.samples = meta.checks.size_slow_fast;
        case_record.illumination_s = meta.checks.illumination_time_s;
        case_record.provenance = meta.provenance;
        write_json(fullfile(records,[key,'_generation.json']),case_record);
        existing = false(1,numel(rows));
        if ~isempty(rows), existing = [rows.angle_deg]==angle & [rows.closest_range_m]==range; end
        if sum(existing)==4
            if isempty(cases), cases = case_record; else, cases(end+1) = case_record; end %#ok<AGROW>
            save(completed,'case_record'); checkpoint();
            continue;
        end
        bp_path = boundary_result_path(out,key,'BP');
        if exist(bp_path,'file')
            saved = load(bp_path,'bp','theory','bpcheck'); bp = saved.bp; theory = saved.theory; bpcheck = saved.bpcheck;
        else
            timer = tic;
            bp = measure_probe(@(xy) bp_values(dataset_path,xy,cfg.bp_range_upsampling),meta,true,cfg.cut_samples);
            bp.elapsed_s = toc(timer);
            theory = measure_probe(@(xy) ideal_stripmap_psf(meta,xy),meta,true,cfg.cut_samples);
            bpcheck = compare_probe(bp,theory,cfg.threshold);
            save(bp_path,'bp','theory','bpcheck','meta','-v7.3');
        end
        item = pack_row(angle,range,'BP',bp,bpcheck,bp.elapsed_s);
        rows = replace_row(rows,item);
        fprintf('BP %s pass=%d IRW=%.4f/%.4f PSLR=%.2f/%.2f %.1fs\n',key,bpcheck.pass,bp.azimuth.irw_m,bp.range.irw_m,bp.azimuth.pslr_db,bp.range.pslr_db,bp.elapsed_s);
        cache = prepare_squint_spectrum(dataset_path,fullfile(work,[key,'_spectrum.mat']));
        for method = cfg.methods
            method_path = boundary_result_path(out,key,method{1});
            if exist(method_path,'file')
                saved = load(method_path,'measured','check');
                rows = replace_row(rows,pack_row(angle,range,method{1},saved.measured,saved.check,saved.measured.elapsed_s));
                checkpoint(); continue;
            end
            switch method{1}
                case 'RD', native = run_rd_squint(cache);
                case 'CS', native = run_cs_squint(cache);
                case 'WK', native = run_wk_squint(cache);
            end
            measured = measure_probe(@(xy) sample_squint_image(native,xy),meta,false,cfg.cut_samples);
            measured.elapsed_s = native.elapsed_s;
            check = compare_probe(measured,bp,cfg.threshold);
            item = pack_row(angle,range,method{1},measured,check,native.elapsed_s);
            rows = replace_row(rows,item);
            parameters = native.parameters;
            save(method_path,'measured','check','parameters','meta','-v7.3');
            fprintf('%s %s pass=%d ratio=%.3f/%.3f side_loss=%.2f/%.2f %.1fs\n',method{1},key,check.pass,check.irw_ratio_x,check.irw_ratio_y,check.pslr_loss_x_db,check.pslr_loss_y_db,native.elapsed_s);
            clear native
            checkpoint();
        end
        if isempty(cases), cases = case_record; else, cases(end+1) = case_record; end %#ok<AGROW>
        save(completed,'case_record'); checkpoint();
        % 只清理本次明确生成的临时频谱；原始回波和正式结果保留。
        delete(cache.path);
    end
end
checkpoint();
fprintf('SCAN_COMPLETE %s\n',run_id);
    function checkpoint()
        save(state_path,'rows','cases','cfg','run_id');
        if ~isempty(rows)
            table = struct2table(rows); table = sortrows(table,{'angle_deg','closest_range_m','method'});
            writetable(table,fullfile(records,'metrics.csv'));
        end
    end
end
function z = bp_values(path,xy,up)
result = run_bp_squint(path,xy,up); z = result.values;
end
function r = pack_row(angle,range,method,m,check,elapsed)
r.angle_deg = angle; r.closest_range_m = range; r.method = method;
r.irw_x_m = m.azimuth.irw_m; r.irw_y_m = m.range.irw_m;
r.pslr_x_db = m.azimuth.pslr_db; r.pslr_y_db = m.range.pslr_db;
r.islr_x_db = m.azimuth.islr_db; r.islr_y_db = m.range.islr_db;
r.error_x_m = m.error_x_m; r.error_y_m = m.error_y_m;
names = fieldnames(check);
for k = 1:numel(names), r.(names{k}) = check.(names{k}); end
r.elapsed_s = elapsed;
end
function rows = replace_row(rows,item)
if isempty(rows), rows = item; return; end
same = [rows.angle_deg]==item.angle_deg & [rows.closest_range_m]==item.closest_range_m & strcmp({rows.method},item.method);
rows(same) = []; rows(end+1) = item;
end
function write_json(path,value)
f = fopen(path,'w','n','UTF-8'); assert(f>=0); close_file = onCleanup(@() fclose(f)); %#ok<NASGU>
fprintf(f,'%s\n',jsonencode(value,'PrettyPrint',true));
end
