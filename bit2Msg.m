function msg = bit2Msg(w,dimension)
 [m,n] = size(w);
 mes1 = zeros(1,n/dimension);
 num = 1;
    for i = 1 : dimension : n
        m1 = 0;
        for j = i : dimension + i - 1
               m1= m1 +w(j)*(2^(dimension - j + i - 1));
        end
        mes1(1,num) = m1 ;
        num = num + 1;
    end
    msg = mes1;
end