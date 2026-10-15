function result = run_bp_squint(dataset_path, xy_m, upsampling)
% 常规距离压缩后BP；只计算请求的物理像素，不以目标真值生成匹配函数。
% xy_m为N像素×2（地面x,y，m）；原始回波从磁盘按脉冲块读取。
if nargin < 3, upsampling = 4; end
timer = tic; loaded = load(dataset_path,'meta'); m = loaded.meta;
validate_stripmap_probe(dataset_path,m);
input = matfile(dataset_path); cfg = m.configuration;
c = cfg.c_mps; fs = m.radar.range_sample_rate_hz;
nr = numel(m.fast_time_s); nfft = 2^nextpow2(nr+ceil(m.radar.pulse_duration_s*fs)+32);
off = nfft/2-floor(nr/2); nup = nfft*upsampling;
fr = (-nfft/2:nfft/2-1)'*fs/nfft;
hr = exp(1i*pi*fr.^2/m.radar.chirp_rate_hz_per_s).*(abs(fr)<=m.radar.bandwidth_hz/2);
rcenter = c*m.fast_time_s(floor(nr/2)+1)/2;
rfirst = rcenter-c*nfft/(4*fs);
step = c/(2*fs*upsampling);
values = complex(zeros(size(xy_m,1),1));
rmin = hypot(xy_m(:,2),cfg.geometry.height_m);
theta = deg2rad(cfg.geometry.squint_deg);
active = find(m.geometry.illuminated);
for first = 1:32:numel(active)
    idx = active(first:min(first+31,numel(active)));
    raw = input.echo(idx(1):idx(end),:).';
    padded = complex(zeros(nfft,numel(idx),'single')); padded(off+(1:nr),:) = raw;
    spectral = fftshift(fft(ifftshift(padded,1),[],1),1).*single(hr);
    enlarged = complex(zeros(nup,numel(idx),'single'));
    enlarged(nup/2-nfft/2+(1:nfft),:) = spectral;
    rc = fftshift(ifft(ifftshift(enlarged,1),[],1),1)*upsampling;
    xp = m.geometry.platform_along_m(idx).';
    range = hypot(xy_m(:,1)-xp,rmin);
    u = (range-rfirst)/step;
    low = floor(u); alpha = u-low;
    good = low>=1 & low<nup-2;
    jj = max(1,min(nup-3,low))+1+(0:numel(idx)-1)*nup;
    % 4倍带限加密后作四点Lagrange插值；以8倍结果作独立数值收敛检查。
    w0 = -alpha.*(alpha-1).*(alpha-2)/6;
    w1 = (alpha+1).*(alpha-1).*(alpha-2)/2;
    w2 = -(alpha+1).*alpha.*(alpha-2)/2;
    w3 = (alpha+1).*alpha.*(alpha-1)/6;
    samples = double(rc(jj-1)).*w0+double(rc(jj)).*w1+double(rc(jj+1)).*w2+double(rc(jj+2)).*w3;
    look = atan2(xy_m(:,1)-xp,rmin);
    good = good & abs(look-theta)<=cfg.geometry.beamwidth_rad/2;
    values = values+sum(samples.*exp(4i*pi*range/m.radar.wavelength_m).*good,2);
end
% 去空间载波便于复数图像显示/插值，幅度与定位不变；记录相位屏以便恢复。
phase_range = hypot(xy_m(:,1)-m.geometry.platform_mid_along_m,rmin);
result.values = values.*exp(-4i*pi*phase_range/m.radar.wavelength_m);
result.method = 'BP'; result.elapsed_s = toc(timer);
result.input_dataset_id = m.id;
result.parameters.range_upsampling = upsampling;
result.parameters.phase_screen_range_m = phase_range;
end
