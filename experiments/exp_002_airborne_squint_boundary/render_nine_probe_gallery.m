function output = render_nine_probe_gallery()
% 补充实验002九点图集。原结果只读；新运行编号支持中断后继续。
% 三个距离位置分别重新取二维复图；另外两个x位置采用已验证的平移等价。
% 每个局部响应独立归一化，不将去载波后的复图相加冒充九目标相干成像。
root = boundary_setup(); cfg = probe_gallery_config();
source = fullfile(root,'results','exp_002_airborne_squint_boundary',cfg.source_run_id);
output = fullfile(root,'results','exp_002_airborne_squint_boundary',cfg.run_id);
records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',cfg.run_id);
work = fullfile(root,'scratch','exp_002',cfg.run_id);
for folder = {output,records,work,fullfile(output,'figures')}
    if ~exist(folder{1},'dir'), mkdir(folder{1}); end
end
config_path = fullfile(records,'gallery_config.json');
if exist(config_path,'file')
    previous = jsondecode(fileread(config_path));
    assert(isequal(previous.angles_deg(:),cfg.angles_deg(:)) && ...
        isequal(previous.closest_ranges_m(:),cfg.closest_ranges_m(:)) && ...
        isequal(previous.along_track_m(:),cfg.along_track_m(:)) && ...
        isequal(string(previous.methods(:)),string(cfg.methods(:))) && ...
        strcmp(previous.source_run_id,cfg.source_run_id) && ...
        previous.half_span_m==cfg.half_span_m && previous.samples_per_axis==cfg.samples_per_axis, ...
        '已存在图集配置不同，请使用新运行编号。');
else
    write_json(config_path,cfg);
end
display_config_path = fullfile(records,'display_config.json');
if ~exist(display_config_path,'file')
    write_json(display_config_path,cfg);
else
    display_cfg = jsondecode(fileread(display_config_path));
    assert(display_cfg.mosaic_spacing_m==cfg.mosaic_spacing_m,'拼图参数改变，请使用新运行编号。');
end
provenance_path = fullfile(records,'generation_provenance.json');
if ~exist(provenance_path,'file')
    [~,git_head] = system(sprintf('git -C "%s" rev-parse HEAD',root)); provenance.generation_head = strtrim(git_head);
    [~,dirty] = system(sprintf('git -C "%s" status --porcelain',root)); provenance.generation_dirty = ~isempty(strtrim(dirty));
    provenance.matlab_version = version;
    provenance.source_algorithm_commit = '4c6e8e088fe1527b7e89ed2e8f638b4bf073b931';
    provenance.final_code_commit_note = 'See completion.md; generation HEAD does not include uncommitted gallery source.';
    write_json(provenance_path,provenance);
