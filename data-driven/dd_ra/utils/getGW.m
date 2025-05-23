function Wmatzono = getGW(lookup)
    W = lookup.W;
    totalsamples = lookup.totalsamples; 
    n = lookup.sys.dims.n;

    g = size(W.G,2);  % number of generators
    GW = cell(1, g * totalsamples);  % preallocate the cell array
    
    index = 1;
    for i = 1:g
        vec = W.G(:,i);
        for j = 0:totalsamples-1
            GW{index} = [zeros(n,j), vec, zeros(n,totalsamples-j-1)];
            index = index + 1;
        end
    end
    
    Wmatzono = matZonotope(zeros(n,totalsamples), GW);

end