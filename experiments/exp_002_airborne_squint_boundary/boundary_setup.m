function project_root = boundary_setup()
project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(project_root,'echo_generation','configs'));
addpath(fullfile(project_root,'echo_generation','geometry'));
addpath(fullfile(project_root,'echo_generation'));
addpath(fullfile(project_root,'common','io'));
addpath(fullfile(project_root,'common','metrics'));
addpath(fullfile(project_root,'common','plotting'));
for method = {'rd','cs','omega_k','bp'}
    addpath(fullfile(project_root,'signal_processing',method{1}));
end
end