end
offset = linspace(-cfg.half_span_m,cfg.half_span_m,cfg.samples_per_axis);
for angle = cfg.angles_deg
    for range = cfg.closest_ranges_m
        key = sprintf('sq%02d_r%05d',angle,range);
        paths = cellfun(@(method) boundary_result_path(output,key,method),cfg.methods,'UniformOutput',false);
        if all(cellfun(@(path) exist(path,'file')==2,paths)), continue; end
        saved = load(boundary_result_path(source,key,'BP'),'meta'); meta = saved.meta;
        truth = meta.targets.position_m(1:2);
        [xx,yy] = meshgrid(truth(1)+offset,truth(2)+offset);
        dataset = fullfile(root,'data','simulated',meta.id,'echo.mat');
        cache = [];
        for k = 1:numel(cfg.methods)
            method = cfg.methods{k};
            if exist(paths{k},'file'), continue; end
            fprintf('图集：%s %s 开始\n',key,method); timer = tic;
            if strcmp(method,'BP')
                native = run_bp_squint(dataset,[xx(:),yy(:)],4); values = native.values;
                old = load(boundary_result_path(source,key,method),'bp','bpcheck');
                metrics = old.bp; passed = old.bpcheck.pass;
            else
                if isempty(cache), cache = prepare_squint_spectrum(dataset,fullfile(work,[key,'_spectrum.mat'])); end
                switch method
                    case 'RD', native = run_rd_squint(cache);
                    case 'CS', native = run_cs_squint(cache);
                    case 'WK', native = run_wk_squint(cache);
                end
                values = sample_squint_image(native,[xx(:),yy(:)]);
                old = load(boundary_result_path(source,key,method),'measured','check');
                metrics = old.measured; passed = old.check.pass;
            end
            response.image = reshape(single(values),size(xx)); % 地面y行×方位x列，复数。
            response.offset_x_m = offset; response.offset_y_m = offset(:);
            response.truth_xy_m = truth; response.closest_range_m = range;
            response.angle_deg = angle; response.method = method;
            response.source_dataset_id = meta.id; response.source_run_id = cfg.source_run_id;
            response.parameters = native.parameters; response.metrics = metrics;
            response.passed_unified_criterion = passed;
            response.elapsed_s = toc(timer);
            response.state = 'independent_probe_ground_roi_spatial_carrier_removed';
            assert(all(isfinite(response.image(:))) && max(abs(response.image(:)))>0);
            save(paths{k},'response','meta','-v7.3');
            fprintf('图集：%s %s 完成，%.1f s\n',key,method,response.elapsed_s);
            clear native values response
        end
        if ~isempty(cache), delete(cache.path); end % 仅删除本入口scratch频谱缓存。
    end
    for method = cfg.methods
        folder = method_folder(output,method{1});
        if ~exist(fullfile(folder,'figures'),'dir'), mkdir(fullfile(folder,'figures')); end
        path = fullfile(folder,'figures',sprintf('sq%02d_nine_points.png',angle));
        mosaic_path = fullfile(folder,'figures',sprintf('sq%02d_nine_points_mosaic.png',angle));
        if ~exist(path,'file') || ~exist(mosaic_path,'file')
            panels = cell(3,3);
            for row = 1:3
                range = cfg.closest_ranges_m(4-row);
                s = load(boundary_result_path(output,sprintf('sq%02d_r%05d',angle,range),method{1}),'response');
                for col = 1:3
                    r = s.response; r.truth_xy_m(1) = cfg.along_track_m(col);
                    r.panel_title = sprintf('点%d：x=%g m，最近斜距=%g km', ...
                        (3-row)*3+col,r.truth_xy_m(1),range/1000);
                    panels{row,col} = r;
                end
            end
            heading = sprintf('%s · %g° · 九点局部成像（每格实际范围%g m × %g m）', ...
                method{1},angle,2*cfg.half_span_m,2*cfg.half_span_m);
            caption = '三个距离分别成像；同距方位点按已验证平移关系展示；非九目标同时激励的相干整幅图。';
            if ~exist(path,'file'), plot_squint_probe_grid(panels,heading,caption,path,cfg.resolution_dpi); end
            if ~exist(mosaic_path,'file')
                plot_squint_probe_mosaic(panels,method{1},angle,cfg.mosaic_spacing_m,mosaic_path,cfg.resolution_dpi);
            end
        end
    end
    % 每个角度一张四算法对照图：四列同窗同色标，三行对应距离边缘/中心。
    path = fullfile(output,'figures',sprintf('sq%02d_four_methods.png',angle));
    if ~exist(path,'file')
        panels = cell(3,4);
        for row = 1:3
            range = cfg.closest_ranges_m(4-row);
            for col = 1:4
                s = load(boundary_result_path(output,sprintf('sq%02d_r%05d',angle,range),cfg.methods{col}),'response');
                r = s.response; r.panel_title = sprintf('%s · 最近斜距%g km',cfg.methods{col},range/1000);
                panels{row,col} = r;
            end
        end
        plot_squint_probe_grid(panels,sprintf('%g° · 四算法与三个距离位置对照',angle), ...
            '全部窗口以真实目标坐标为原点，统一米制比例；红圈为真值；每格独立峰值归一化。',path,cfg.resolution_dpi);
    end
end
% 每方法一张角度演化图，便于直接看PSF倾斜、展宽和偏移。
for method = cfg.methods
    folder = method_folder(output,method{1}); path = fullfile(folder,'figures','angle_evolution.png');
    if exist(path,'file'), continue; end
    panels = cell(3,numel(cfg.angles_deg));
    for row = 1:3
        range = cfg.closest_ranges_m(4-row);
        for col = 1:numel(cfg.angles_deg)
            angle = cfg.angles_deg(col);
            s = load(boundary_result_path(output,sprintf('sq%02d_r%05d',angle,range),method{1}),'response');
            r = s.response; r.panel_title = sprintf('%g° · 最近斜距%g km',angle,range/1000);
            panels{row,col} = r;
        end
    end
    plot_squint_probe_grid(panels,sprintf('%s · 斜视角变化的同尺度对照',method{1}), ...
        '各角度地面窗口均为16 m × 16 m；红圈为真值；倾斜形状在等比例坐标下直接显示。',path,cfg.resolution_dpi);
end
audit_gallery(source,output,records,cfg);
write_gallery_index(output,cfg);
fprintf('九点图集完成：%s\n',output);
end

function folder = method_folder(output,method)
if strcmp(method,'WK'), name = 'omega_k'; else, name = lower(method); end
folder = fullfile(output,name);
end

