function [res_z,wi,dist_min] = spheredecodetoML(x, d, H,J)
   
    Gc = J*H;

    [n,m]=size(H); 
    [Q,R] = qr(H); %QR???
  

    %?????????%
    % s?H??��??????x??sk_k1????????��?^Sm|m+1%
    k = m;
    s = inv(R)*Q'*x;
    sk_k1(m) = s(m); 
    di(m) = sqrt(d^2 - norm(x)^2 + norm(H*s)^2);
    res_z = zeros(1,m);
    dist_min= Inf;
    wi = -1;

    flag = 0;

    %????z??????%
    while(flag == 0)
        [highBound(k) ,lowBound(k)]= BoundsZk(di,R,sk_k1,k);
        z(k) = lowBound(k);
        %increase zk%
        flag = 1;
        while(flag == 1)
            z(k) = z(k) + 1;
            if z(k)  <= highBound(k)
                %decrease k%
                if k == 1
                     %??????z%
                    %increase zk%
                    temp = norm(H * z' - x);
                    Ai = getAiByZ(z,Gc,J);
                    if temp <= dist_min
                        res_z = z;
                        dist_min = temp;
                        wi = mod(Ai,2);
                    end
                    
                    flag = 1;
                else
                    k = k -1;
                    sum = 0;
                    for j = k+1:m
                        sum = sum + (R(k,j)/R(k,k))*(z(j)-s(j));
                    end
                    sk_k1(k) = s(k) - sum;
                    di(k) = sqrt(di(k+1)^2 - R(k+1,k+1)^2*(z(k+1) - sk_k1(k+1))^2);
                    %????z??????%
                    flag = 0;
                end
            else
                %increase k%
                k = k +1;
                
                if k == m + 1
                    %???%
                    flag = -1;
                    break;
                else
                    %increase zk%
                    
                end
            end
        end
    end
end
