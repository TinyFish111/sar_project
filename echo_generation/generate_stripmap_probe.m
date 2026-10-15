function dataset_path = generate_stripmap_probe(cfg, project_root, dataset_id)
% 独立生成并保存实际原始LFM样本，行慢时间、列快时间；分块写v7.3 MAT。
% 逐点激励测量场景冲激响应，避免多点旁瓣污染。不能据此评估分布式场景串扰。
g = stripmap_probe_geometry(cfg);
c = cfg.c_mps;
fs = cfg.radar.range_sample_rate_hz;
active_range = g.slant_range_m(g.illuminated);
center_range = (min(active_range)+max(active_range))/2;
half_span = (max(active_range)-min(active_range))/c+cfg.radar.pulse_duration_s/2+cfg.numerics.fast_time_guard_s;
nr = 2*ceil(half_span*fs);
fast_time_s = 2*center_range/c+(-nr/2:nr/2-1)/fs;
meta.id = dataset_id;
meta.schema_version = '2.1_stripmap_probe';
meta.radar = cfg.radar;
meta.configuration = cfg;
meta.geometry = g;
meta.geometry.platform_position_m = [g.platform_along_m,zeros(size(g.slow_time_s)),cfg.geometry.height_m*ones(size(g.slow_time_s))];
meta.fast_time_s = fast_time_s;
meta.slow_time_s = g.slow_time_s;
meta.targets.position_m = [cfg.targets.along_track_m,cfg.targets.cross_track_m,0];
meta.targets.reflectivity = 1;
meta.targets.coordinate_system = g.coordinate_system;
meta.processing_state = 'raw_complex_baseband';
meta.provenance = get_project_provenance(project_root,'echo_generation/configs/airborne_squint_boundary.m',1);
meta.checks.all_pulses_contain_complete_chirp = all(2*active_range/c-cfg.radar.pulse_duration_s/2>=fast_time_s(1)) && all(2*active_range/c+cfg.radar.pulse_duration_s/2<=fast_time_s(end));
assert(meta.checks.all_pulses_contain_complete_chirp);
meta.checks.size_slow_fast = [numel(g.slow_time_s),nr];
meta.checks.range_migration_m = max(active_range)-min(active_range);
meta.checks.illumination_time_s = diff(g.entry_exit_s);
folder = fullfile(project_root,'data','simulated',dataset_id);
assert(~exist(folder,'dir'),'已有正式回波不得覆盖。');
mkdir(folder);
dataset_path = fullfile(folder,'echo.mat');
save(dataset_path,'meta','-v7.3');
out = matfile(dataset_path,'Writable',true);
out.echo(numel(g.slow_time_s),nr) = complex(single(0));
for first = 1:cfg.numerics.block_pulses:numel(g.slow_time_s)
    idx = first:min(first+cfg.numerics.block_pulses-1,numel(g.slow_time_s));
    dt = fast_time_s-2*g.slant_range_m(idx)/c;
    phase = pi*cfg.radar.chirp_rate_hz_per_s*dt.^2-4*pi*g.slant_range_m(idx)/cfg.radar.wavelength_m;
    raw = single(exp(1i*phase).*(abs(dt)<=cfg.radar.pulse_duration_s/2).*g.illuminated(idx));
    assert(all(isfinite(raw(:))));
    out.echo(idx,:) = raw;
end
end
