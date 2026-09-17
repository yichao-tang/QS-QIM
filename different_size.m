clear
clc
I = imread('lena.bmp');
%I = imread('02.goldhill.bmp');
%I = imread('03.peppers.bmp');
% I = imread('04.barbara.bmp');
% I = imread('05.airplane.bmp');
% I = imread('06.baboon.bmp');
% I = imread('07.boat.bmp');
%img=double(I);
I= imresize(I, [256,256]);
%I = imresize(I, [128,128]);
% I = imresize(I, [64,64]);
% I = imresize(I, [32,32]);
%imshow(uint8(I));
MODE = 1; %用于转换
%1.PCET(T=15时能嵌入191bits)；2.PCT(T=15时只能嵌入96bits)；3.PST(T=15时只能嵌入84bits)
nMax=30; %nMax为阶数和重复数，用于控制最大嵌入容量
num=256; %num为水印长度 
% 1.PCET(T=13时能嵌入128bits) 2.PCT(T=18时能嵌入128bits)；3.PST(T=19时能嵌入128bits)
% 1.PCET(T=18时能嵌入256bits) 2.PCT(T=26时能嵌入256bits)；3.PST(T=27时能嵌入256bits)
Delta=32;%32;%固定值
seed_num=0;
rng(seed_num,'twister');
%% 预备环节（实验所需参数初始化）
N=size(I,1);
w =randi([0,1],1,num); 
d_0 = 1/8*Delta*ones(1,num);%7/8*Delta*ones(1,num);
% 最新结果，当d_0 = 7/8*Delta*ones(1,num);时可以取得较少的辅助信息量；但鲁棒性测试还未进行
% % 虽然Zernike矩使用了7/8，但实际上1/8和5/8才更有可能获得最佳效果。PHT矩采用其中一种
% d_0=1/4*Delta*ones(1,num);和d_0=3/4*Delta*ones(1,num);时都无法实现水印正常的提取。且后者的误码率更高（两倍左右）。

% d_0=zeros(1,num);和d_0=Delta*ones(1,num);时鲁棒性最强
%（但lena图，随机种子为0时的高斯抗性和JPEG2000抗性反而较差），辅助信息量最大，导致无法嵌入

% d_0=1/2*Delta*ones(1,num);时鲁棒性最弱，但辅助信息量最小（PHT矩时的辅助信息量也很大无法嵌入）

d_1 = d_0 + (Delta/2);%(Delta/2) - d_0;
%% 选择需要计算的PHT矩
% MMT=PCET_func(I,nMax);
if MODE==1
    MMT=PCET_func(I,nMax);
elseif MODE==2
    MMT=PCT_func(I,nMax);
elseif MODE==3
    MMT=PST_func(I,nMax);
else
    disp('Error!');
    return;
