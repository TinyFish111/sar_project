function write_source_manifest(run_id)
root = boundary_setup();
records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
files = dir(fullfile(root,'echo_generation','**','*.m'));
for folder = {'signal_processing','common','experiments/exp_002_airborne_squint_boundary'}
    files = [files;dir(fullfile(root,folder{1},'**','*.m'))]; %#ok<AGROW>
end
entries = struct([]);
for k = 1:numel(files)
    path = fullfile(files(k).folder,files(k).name);
    f = fopen(path,'rb'); assert(f>=0); bytes = fread(f,Inf,'*uint8'); fclose(f);
    digest = java.security.MessageDigest.getInstance('SHA-256'); digest.update(typecast(bytes,'int8'));
    value = typecast(digest.digest(),'uint8');
    item.path = strrep(path,[root,filesep],''); item.path = strrep(item.path,'\','/');
    item.sha256 = lower(reshape(dec2hex(value,2).',1,[])); item.bytes = numel(bytes);
    if isempty(entries), entries = item; else, entries(end+1) = item; end %#ok<AGROW>
end
manifest.provenance_at_manifest = get_project_provenance(root,'experiments/exp_002_airborne_squint_boundary/boundary_config.m',1);
manifest.note = 'This pre-commit HEAD is not the final implementation version. Final code commit is bound in completion.md; source hashes identify the reproducible sources.';
manifest.sources = entries;
f = fopen(fullfile(records,'source_manifest.json'),'w','n','UTF-8'); assert(f>=0); clean = onCleanup(@() fclose(f)); %#ok<NASGU>
fprintf(f,'%s\n',jsonencode(manifest,'PrettyPrint',true));
end
