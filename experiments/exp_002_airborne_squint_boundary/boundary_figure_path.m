function path = boundary_figure_path(output_dir,key,method)
if strcmpi(method,'WK'), folder_name = 'omega_k'; else, folder_name = lower(method); end
folder = fullfile(output_dir,folder_name,'figures'); if ~exist(folder,'dir'), mkdir(folder); end
path = fullfile(folder,[key,'.png']);
end