function audit_gallery(source,output,records,cfg)
rows = struct([]); index = 0;
for angle = cfg.angles_deg
    for range = cfg.closest_ranges_m
        for method = cfg.methods
            path = boundary_result_path(output,sprintf('sq%02d_r%05d',angle,range),method{1});
            s = load(path,'response'); r = s.response; index = index+1;
            [peak,where] = max(abs(r.image(:))); [iy,ix] = ind2sub(size(r.image),where);
            edge = [abs(r.image(1,:)),abs(r.image(end,:)),abs(r.image(:,1)).',abs(r.image(:,end)).'];
            rows(index).angle_deg = angle; rows(index).closest_range_m = range;
            rows(index).method = method{1}; rows(index).rows = size(r.image,1); rows(index).columns = size(r.image,2);
            rows(index).step_m = r.offset_x_m(2)-r.offset_x_m(1);
            rows(index).min_irw_samples = min(r.metrics.azimuth.irw_m,r.metrics.range.irw_m)/rows(index).step_m;
            rows(index).finite = all(isfinite(r.image(:)));
            rows(index).peak_inside_window = iy>1 && iy<size(r.image,1) && ix>1 && ix<size(r.image,2);
            rows(index).edge_max_db = 20*log10(max(edge)/peak);
            rows(index).existing_roi_center_relative_error = NaN;
            previous = fullfile(method_folder(source,method{1}),sprintf('sq%02d_r%05d_roi.mat',angle,range));
            if exist(previous,'file')
                old = load(previous,'focused'); z = old.focused.image;
                center = r.image((size(r.image,1)+1)/2,(size(r.image,2)+1)/2);
                expected = z((size(z,1)+1)/2,(size(z,2)+1)/2);
                rows(index).existing_roi_center_relative_error = abs(double(center)-expected)/max(abs(expected),eps);
            end
        end
    end
end
t = struct2table(rows); assert(all(t.finite) && all(t.peak_inside_window) && all(t.min_irw_samples>=6));
matched = t.existing_roi_center_relative_error(isfinite(t.existing_roi_center_relative_error));
assert(~isempty(matched) && all(matched<1e-5),'新旧二维复图公共真值像素不一致。');
writetable(t,fullfile(records,'gallery_checks.csv'));
images = dir(fullfile(output,'**','*.png'));
assert(numel(images)==numel(cfg.methods)*(2*numel(cfg.angles_deg)+1)+numel(cfg.angles_deg));
image_rows = struct([]);
for k = 1:numel(images)
    info = imfinfo(fullfile(images(k).folder,images(k).name));
    relative = fullfile(images(k).folder(numel(output)+2:end),images(k).name);
    image_rows(k).relative_path = strrep(relative,filesep,'/');
    image_rows(k).width_pixels = info.Width; image_rows(k).height_pixels = info.Height;
    image_rows(k).bytes = images(k).bytes;
end
writetable(struct2table(image_rows),fullfile(records,'image_index.csv'));
report.source_run_id = cfg.source_run_id; report.run_id = cfg.run_id;
report.png_count = numel(images); report.complex_roi_count = height(t);
report.target_positions_per_nine_panel_figure = 9;
report.previous_roi_common_center_checks = numel(matched);
report.previous_roi_center_max_relative_error = max(matched);
report.display_normalization = 'independent peak per panel; parula(256); [-40,0] dB';
report.translation_basis = 'independent stripmap x translation; existing actual +500 m validation';
report.simultaneous_nine_target_echo = false;
report.provenance = jsondecode(fileread(fullfile(records,'generation_provenance.json')));
report.final_code_commit = 'See completion.md after source commit; generation HEAD is not final code version.';
write_json(fullfile(records,'gallery_audit.json'),report);
end

function write_gallery_index(output,cfg)
path = fullfile(output,'图集索引.md'); if exist(path,'file'), return; end
fid = fopen(path,'w','n','UTF-8'); assert(fid>=0); cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# 九点成像图集\n\n');
fprintf(fid,'局部窗口统一16 m × 16 m、257 × 257、等比例地面坐标、parula与[-40,0] dB。\n\n');
fprintf(fid,'九点同页图和单坐标拼图均使用三个距离的独立回波；同距方位点采用已验证平移关系。\n');
fprintf(fid,'单坐标拼图只压缩块间距，不改变局部尺度；它不是同时九目标的相干整幅成像。\n\n');
fprintf(fid,'## 按角度看四算法\n\n');
for angle = cfg.angles_deg
    fprintf(fid,'- [%g° 四算法/三距离对照](figures/sq%02d_four_methods.png)\n',angle,angle);
end
for method = cfg.methods
    folder = method_folder('',method{1}); folder = strrep(folder,filesep,'/');
    fprintf(fid,'\n## %s\n\n',method{1});
    fprintf(fid,'- [四角度演化图](%s/figures/angle_evolution.png)\n',folder);
    for angle = cfg.angles_deg
        fprintf(fid,'- %g°：[九格详图](%s/figures/sq%02d_nine_points.png) · [单坐标九点拼图](%s/figures/sq%02d_nine_points_mosaic.png)\n', ...
            angle,folder,angle,folder,angle);
    end
end
end

function write_json(path,value)
fid = fopen(path,'w','n','UTF-8'); assert(fid>=0); cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
