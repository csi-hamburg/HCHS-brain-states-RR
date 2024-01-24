files = dir(fullfile('./../../../derivatives/xcpengine',design,'sub-*','fcon', atlas, '*_ts.1D'));
files = files(1:numel(files)); %% remove . and ..

subIDs = cellfun(@(s)(s(5:12)),{files.name},'UniformOutput',false);

final_batch_idx = ismember(subIDs, final_batch);

subIDs  = subIDs(final_batch_idx);
files  = files(final_batch_idx);

numel(subIDs)
n = numel(files)


[nTP, nROI] = size(dlmread(fullfile(files(1).folder, files(1).name))); %% without excluded communities


%%
dd = [];
TPsubj = [];

for i = 1:n
    file = files(i);
    ts = dlmread(fullfile(file.folder, file.name));
    dd = [dd; ts];
    TPsubj = [TPsubj; i*ones(size(ts,1), 1)];
end

dd = dd(:,idx); %% exclude communities
size(dd);
nROI = size(dd,2);

%% k-means clustering
[IDX, C, SUMD, D] = kmeans(dd, 5, 'Distance', 'correlation', 'Replicates', Reps, 'MaxIter', MaxIter);


%%
groupcounts(IDX) / length(IDX)
[~, q] = sort(groupcounts(IDX) / length(IDX), 'desc');
[~, q] = sort(q);


%%
m = {};
for i = 1:n
   m{i} = IDX(TPsubj == i); 
end
quantile(cellfun(@length,m),[0,.25,.5,.75,1])
%% fractional occupancy
fracocc = nan(numel(subIDs), nstates);
for i = 1:nstates
    fracocc(:,i) = cellfun(@(s)(sum(s==i)/numel(s)),m);
end
fracocc(:,q) = fracocc;

%% dwell time
dts = cellfun(@dwelltimes, m, 'unif', false);
dts = cell2mat(dts');

for i = 1:nstates
    dt = dts(:,i);
end
dts(:,q) = dts;

%% spider data for Schaefer atlas
if contains(atlas, 'schaefer')
    CAfile = fullfile(atlasdir, atlas, [atlas, 'CommunityAffiliation.1D']);
    NW7 = dlmread(CAfile);
    NW7u = unique(NW7);
end

spiderdatall = []; %% state, NW, sign, value 
for j = 1:nstates
    for i = 1:numel(NW7u)
        nw = NW7u(i);
        u = double(nw == NW7);
        vpos = max(C(j,:),0);
        vneg = max(-C(j,:),0);
        posNW(j,i) = vpos*u/(norm(u)*norm(vpos));
        negNW(j,i) = vneg*u/(norm(u)*norm(vneg));
        
        spiderdatall = [spiderdatall; [ [q(j);q(j)], [i;i], [1;-1], [posNW(j,i); negNW(j,i)]  ] ];
        
    end
end
%dlmwrite(['./../../derivatives/data/spiderdatall_' design '~' atlas, '.dat'], spiderdatall);

%% export
fid = fopen(['./../../derivatives/data/' flag '/dFCmetrics~' design '~' atlas, '~.dat'], 'w');
str = ['ID,', sprintf('fracocc_%d,',1:nstates), sprintf('dwell_%d,',1:nstates)];
fprintf(fid, [str(1:end-1) '\n']);
clear str
format=['sub-%s,', repmat('%f,',[1, 2*nstates])];
for i = 1:numel(subIDs)
    fprintf(fid, [format(1:end-1) '\n'], subIDs{i}, fracocc(i,:), dts(i,:));
end
fclose(fid);
clear format