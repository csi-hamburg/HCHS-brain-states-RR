designs = {'24p', '24p_gsr', '36p', '36p_despike', '36p_spkreg', '36p_scrub', 'aroma', 'tcompcor', 'acompcor'};
atlasses = {'aal116', 'desikanKilliany', 'glasser360', 'gordon333', 'HarvardOxford', 'power264', ...
    'schaefer100x7', 'schaefer200x7', 'schaefer400x7'};

atlasdir = './../../../input/atlas/';

nstates = 5;

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
