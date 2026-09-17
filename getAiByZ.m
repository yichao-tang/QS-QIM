function Ai = getAiByZ(z,Gc,J)
        Ai = -1;
      
        [n,m] = size(Gc);

        di= getDi(m);
        for i = 1:2^m
            temp= (z' - di(:,i))/J;
            if temp == round(temp)
                if Ai ~= -1
                    Ai = -2;
                    return ;
                end
                Ai = i-1;
            end
        end
end