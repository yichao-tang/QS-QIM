function [dSer] = SER( wm,wr ,mDimension )
    [m,n] = size(wm);
    mes1 = zeros(1,n/mDimension);
    mes2 = zeros(1,n/mDimension);
    for i = 1 : mDimension : n
        m1 = 0;
        m2 = 0;
        for j = i : mDimension + i - 1
               m1= m1 +wm(j)*(2^(mDimension - j + i - 1));
               m2= m2 +wr(j)*(2^(mDimension - j + i - 1));
        end
        mes1(1,floor(i/mDimension)+1) = m1 ;
        mes2(1,floor(i/mDimension)+1) = m2 ;
    end
    dSer = BER(mes1,mes2);
end