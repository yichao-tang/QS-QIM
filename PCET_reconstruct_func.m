function [im_rec] = PCET_reconstruct_func(N,Mnm)

[X,Y]=meshgrid(-1:(2/(N-1)):1,-1:(2/(N-1)):1);
[theta,r] = cart2pol(X,Y); %直角坐标转化为极坐标
idx = uint8(r<=1);%限定了计算的范围，即单位圆内
R=r.^2; % 首先将r^2算出来，以便后面直接调用
im_rec=zeros(N);
for s=1:N
    for t=1:N
        H=exp(i*(2*pi*Mnm(2,:)*R(s,t) + Mnm(3,:)*theta(s,t) ));
        im_rec(s,t) = im_rec(s,t)+sum(H.*Mnm(4,:));
    end
end
im_rec=im_rec.*double(idx);%只取单位圆内部
% im_rec=abs(im_rec);
end