end
%% 首先确认水印嵌入顺序
% 调换顺序，便于嵌入
temp(1,:) = abs(MMT(1,:)+1i*MMT(2,:)); %模从小到大
temp(2,:)=MMT(1,:); %阶数
temp(3,:)=MMT(2,:); %重复数
temp(4,:)=MMT(3,:); %矩的大小
[Mnm,ind]=sortrows(temp'); % ind从前到后的顺序代表了阶数和重复数递增的顺序
Mnm = Mnm'; ind = ind'; %E是调整顺序后的PHT矩

% 自适应阈值
T_start=7000; %T和斜率按照PHT矩的情况再做调整
slide=10;%斜率
for k = 1 : length(Mnm)
    if mod(Mnm(3,k), 4) ~= 0
        T(k) = T_start-Mnm(1,k)*slide;
    end
end %T值增大PSNR提升，嵌入幅度减小
%% 确认嵌入的矩
moment = 0;
for k = 1 : length(Mnm)
    if MODE == 1
        if mod(Mnm(3,k), 4) ~= 0 
            if Mnm(2,k) == 0 && Mnm(3,k) > 0
                moment = moment + 1;
                tem(moment)=k;
            elseif Mnm(2,k) > 0
                moment = moment + 1;
                tem(moment)=k;
            end
        end
    elseif MODE == 2
        if mod(Mnm(3,k), 4) ~= 0 && Mnm(2,k)>=0 && Mnm(3,k) > 0
            moment = moment + 1;
            tem(moment)=k;
        end
    elseif MODE == 3
        if mod(Mnm(3,k), 4) ~= 0 && Mnm(2,k)>=1 && Mnm(3,k) > 0
            moment = moment + 1;
            tem(moment)=k;
        end
    end
end
%insert_palace = tem(1:num); %选择num个靠前的矩进行嵌入
insert_palace = tem;
%% 鲁棒性测试（抗旋转攻击）
% for l = 1 : 18 %7%
%     K_tem_rotate_robust = imrotate(uint8(I),l*20,'crop');%imrotate(uint8(Iw2),l*45,'crop');%
%     if MODE==1
%         MMT_rotate_robust=PCET_func(K_tem_rotate_robust,nMax);
%     elseif MODE==2
%         MMT_rotate_robust=PCT_func(K_tem_rotate_robust,nMax);
%     elseif MODE==3
%         MMT_rotate_robust=PST_func(K_tem_rotate_robust,nMax);
%     end
%     % 调换顺序，便于嵌入
%     temp_w2_rotate_robust(1,:) = abs(MMT_rotate_robust(1,:)+1i*MMT_rotate_robust(2,:)); %模从小到大
%     temp_w2_rotate_robust(2,:)=MMT_rotate_robust(1,:); %阶数
%     temp_w2_rotate_robust(3,:)=MMT_rotate_robust(2,:); %重复数
%     temp_w2_rotate_robust(4,:)=MMT_rotate_robust(3,:); %矩的大小
%     [Mnm_w2_rotate_robust,ind_w2_rotate_robust]=sortrows(temp_w2_rotate_robust'); % ind从前到后的顺序代表了阶数和重复数递增的顺序
%     Mnm_w2_rotate_robust = Mnm_w2_rotate_robust'; ind_w2_rotate_robust = ind_w2_rotate_robust'; %E是调整顺序后的PHT矩
%     moment = 0;
%     for k = 1 : length(Mnm_w2_rotate_robust)
%         if ismember(k,insert_palace)% && k<=insert_palace_max
%              moment = moment + 1;
%             moment_rotate_robust(l,moment)=abs(Mnm_w2_rotate_robust(4,k)-Mnm(4,k));
%         end
%     end
% end 
    
%% 鲁棒性测试（抗缩放攻击）
    K_tem_resize_robust =imresize(uint8(I),0.5);%imresize(uint8(Iw2),0.2+l*0.3);%
    [~, Cols_resize]=size(K_tem_resize_robust);
    if ~~(Cols_resize/2-floor(Cols_resize/2))
        K_tem_resize_robust = imresize(K_tem_resize_robust,[Cols_resize+1,Cols_resize+1]);
    end
    if MODE==1
        MMT_resize_robust=PCET_func(K_tem_resize_robust,nMax);
    elseif MODE==2
        MMT_resize_robust=PCT_func(K_tem_resize_robust,nMax);
    elseif MODE==3
        MMT_resize_robust=PST_func(K_tem_resize_robust,nMax);
    end
    % 调换顺序，便于嵌入
    temp_w2_resize_robust(1,:) = abs(MMT_resize_robust(1,:)+1i*MMT_resize_robust(2,:)); %模从小到大
    temp_w2_resize_robust(2,:)=MMT_resize_robust(1,:); %阶数
    temp_w2_resize_robust(3,:)=MMT_resize_robust(2,:); %重复数
    temp_w2_resize_robust(4,:)=MMT_resize_robust(3,:); %矩的大小
    [Mnm_w2_resize_robust,ind_w2_resize_robust]=sortrows(temp_w2_resize_robust'); % ind从前到后的顺序代表了阶数和重复数递增的顺序
    Mnm_w2_resize_robust = Mnm_w2_resize_robust'; ind_w2_resize_robust = ind_w2_resize_robust'; %E是调整顺序后的PHT矩
    moment = 0;
    for k = 1 : length(Mnm_w2_resize_robust)
        if ismember(k,insert_palace)% && k<=insert_palace_max
            moment = moment + 1;
            moment_resize_robust(moment)=abs(Mnm_w2_resize_robust(4,k)-Mnm(4,k));
        end
    end

%% 鲁棒性测试（抗高斯噪声攻击）
K_tem_gaussian_robust = imnoise(uint8(I), 'gaussian', 0, 0.029);
if MODE==1
    MMT_gaussian_robust=PCET_func(K_tem_gaussian_robust,nMax);
elseif MODE==2
    MMT_gaussian_robust=PCT_func(K_tem_gaussian_robust,nMax);
elseif MODE==3
    MMT_gaussian_robust=PST_func(K_tem_gaussian_robust,nMax);
end
% 调换顺序，便于嵌入
temp_w2_gaussian_robust(1,:) = abs(MMT_gaussian_robust(1,:)+1i*MMT_gaussian_robust(2,:)); %模从小到大
temp_w2_gaussian_robust(2,:)=MMT_gaussian_robust(1,:); %阶数
temp_w2_gaussian_robust(3,:)=MMT_gaussian_robust(2,:); %重复数
temp_w2_gaussian_robust(4,:)=MMT_gaussian_robust(3,:); %矩的大小
[Mnm_w2_gaussian_robust,ind_w2_gaussian_robust]=sortrows(temp_w2_gaussian_robust'); % ind从前到后的顺序代表了阶数和重复数递增的顺序
Mnm_w2_gaussian_robust = Mnm_w2_gaussian_robust'; ind_w2_gaussian_robust = ind_w2_gaussian_robust'; %E是调整顺序后的PHT矩
moment = 0;
for k = 1 : length(Mnm_w2_gaussian_robust)
    if ismember(k,insert_palace)% && k<=insert_palace_max
        moment = moment + 1;
        moment_gaussian_robust(moment)=abs(Mnm_w2_gaussian_robust(4,k)-Mnm(4,k));
    end
end

%% 鲁棒性测试（抗JPEG攻击）
imwrite(uint8(I),'Iw_jpeg_compress.jpg','Quality',10);
K_tem_jpeg_robust = imread('Iw_jpeg_compress.jpg');
if MODE==1
    MMT_jpeg_robust=PCET_func(K_tem_jpeg_robust,nMax);
elseif MODE==2
    MMT_jpeg_robust=PCT_func(K_tem_jpeg_robust,nMax);
elseif MODE==3
    MMT_jpeg_robust=PST_func(K_tem_jpeg_robust,nMax);
end
% 调换顺序，便于嵌入
temp_w2_jpeg_robust(1,:) = abs(MMT_jpeg_robust(1,:)+1i*MMT_jpeg_robust(2,:)); %模从小到大
temp_w2_jpeg_robust(2,:)=MMT_jpeg_robust(1,:); %阶数
temp_w2_jpeg_robust(3,:)=MMT_jpeg_robust(2,:); %重复数
temp_w2_jpeg_robust(4,:)=MMT_jpeg_robust(3,:); %矩的大小
[Mnm_w2_jpeg_robust,ind_w2_jpeg_robust]=sortrows(temp_w2_jpeg_robust'); % ind从前到后的顺序代表了阶数和重复数递增的顺序
Mnm_w2_jpeg_robust = Mnm_w2_jpeg_robust'; ind_w2_jpeg_robust = ind_w2_jpeg_robust'; %E是调整顺序后的PHT矩
moment = 0;
for k = 1 : length(Mnm_w2_jpeg_robust)
    if ismember(k,insert_palace)% && k<=insert_palace_max
        moment = moment + 1;
        moment_jpeg_robust(moment)=abs(Mnm_w2_jpeg_robust(4,k)-Mnm(4,k));
    end
end

%% 鲁棒性测试（抗JPEG2000攻击）
imwrite(uint8(I),'Iw_jpeg2000_compress.jp2','CompressionRatio',100);
K_tem_jpeg2000_robust = imread('Iw_jpeg2000_compress.jp2');
if MODE==1
    MMT_jpeg2000_robust=PCET_func(K_tem_jpeg2000_robust,nMax);
elseif MODE==2
    MMT_jpeg2000_robust=PCT_func(K_tem_jpeg2000_robust,nMax);
elseif MODE==3
    MMT_jpeg2000_robust=PST_func(K_tem_jpeg2000_robust,nMax);
end
% 调换顺序，便于嵌入
temp_w2_jpeg2000_robust(1,:) = abs(MMT_jpeg2000_robust(1,:)+1i*MMT_jpeg2000_robust(2,:)); %模从小到大
temp_w2_jpeg2000_robust(2,:)=MMT_jpeg2000_robust(1,:); %阶数
temp_w2_jpeg2000_robust(3,:)=MMT_jpeg2000_robust(2,:); %重复数
temp_w2_jpeg2000_robust(4,:)=MMT_jpeg2000_robust(3,:); %矩的大小
[Mnm_w2_jpeg2000_robust,ind_w2_jpeg2000_robust]=sortrows(temp_w2_jpeg2000_robust'); % ind从前到后的顺序代表了阶数和重复数递增的顺序
Mnm_w2_jpeg2000_robust = Mnm_w2_jpeg2000_robust'; ind_w2_jpeg2000_robust = ind_w2_jpeg2000_robust'; %E是调整顺序后的PHT矩
moment = 0;
for k = 1 : length(Mnm_w2_jpeg2000_robust)
    if ismember(k,insert_palace)% && k<=insert_palace_max
        moment = moment + 1;
        moment_jpeg2000_robust(moment)=abs(Mnm_w2_jpeg2000_robust(4,k)-Mnm(4,k));
    end
end

%% 数据整理
sum=0;
for i= 1 : 13
    attack_mean(1,i)=mean(mean(moment_resize_robust(1,sum+1:sum+50)));%resize
    attack_mean(2,i)=mean(mean(moment_gaussian_robust(1,sum+1:sum+50)));%gaussian
    attack_mean(3,i)=mean(mean(moment_jpeg_robust(1,sum+1:sum+50)));%jpeg
    attack_mean(4,i)=mean(mean(moment_jpeg2000_robust(1,sum+1:sum+50)));%jpeg2000
    attack_std(1,i)=std(moment_resize_robust(1,sum+1:sum+50),0,2)^2;
    attack_std(2,i)=std(moment_gaussian_robust(1,sum+1:sum+50),0,2)^2;
    attack_std(3,i)=std(moment_jpeg_robust(1,sum+1:sum+50),0,2)^2;
    attack_std(4,i)=std(moment_jpeg2000_robust(1,sum+1:sum+50),0,2)^2;
    sum=sum+50;
end
attack_mean(1,14)=mean(mean(moment_resize_robust(1,sum+1:sum+47)));%651-697
attack_mean(1,15)=mean(mean(moment_resize_robust)); %整体均值
attack_mean(2,14)=mean(mean(moment_gaussian_robust(1,sum+1:sum+47)));%651-697
attack_mean(2,15)=mean(mean(moment_gaussian_robust)); %整体均值
attack_mean(3,14)=mean(mean(moment_jpeg_robust(1,sum+1:sum+47)));%651-697
attack_mean(3,15)=mean(mean(moment_jpeg_robust)); %整体均值
attack_mean(4,14)=mean(mean(moment_jpeg2000_robust(1,sum+1:sum+47)));%651-697
attack_mean(4,15)=mean(mean(moment_jpeg2000_robust)); %整体均值
attack_std(1,14)=std(moment_resize_robust(1,sum+1:sum+47),0,2)^2;%651-697
attack_std(1,15)=std(moment_resize_robust,0,2)^2; %整体方差
attack_std(2,14)=std(moment_gaussian_robust(1,sum+1:sum+47),0,2)^2;%651-697
attack_std(2,15)=std(moment_gaussian_robust,0,2)^2; %整体方差
attack_std(3,14)=std(moment_jpeg_robust(1,sum+1:sum+47),0,2)^2;%651-697
attack_std(3,15)=std(moment_jpeg_robust,0,2)^2; %整体方差
attack_std(4,14)=std(moment_jpeg2000_robust(1,sum+1:sum+47),0,2)^2;%651-697
attack_std(4,15)=std(moment_jpeg2000_robust,0,2)^2; %整体方差
