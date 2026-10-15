function data = read_squint_spectrum(cache, indices)
% 输出快时间×方位频率；仅从同一公共缓存读数据，不调用任何算法模块。
if isfield(cache,'storage') && strcmp(cache.storage,'uncompressed_hdf5_blocks')
    count = [numel(indices),numel(cache.meta.fast_time_s)];
    re = h5read(cache.path,'/azimuth_real',[indices(1),1],count);
    im = h5read(cache.path,'/azimuth_imag',[indices(1),1],count);
    data = complex(re,im).';
else
    input = matfile(cache.path); data = input.spectrum(indices,:).';
end
end
