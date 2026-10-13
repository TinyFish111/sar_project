function result = run_rd(dataset, options)
% 正侧视RD：线性距离匹配滤波 -> 方位FFT -> sinc RCMC -> 双曲方位匹配 -> IFFT。
% 无工具箱依赖，不实施SRC；适用边界见实验记录。
tStart = tic;
assert(strcmp(dataset.processing_state,'raw_complex_baseband_no_range_compression'));
assert(dataset.geometry.squint_deg == 0,'此基线仅支持正侧视。');
c = dataset.radar.propagation_speed_mps;
fs = dataset.radar.range_sample_rate_hz;
fa = dataset.radar.prf_hz;
lambda = dataset.radar.wavelength_m;
v = dataset.geometry.speed_mps;
r0 = dataset.geometry.reference_slant_range_m;
[na,nr] = size(dataset.echo);
rangeAxis = c*dataset.fast_time_s/2;
keep = find(abs(rangeAxis-r0)<=options.range_processing_half_width_m);
r = rangeAxis(keep);
% 奇数长度的中心化参考脉冲；显式线性卷积、补零并对齐群延迟。
halfPulse = floor(dataset.radar.pulse_duration_s*fs/2);
refT = (-halfPulse:halfPulse)/fs;
ref = exp(1i*pi*dataset.radar.chirp_rate_hz_per_s*refT.^2);
h = conj(fliplr(ref));
nfftRange = 2^nextpow2(nr+numel(h)-1);
H = fft(single(h),nfftRange,2);
rangeCompressed = complex(zeros(na,numel(keep),'single'));
for first = 1:options.range_fft_block_rows:na
    rows = first:min(first+options.range_fft_block_rows-1,na);
    linear = ifft(fft(dataset.echo(rows,:),nfftRange,2).*H,[],2);
    rangeCompressed(rows,:) = linear(:,halfPulse+keep);
end
[~,peakBefore] = max(abs(rangeCompressed),[],2);
diagRows = unique(round(linspace(1,na,256)));
diagKeep = find(abs(r-r0)<=25);
result.diagnostics.range_compressed_before_rcmc = abs(rangeCompressed(diagRows,diagKeep));
result.diagnostics.slow_time_s = dataset.slow_time_s(diagRows);
result.diagnostics.range_offset_m = r(diagKeep)-r0;
result.diagnostics.peak_range_before_m = r(peakBefore);
% 双边补零，避免方位循环卷积把边缘能量折回中心。
nfftAz = 2^nextpow2(options.azimuth_fft_padding_factor*na);
offset = nfftAz/2-na/2;
padded = complex(zeros(nfftAz,numel(r),'single'));
padded(offset+(1:na),:) = rangeCompressed;
clear rangeCompressed linear
spec = fftshift(fft(ifftshift(padded,1),[],1),1);
clear padded
freq = (-nfftAz/2:nfftAz/2-1)'*fa/nfftAz;
D = sqrt(1-(lambda*freq/(2*v)).^2);
assert(all(isreal(D)) && all(D>0));
dr = c/(2*fs);
taps = options.rcmc_sinc_taps;
assert(mod(taps,2)==0);
tapOffsets = -taps/2+1:taps/2;
% 每一方位频率行独立，从R/D位置取样到输出最近斜距R。
% Lanczos型截断sinc，逐查询点归一化以保持常量增益。
for ia = 1:nfftAz
    sampleIndex = (r/D(ia)-r(1))/dr+1;
    base = floor(sampleIndex);
    rowOut = complex(zeros(1,numel(r),'single'));
    weightSum = zeros(1,numel(r));
    for it = tapOffsets
        index = base+it;
        delta = sampleIndex-index;
        w = local_sinc(delta).*local_sinc(delta/(taps/2));
        valid = index>=1 & index<=numel(r) & abs(delta)<taps/2;
        rowOut(valid) = rowOut(valid)+single(w(valid)).*spec(ia,index(valid));
        weightSum(valid) = weightSum(valid)+w(valid);
    end
    valid = abs(weightSum)>1e-10;
    rowOut(valid) = rowOut(valid)./single(weightSum(valid));
    spec(ia,:) = rowOut;
end
% 只为诊断反变换25m中心条带；不改变正式处理。
rcmcTime = fftshift(ifft(ifftshift(spec(:,diagKeep),1),[],1),1);
result.diagnostics.range_compressed_after_rcmc = abs(rcmcTime(offset+diagRows,:));
clear rcmcTime
% exp(+j4*pi*R/lambda*(D-1))消除双曲方位频谱相位；常量相位保留。
for ia = 1:nfftAz
    spec(ia,:) = spec(ia,:).*single(exp(1i*4*pi*r/lambda*(D(ia)-1)));
end
imageFull = fftshift(ifft(ifftshift(spec,1),[],1),1);
clear spec
alongTrack = (-nfftAz/2:nfftAz/2-1)'*v/fa;
outAz = find(abs(alongTrack)<=options.azimuth_output_half_width_m);
outRange = find(abs(r-r0)<=options.range_output_half_width_m);
result.image = imageFull(outAz,outRange);
result.slant_range_m = r(outRange);
result.along_track_m = alongTrack(outAz);
% 完整场景幅度缩略图用于检查有无鬼影，复数全图不重复存盘。
quickAz = 1:4:nfftAz;
quickRange = 1:8:numel(r);
result.diagnostics.full_scene_amplitude = abs(imageFull(quickAz,quickRange));
result.diagnostics.full_scene_along_track_m = alongTrack(quickAz);
result.diagnostics.full_scene_slant_range_m = r(quickRange);
result.coordinate_system = 'along-track x and closest slant range R; metres';
result.input_dataset_id = dataset.id;
result.method = 'broadside_range_doppler_linear_matched_filter_sinc_rcmc';
result.options = options;
result.processing_elapsed_s = toc(tStart);
result.geometry.speed_mps = v;
result.geometry.reference_slant_range_m = r0;
end

function y = local_sinc(x)
y = ones(size(x));
nonzero = abs(x)>1e-12;
y(nonzero) = sin(pi*x(nonzero))./(pi*x(nonzero));
end
