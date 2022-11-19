files = dir(fullfile('./../../../derivatives/xcpengine',design,'sub-*','fcon', atlas, '*_ts.1D'));
files = files(1:numel(files)); %% remove . and ..

n = numel(files);
subIDs = cellfun(@(s)(s(5:12)),{files.name},'UniformOutput',false);

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
[IDX, C, SUMD, D] = kmeans(dd, 5, 'Distance', 'correlation', 'Replicates', 100, 'MaxIter', 1e3);


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

%% export
fid = fopen(['./../../derivatives/data/dFCmetrics~' design '~' atlas, '~.dat'], 'w');
str = ['ID,', sprintf('fracocc_%d,',1:nstates), sprintf('dwell_%d,',1:nstates)];
fprintf(fid, [str(1:end-1) '\n']);
clear str
format=['sub-%s,', repmat('%f,',[1, 2*nstates])];
for i = 1:numel(subIDs)
    fprintf(fid, [format(1:end-1) '\n'], subIDs{i}, fracocc(i,:), dts(i,:));
end
fclose(fid);
clear format