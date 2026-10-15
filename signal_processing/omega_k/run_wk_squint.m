function result = run_wk_squint(cache, processing)
% 经典平方根波数域匹配+Stolt；采用局部输出坐标的频域缩放，避免空场景大FFT。
% 参考距离的变化只产生可解析的坐标平移；未加入新的高阶近似/新型改进算法。
if nargin < 2, processing = wk_squint_config(); end
if ~isfield(processing,'frequency_grid_refinement'), processing.frequency_grid_refinement = 1; end
timer = tic; p = squint_processing_axes(cache,processing.range_upsampling); m = cache.meta;
c = m.configuration.c_mps; v = m.configuration.geometry.speed_mps;
f0 = m.radar.carrier_hz; nr = numel(m.fast_time_s);
image_spectrum = complex(zeros(numel(p.range_output_m),cache.nfft_azimuth,'single'));
dr = p.output_step_m;
% q网格Nyquist范围覆盖全输出ROI；距离中心为显示窗口原点，不是额外参考点滤波。
span = max(abs(p.range_output_m-p.probe_range_m));
dq = c/(2*(2*span+50))/processing.frequency_grid_refinement;
for first = 1:processing.frequency_block_size:cache.nfft_azimuth
    idx = first:min(first+processing.frequency_block_size-1,cache.nfft_azimuth);
    data = complex(zeros(p.nfft_range,numel(idx),'single'));
    data(p.range_offset+(1:nr),:) = read_squint_spectrum(cache,idx);
    spectrum = fftshift(fft(ifftshift(data,1),[],1),1);
    for k = 1:numel(idx)
        fat = p.fa_hz(idx(k)); gamma = c*fat/(2*v);
        q = sqrt((f0+p.fr_hz).^2-gamma^2);
        phase = pi*p.fr_hz.^2/m.radar.chirp_rate_hz_per_s ...
            +4*pi*p.probe_range_m/c*q-4*pi*p.fr_hz*p.range_center_m/c ...
            +2*pi*fat*p.probe_range_m*tan(p.theta_rad)/v;
        matched = double(spectrum(:,k)).*exp(1i*phase);
        lo = sqrt((f0-m.radar.bandwidth_hz/2)^2-gamma^2);
        hi = sqrt((f0+m.radar.bandwidth_hz/2)^2-gamma^2);
        qc = (lo+hi)/2;
        count = 2^nextpow2(max((hi-lo)/dq*processing.zoom_fft_oversampling,c/(2*dr*dq)));
        qout = qc+(-count/2:count/2-1)'*dq;
        fin = sqrt(qout.^2+gamma^2)-f0;
        % 校正旧程序单次线性Stolt的幅相误差：16点截断sinc，仍是经典插值。
        stolt = sinc_regular(p.fr_hz,matched,fin,processing.stolt_taps);
        stolt(fin < -m.radar.bandwidth_hz/2 | fin > m.radar.bandwidth_hz/2) = 0;
        migrated = fftshift(ifft(ifftshift(stolt)));
        rr = (-count/2:count/2-1)'*c/(2*count*dq);
        offset = p.range_output_m-p.probe_range_m;
        line = interp1(rr,migrated,offset,'linear',0);
        % 恢复统一q原点，并按每个距离的波束中心时刻消除图像剪切。
        line = line.*exp(4i*pi/c*(qc-f0*p.dref)*offset ...
            +2i*pi*cache.doppler_baseband_hz(idx(k))/v*offset*tan(p.theta_rad));
        image_spectrum(:,idx(k)) = single(line);
    end
end
[image,p] = finish_squint_image(image_spectrum,p);
result = squint_result(cache,p,image,'WK',toc(timer));
result.parameters.stolt = sprintf('%d-point Lanczos; full shifted band; local coordinate FFT',processing.stolt_taps);
result.parameters.numerics = processing;
end
function z = sinc_regular(x,y,xq,taps)
u = (xq-x(1))/(x(2)-x(1)); z = complex(zeros(size(u))); normw = zeros(size(u));
for k = -taps/2+1:taps/2
    j = floor(u)+k; delta = u-j;
    w = sinc_local(delta).*sinc_local(delta/(taps/2));
    good = j>=0 & j<numel(x);
    z(good) = z(good)+y(j(good)+1).*w(good); normw(good) = normw(good)+w(good);
end
z = z./max(normw,eps);
end
function z = sinc_local(x)
z = ones(size(x)); good = abs(x)>1e-12; z(good) = sin(pi*x(good))./(pi*x(good));
end
