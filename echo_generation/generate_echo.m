function dataset = generate_echo(cfg, project_root, dataset_id)
% 输出原始复基带回波：s = wr*wa*exp(j*pi*Kr*(tau-2R/c)^2)*exp(-j*4*pi*R/lambda)。
% 不依赖任何成像方法，采用stop-go、静止点目标和精确欧氏距离。
assert(abs(cfg.radar.bandwidth_hz-cfg.radar.chirp_rate_hz_per_s*cfg.radar.pulse_duration_s)<1);
assert(cfg.radar.range_sample_rate_hz>cfg.radar.bandwidth_hz);
na = 2*ceil(cfg.geometry.illumination_time_s*cfg.radar.prf_hz/2);
eta = (-na/2:na/2-1)'/cfg.radar.prf_hz;
half_span = cfg.scene.slant_swath_m/cfg.c_mps + cfg.radar.pulse_duration_s/2 + cfg.numerics.fast_time_guard_s;
nr = 2*ceil(half_span*cfg.radar.range_sample_rate_hz);
tau = 2*cfg.scene.center_slant_range_m/cfg.c_mps + (-nr/2:nr/2-1)/cfg.radar.range_sample_rate_hz;
geometry = airborne_straight_geometry(cfg,eta);
targets = point_target_scene(cfg);
raw = complex(zeros(na,nr,cfg.numerics.echo_precision));
ranges = zeros(na,size(targets.position_m,1));
for k = 1:size(targets.position_m,1)
    delta = geometry.platform_position_m-targets.position_m(k,:);
    ranges(:,k) = sqrt(sum(delta.^2,2));
    beam_center_s = targets.position_m(k,1)/cfg.geometry.speed_mps;
    illuminated = abs(eta-beam_center_s)<=cfg.geometry.illumination_time_s/2;
    for ia = find(illuminated)'
        dt = tau-2*ranges(ia,k)/cfg.c_mps;
        support = abs(dt)<=cfg.radar.pulse_duration_s/2;
        phase = pi*cfg.radar.chirp_rate_hz_per_s*dt(support).^2-4*pi*ranges(ia,k)/cfg.radar.wavelength_m;
        raw(ia,support) = raw(ia,support)+cast(targets.reflectivity(k)*exp(1i*phase),cfg.numerics.echo_precision);
    end
end
dataset.schema_version = '1.0';
dataset.id = dataset_id;
dataset.echo = raw;
dataset.fast_time_s = tau;
dataset.slow_time_s = eta;
dataset.radar = cfg.radar;
dataset.radar.propagation_speed_mps = cfg.c_mps;
dataset.geometry = geometry;
dataset.targets = targets;
dataset.truth.slant_range_m = ranges;
dataset.truth.center_azimuth_chirp_rate_hz_per_s = -2*cfg.geometry.speed_mps^2/(cfg.radar.wavelength_m*cfg.scene.center_slant_range_m);
dataset.truth.effective_aperture_length_m = cfg.geometry.speed_mps*cfg.geometry.illumination_time_s;
dataset.truth.doppler_bandwidth_hz = abs(dataset.truth.center_azimuth_chirp_rate_hz_per_s)*cfg.geometry.illumination_time_s;
dataset.processing_state = 'raw_complex_baseband_no_range_compression';
dataset.configuration = cfg;
dataset.provenance = get_project_provenance(project_root,'echo_generation/configs/airborne_point_baseline.m',cfg.numerics.random_seed);
end
