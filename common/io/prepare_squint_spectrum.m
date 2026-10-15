function cache = prepare_squint_spectrum(dataset_path, cache_path)
% 与算法无关的读取/FFT缓存：去真实多普勒中心，双边补零实现线性相关。
% 缓存矩阵行为去中心方位频率，列为原始快时间；只在scratch保存。
loaded = load(dataset_path,'meta');
m = loaded.meta;
validate_stripmap_probe(dataset_path,m);
cfg = m.configuration;
rref = cfg.scene.reference_closest_range_m;
theta = deg2rad(cfg.geometry.squint_deg);
b = cfg.geometry.beamwidth_rad/2;
ref_half = max(abs(rref/cfg.geometry.speed_mps*(tan(theta)-tan(theta+[b,-b]))));
na = numel(m.slow_time_s);
nref = 2*ceil(ref_half*cfg.radar.prf_hz)+8;
nfft = 2^nextpow2(na+nref+32);
cache.path = cache_path;
cache.nfft_azimuth = nfft;
cache.meta = m;
cache.doppler_baseband_hz = (-nfft/2:nfft/2-1)*cfg.radar.prf_hz/nfft;
cache.doppler_true_hz = cache.doppler_baseband_hz+m.geometry.center_doppler_hz;
cache.azimuth_sheared_m = (-nfft/2:nfft/2-1)*cfg.geometry.speed_mps/cfg.radar.prf_hz;
cache.storage = 'uncompressed_hdf5_blocks';
if exist(cache_path,'file')
    try
        h5info(cache_path,'/azimuth_real');
        complete = h5readatt(cache_path,'/','spectrum_complete');
        if complete==1, return; end
    catch
        previous = load(cache_path,'cache');
        if ~isfield(previous.cache,'storage')
            cache.storage = 'matfile_legacy'; return;
        end
    end
    % 只删除当前项目scratch下由本入口生成的不完整中间缓存。
    project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    [ok,attribute] = fileattrib(cache_path);
    assert(ok && startsWith(lower(attribute.Name),lower([fullfile(project_root,'scratch'),filesep])));
    delete(cache_path);
end
input = matfile(dataset_path);
save(cache_path,'cache','-v7.3');
nr = numel(m.fast_time_s);
% 临时频谱不压缩：v7.3默认压缩高熵复频谱会占用大量CPU。
% 块形状与后续读取的方位频率块对齐，正式原始回波仍保持v7.3格式。
h5create(cache_path,'/azimuth_real',[nfft,nr],'Datatype','single','ChunkSize',[32,min(256,nr)]);
h5create(cache_path,'/azimuth_imag',[nfft,nr],'Datatype','single','ChunkSize',[32,min(256,nr)]);
deramp = single(exp(-2i*pi*m.geometry.center_doppler_hz*m.slow_time_s));
off = nfft/2-floor(na/2);
for first = 1:256:nr
    cols = first:min(first+255,nr);
    data = complex(zeros(nfft,numel(cols),'single'));
    data(off+(1:na),:) = input.echo(:,cols).*deramp;
    data = fftshift(fft(ifftshift(data,1),[],1),1);
    h5write(cache_path,'/azimuth_real',real(data),[1,first],[nfft,numel(cols)]);
    h5write(cache_path,'/azimuth_imag',imag(data),[1,first],[nfft,numel(cols)]);
end
h5writeatt(cache_path,'/','spectrum_complete',1);
end
