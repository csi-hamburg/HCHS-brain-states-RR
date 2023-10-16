designs = {'36p', '24p', '24p_gsr', '36p_despike', '36p_spkreg', '36p_scrub', 'aroma', 'tcompcor', 'acompcor'};
atlasses = {'schaefer400x7', 'aal116', 'desikanKilliany', 'glasser360', 'gordon333', 'HarvardOxford', 'power264', ...
    'schaefer100x7', 'schaefer200x7'};

atlasdir = './../../../input/atlas/';

nstates = 5;

fid = fopen('./../../../input/final_batch.dat');
final_batch = textscan(fid, '%s');
fclose(fid);
final_batch = final_batch{1}';

Reps = 100;
MaxIter = 1e3;
flag = 'slow'

for design = designs
    design = design{1};
    for atlas = atlasses
        atlas = atlas{1};
        
        disp(['Processing ' design ' and ' atlas '.'])
        
        NodeIndex = dlmread(fullfile(atlasdir, atlas, [atlas, 'NodeIndex.1D']));
        NodeIndex = 1:numel(NodeIndex);
        
        CAfile = fullfile(atlasdir, atlas, [atlas, 'CommunityAffiliation.1D']);
        if exist(CAfile, 'file')
            CommunityAffiliation = dlmread(CAfile);
        end
        
        CNfile = fullfile(atlasdir, atlas, [atlas, 'CommunityNames.txt']);
        if exist(CNfile, 'file')
            fid = fopen(fullfile(atlasdir, atlas, [atlas, 'CommunityNames.txt']));
            data = textscan(fid, '%s');
            fclose(fid);
            CommunityNames = data{1};
            clear data
        end
        
        if any(strcmp(atlas, {'power246', 'gordon333'}))
            excludedCommunities = {'none', 'cerebellar', 'subcortical'};
            idx = cellfun(@(s)(~any(strcmp(s, excludedCommunities))), CommunityNames(CommunityAffiliation));
        else
            idx = NodeIndex;    
        end
        
        clustering;
        clear CommunityAffiliation CommunityNames;
        
    end
end

%%
Reps = 100;
MaxIter = 1e3;
flag = 'spider';
atlas = 'schaefer100x7';
design = '36p';

NodeIndex = dlmread(fullfile(atlasdir, atlas, [atlas, 'NodeIndex.1D']));
NodeIndex = 1:numel(NodeIndex);
idx = NodeIndex;

clustering;
