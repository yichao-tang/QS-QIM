function di=getDi(N)
    J = zeros(N,1);
    di = zeros(N,2^N);
    for i = 0:2^N - 1
            temp = i;
            for j = N-1 :-1: 0
                    J(N-j,1) = floor(temp/2^j);
                    temp = mod(temp,2^j);
            end
            di(:,i+1) = J;
    end
end