function dt = dwelltimes(x)

    nstates = 5;

    x = reshape(x,1,[]);
    states = 1:nstates; %1:max(x); % unique(x);

    i = find(diff(x));
    n = [i numel(x)] - [0 i];
  
    dt = arrayfun(@(s)(mean(n([x(i) x(end)]==s))), states, 'unif', true);
    
end