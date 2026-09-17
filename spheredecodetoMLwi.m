function qx = spheredecodetoMLwi(x,wi)%mΪNr��nΪNt
    [H,J,d,Gc]= getPa();
    [~,~,dist_min] = spheredecodetoML(x, d, H,J);
    d = dist_min + d;
    d = d*2;
    [n,m]=size(H); %��������H��Ϊm*m
    [Q,R] = qr(H); %QR�ֽ�
  

    % ��ʼ������  %
    % sΪH��α������x��sk_k1��ʾ�����е�^Sm|m+1%
    k = m;
    s = inv(R)*Q'*x;
    sk_k1(m) = s(m); 
    % di(m)��ʾd'm, dist_min��ʾ��x����ĸ��ľ���%
    di(m) = sqrt(d^2 - norm(x)^2 + norm(H*s)^2);
    dist_min= Inf;

    % flag����ѭ����������%
    flag = 0;
    res_z = zeros(1,k);
    %����z������%
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
                     %�ռ����z%
                    %increase zk%
                    temp = norm(H * z' - x);
                    %�˴������������ĸ���������ĸ��ָ�i������������Я��Ai��Ϣ�ĸ��%
                    Ai = getAiByZ(z,Gc,J);

                    if mod(Ai,2) == wi && temp <= dist_min && isempty(find(H*z' < 0))
                        res_z = z;
                        dist_min = temp;
                    end
                    
                    flag = 1;
                else
                    k = k -1;
                    sum = 0;
                    for j = k+1:m
                        sum = sum + (R(k,j)/R(k,k))*(z(j)-s(j));
                    end
                    sk_k1(k) = s(k) - sum;
                    di(k) = sqrt(di(k+1)^2  - R(k+1,k+1)^2*(z(k+1) - sk_k1(k+1))^2);
                    %����z������%
                    flag = 0;
                end
            else
                %increase k%
                k = k +1;
                
                if k == m + 1
                    %��ֹ%
                    flag = -1;
                    break;
                else
                    %increase zk%
                    
                end
            end
        end
    end
    qx = H*res_z';
end
