function [MMT,H]=PCET_func(img,T)

% 将图像坐标转化到[-1 1]*[-1 1]之间
N=size(img,1);
% x=0:(N-1);
% X=x/(N/2)-1;
% Y=x/(N/2)-1;
[X,Y]=meshgrid(-1:(2/(N-1)):1,-1:(2/(N-1)):1);

% 获取单位圆内的图像img2
% [XX,YY]=meshgrid(-1:(2/(N-1)):1,-1:(2/(N-1)):1);
[theta,r] = cart2pol(X,Y); %直角坐标转化为极坐标
idx = uint8(r<=1);%限定了计算的范围，即单位圆内
img2=img.*idx;
% figure,imshow(img2)

% 设定阶数(order)n与重复度(repetition)l的取值范围
num=0;
for n=-T:T %阶数
    for l=-T:T % 重复度
        if abs(n)+abs(l)<=T
            num=num+1;
            MMT(:,num)=[n;l]; %NL第一行表示阶数，第二行表示重复度
        end
    end
end

%下面计算PCET矩
MMT(3,:)=0;
R=r.^2; % 首先将r^2算出来，以便后面直接调用
MMT=complex(MMT);
for k=1:size(MMT,2)
    H{k}=exp(i*( 2*pi*MMT(1,k).*R + MMT(2,k).*theta)).*double(idx);
    MMT(3,k)=sum(sum( conj(H{k}).*double(img2))); 
    %------------------下面一段为循环的笨方法，比较慢------------------------
    %     for s=1:N
    %         for t=1:N
    %             if idx(s,t)~=0
    %                 f=img2(s,t); % 像素灰度值
    %                 H=exp(i*( 2*pi*MMT(1,k)*R(s,t) + MMT(2,k)*theta(s,t) ));
    %                 MMT(3,k) = MMT(3,k)+conj(H)*double(f);
    %             end
    %         end
    %     end
    %-----------------------------------笨方法结束------------------------------
%     MMT(3,k)=MMT(3,k)*4/(pi*N^2); % 计算的PCET矩
%     Ir=Ir+MMT(3,k)*H.*double(idx);
end
%  imshow(uint8(Ir));
MMT(3,:)=MMT(3,:)*4/(pi*N^2); % 计算的PCET矩
MMT_real=abs(MMT);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % 图像重构
% 
% im_rec=zeros(N);
% for s=1:N
%     for t=1:N
%         H=exp(i*( 2*pi*MMT(1,:)*R(s,t) + MMT(2,:)*theta(s,t) ));
%         im_rec(s,t) = im_rec(s,t)+sum( H.*MMT(3,:));
%         %------------------下面一段为循环的笨方法，比较慢------------------------
%         %         for k=1:size(MMT,2)
%         %             H=exp(i*( 2*pi*MMT(1,k)*R(s,t) + MMT(2,k)*theta(s,t) ));
%         %             im_rec(s,t) = im_rec(s,t)+H*MMT(3,k);
%         %         end
%         %-----------------------------------笨方法结束--------------------------
%     end
% end
% 
% im_rec=im_rec.*double(idx);%只取单位圆内部
% figure,imshow(uint8((abs(im_rec))))