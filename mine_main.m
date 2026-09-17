clear
clc
I = imread('lena.bmp');
img=double(I);
MODE = 1; %用于转换
%1.PCET(T=15时能嵌入191bits)；2.PCT(T=15时只能嵌入96bits)；3.PST(T=15时只能嵌入84bits)
nMax=2; %nMax为阶数和重复数，用于控制最大嵌入容量
num=256; %num为水印长度 
% 1.PCET(T=13时能嵌入128bits) 2.PCT(T=18时能嵌入128bits)；3.PST(T=19时能嵌入128bits)
% 1.PCET(T=18时能嵌入256bits) 2.PCT(T=26时能嵌入256bits)；3.PST(T=27时能嵌入256bits)
Delta=1;%32;%固定值
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
insert_palace = tem(1:num); %选择num个靠前的矩进行嵌入
%% 水印嵌入
moment = 0;
for k = 1 : length(Mnm)
    if ismember(k,insert_palace)
        moment = moment + 1;
        %选择重复数不为4的倍数的矩进行嵌入，嵌入的同时应修改对应的值
         if w(moment)==0 %论文中公式（12）
            Mw(k)=floor(Mnm(4,k)/Delta)*Delta;
        elseif w(moment)==1
            Mw(k)=floor((Mnm(4,k)-Delta/2)/Delta)*Delta;
        end
    end
end

mine_insert(I,nMax,Mw,insert_palace);




%      if ismember(k,insert_palace)
%         Iw=Iw+((Mw/MMT(3,k))-1).*H.*MMT(3,k);
%     end
%      Ir=abs(Ir);












if MODE==1
    Irw1=PCET_reconstruct_func(N,M_1); %重构出水印差值图像，并加上原图得到水印图像
elseif MODE==2
    Irw1=PCT_reconstruct_func(N,M_1); 
elseif MODE==3
    Irw1=PST_reconstruct_func(N,M_1); 
end
% % 不使用舍入重构操作时注释
% Irw1(isnan(Irw1))=0; %矩外的NaN部分置零
% Iw1 = round(double(I) + Irw1);
% Iw1(Iw1>255)=255;
% Iw1(Iw1<0)=0;
% psnr_Iw1 = psnr(I,uint8(Iw1)) %计算鲁棒水印嵌入后的PSNR

% % 使用舍入重构操作时注释
Irw1(isnan(Irw1))=0; %矩外的NaN部分置零
Iw2 = round(double(I) + Irw1);
Iw2(Iw2>255)=255;
Iw2(Iw2<0)=0;
% 此时的Iw2就是鲁棒水印图像
psnr_Iw1 = psnr(I,uint8(Iw2)) %计算鲁棒水印嵌入后的PSNR
%% 计算鲁棒水印图像的PHT矩（舍入重构操作1）(PHT矩舍入重构操作无效，因为舍入导致的误差实在太小)
% if MODE==1
%     MMT_1=PCET_func(uint8(Iw1),nMax);
% elseif MODE==2
%     MMT_1=PCT_func(uint8(Iw1),nMax);
% elseif MODE==3
%     MMT_1=PST_func(uint8(Iw1),nMax);
% end
% % 调换顺序，便于嵌入
% temp_w(1,:) = abs(MMT_1(1,:)+1i*MMT_1(2,:)); %模从小到大
% temp_w(2,:)=MMT_1(1,:); %阶数
% temp_w(3,:)=MMT_1(2,:); %重复数
% temp_w(4,:)=MMT_1(3,:); %矩的大小
% [Mnm_w,ind_w]=sortrows(temp_w'); % ind从前到后的顺序代表了阶数和重复数递增的顺序
% Mnm_w = Mnm_w'; ind_w = ind_w'; %E是调整顺序后的PHT矩
% 
% %% 将重构前后的矩的误差进行二次嵌入（舍入重构操作2）
% moment = 0;
% for k = 1 : length(Mnm_w)
%     if ismember(k,insert_palace)
%         moment = moment + 1;
%         if MODE == 1
%             %（PCET在修改第nm个时还需同时修改第(-n)(-m)个）
%             [~,col]=find(Mnm_w(2,:)==-Mnm_w(2,k) & Mnm_w(3,:)==-Mnm_w(3,k));
%             Mw(col) = conj(Mw(k));
%             M_2(1,k)=Mnm_w(1,k);M_2(2,k)=Mnm_w(2,k);M_2(3,k)=Mnm_w(3,k);
%             M_2(4,k)=Mw(k)-Mnm_w(4,k);
%             M_2(1,col)=Mnm_w(1,col);M_2(2,col)=Mnm_w(2,col);M_2(3,col)=Mnm_w(3,col);
%             M_2(4,col)=Mw(col)-Mnm_w(4,col); % 水印嵌入更改的矩，然后将其进行重构
%         elseif MODE == 2
%             %（PCT在修改第nm个时还需同时修改第n(-m)个）
%             [~,col]=find(Mnm_w(2,:)==Mnm_w(2,k) & Mnm_w(3,:)==-Mnm_w(3,k));
%             Mw(col) = conj(Mw(k));
%             M_2(1,k)=Mnm_w(1,k);M_2(2,k)=Mnm_w(2,k);M_2(3,k)=Mnm_w(3,k);
%             M_2(4,k)=Mw(k)-Mnm_w(4,k);
%             M_2(1,col)=Mnm_w(1,col);M_2(2,col)=Mnm_w(2,col);M_2(3,col)=Mnm_w(3,col);
%             M_2(4,col)=Mw(col)-Mnm_w(4,col); % 水印嵌入更改的矩，然后将其进行重构
%         elseif MODE == 3
%             %（PCT在修改第nm个时还需同时修改第n(-m)个）
%             [~,col]=find(Mnm_w(2,:)==Mnm_w(2,k) & Mnm_w(3,:)==-Mnm_w(3,k));
%             Mw(col) = conj(Mw(k));
%             M_2(1,k)=Mnm_w(1,k);M_2(2,k)=Mnm_w(2,k);M_2(3,k)=Mnm_w(3,k);
%             M_2(4,k)=Mw(k)-Mnm_w(4,k);
%             M_2(1,col)=Mnm_w(1,col);M_2(2,col)=Mnm_w(2,col);M_2(3,col)=Mnm_w(3,col);
%             M_2(4,col)=Mw(col)-Mnm_w(4,col); % 水印嵌入更改的矩，然后将其进行重构
%         end
%     end
% end
% 
% if MODE==1
%     Irw2=PCET_reconstruct_func(N,M_2); %重构出水印差值图像，并加上原图得到水印图像
% elseif MODE==2
%     Irw2=PCT_reconstruct_func(N,M_2); 
% elseif MODE==3
%     Irw2=PST_reconstruct_func(N,M_2); 
% end
% % 
% Irw2(isnan(Irw2))=0; %矩外的NaN部分置零
% Iw2 = round(Iw1 + Irw2);
% Iw2(Iw2>255)=255;
% Iw2(Iw2<0)=0;
% psnr_Iw2 = psnr(I,uint8(Iw2)) %计算二次嵌入后的PSNR
% 
% check_Reconstruct=isequal(Iw2,Iw1);
%% （二次嵌入后的）鲁棒水印图像PHT矩(用于生成中间无水印图像以及用于提取鲁棒水印)
if MODE==1
    MMT_2=PCET_func(uint8(Iw2),nMax);
elseif MODE==2
    MMT_2=PCT_func(uint8(Iw2),nMax);
elseif MODE==3
    MMT_2=PST_func(uint8(Iw2),nMax);
end
% 调换顺序，便于嵌入
temp_w2(1,:) = abs(MMT_2(1,:)+1i*MMT_2(2,:)); %模从小到大
temp_w2(2,:)=MMT_2(1,:); %阶数
temp_w2(3,:)=MMT_2(2,:); %重复数
temp_w2(4,:)=MMT_2(3,:); %矩的大小
[Mnm_w2,ind_w2]=sortrows(temp_w2'); % ind从前到后的顺序代表了阶数和重复数递增的顺序
Mnm_w2 = Mnm_w2'; ind_w2 = ind_w2'; %E是调整顺序后的PHT矩
%% 鲁棒水印提取（确认嵌入是否准确）
moment = 0;
for k = 1 : length(Mnm_w2)
    if ismember(k,insert_palace)% && k<=insert_palace_max
        moment = moment + 1;
        MRnm_w(k) = (Mnm_w2(4,k)/Mnm_w2(4,1))*T(k);
        MRnm_w_j(1,k)=round((abs(MRnm_w(k))-d_0(moment))/Delta)*Delta+d_0(moment); %第一行存储随机数组为0时的情况
        MRnm_w_j(2,k)=round((abs(MRnm_w(k))-d_1(moment))/Delta)*Delta+d_1(moment); %第二行存储随机数组为1时的情况
        if (abs(MRnm_w(k))-abs(MRnm_w_j(1,k)))^2 <= (abs(MRnm_w(k))-abs(MRnm_w_j(2,k)))^2 %若原zernike矩更接近随机数组为0时的情况
            w_ex(moment) = 0;
        else
            w_ex(moment) = 1;
        end
        w_be(moment)=w(moment); %判断提取是否成功
        MRnm_re(k) = abs(MRnm_w(k))-d_int(moment);
        Mnm_re(k) = abs(MRnm_re(k)/abs(MRnm_w(k)))*Mnm_w2(4,k);
        if MODE == 1 %用于计算中间无水印图像的矩
            %（PCET在修改第nm个时还需同时修改第(-n)(-m)个）
            [~,col]=find(Mnm_w2(2,:)==-Mnm_w2(2,k) & Mnm_w2(3,:)==-Mnm_w2(3,k));
            Mnm_re(col) = conj(Mnm_re(k));
            M_3(1,k)=Mnm_w2(1,k);M_3(2,k)=Mnm_w2(2,k);M_3(3,k)=Mnm_w2(3,k);
            M_3(4,k)=Mnm_re(k)-Mnm_w2(4,k);
            M_3(1,col)=Mnm_w2(1,col);M_3(2,col)=Mnm_w2(2,col);M_3(3,col)=Mnm_w2(3,col);
            M_3(4,col)=Mnm_re(col)-Mnm_w2(4,col); % 水印嵌入更改的矩，然后将其进行重构
        elseif MODE == 2
            %（PCT在修改第nm个时还需同时修改第n(-m)个）
            [~,col]=find(Mnm_w2(2,:)==Mnm_w2(2,k) & Mnm_w2(3,:)==-Mnm_w2(3,k));
            Mnm_re(col) = conj(Mnm_re(k));
            M_3(1,k)=Mnm_w2(1,k);M_3(2,k)=Mnm_w2(2,k);M_3(3,k)=Mnm_w2(3,k);
            M_3(4,k)=Mnm_re(k)-Mnm_w2(4,k);
            M_3(1,col)=Mnm_w2(1,col);M_3(2,col)=Mnm_w2(2,col);M_3(3,col)=Mnm_w2(3,col);
            M_3(4,col)=Mnm_re(col)-Mnm_w2(4,col); % 水印嵌入更改的矩，然后将其进行重构
        elseif MODE == 3
            %（PCT在修改第nm个时还需同时修改第n(-m)个）
            [~,col]=find(Mnm_w2(2,:)==Mnm_w2(2,k) & Mnm_w2(3,:)==-Mnm_w2(3,k));
            Mnm_re(col) = conj(Mnm_re(k));
            M_3(1,k)=Mnm_w2(1,k);M_3(2,k)=Mnm_w2(2,k);M_3(3,k)=Mnm_w2(3,k);
            M_3(4,k)=Mnm_re(k)-Mnm_w2(4,k);
            M_3(1,col)=Mnm_w2(1,col);M_3(2,col)=Mnm_w2(2,col);M_3(3,col)=Mnm_w2(3,col);
            M_3(4,col)=Mnm_re(col)-Mnm_w2(4,col); % 水印嵌入更改的矩，然后将其进行重构
        end
    end
end
%% 判断提取是否成功
isequal(w_ex,w_be)
te=sum(abs(w_be-w_ex));
BER_no_attack = te/length(w_ex);
%% 鲁棒性测试（抗旋转攻击）
for l = 1 : 18 %7%
    K_tem_rotate_robust = imrotate(uint8(Iw2),l*20,'crop');%imrotate(uint8(Iw2),l*45,'crop');%
    if MODE==1
        MMT_rotate_robust=PCET_func(K_tem_rotate_robust,nMax);
    elseif MODE==2
        MMT_rotate_robust=PCT_func(K_tem_rotate_robust,nMax);
    elseif MODE==3
        MMT_rotate_robust=PST_func(K_tem_rotate_robust,nMax);
    end
    % 调换顺序，便于嵌入
    temp_w2_rotate_robust(1,:) = abs(MMT_rotate_robust(1,:)+1i*MMT_rotate_robust(2,:)); %模从小到大
    temp_w2_rotate_robust(2,:)=MMT_rotate_robust(1,:); %阶数
    temp_w2_rotate_robust(3,:)=MMT_rotate_robust(2,:); %重复数
    temp_w2_rotate_robust(4,:)=MMT_rotate_robust(3,:); %矩的大小
    [Mnm_w2_rotate_robust,ind_w2_rotate_robust]=sortrows(temp_w2_rotate_robust'); % ind从前到后的顺序代表了阶数和重复数递增的顺序
    Mnm_w2_rotate_robust = Mnm_w2_rotate_robust'; ind_w2_rotate_robust = ind_w2_rotate_robust'; %E是调整顺序后的PHT矩
    moment = 0;
    for k = 1 : length(Mnm_w2_rotate_robust)
        if ismember(k,insert_palace)% && k<=insert_palace_max
            moment = moment + 1;
            MRnm_w_rotate_robust(k) = (Mnm_w2_rotate_robust(4,k)/Mnm_w2_rotate_robust(4,1))*T(k);
            MRnm_w_j_rotate_robust(1,k)=round((abs(MRnm_w_rotate_robust(k))-d_0(moment))/Delta)*Delta+d_0(moment); %第一行存储随机数组为0时的情况
            MRnm_w_j_rotate_robust(2,k)=round((abs(MRnm_w_rotate_robust(k))-d_1(moment))/Delta)*Delta+d_1(moment); %第二行存储随机数组为1时的情况
            if (abs(MRnm_w_rotate_robust(k))-abs(MRnm_w_j_rotate_robust(1,k)))^2 ...
                    <= (abs(MRnm_w_rotate_robust(k))-abs(MRnm_w_j_rotate_robust(2,k)))^2 %若原zernike矩更接近随机数组为0时的情况
                w_ex_rotate_robust(moment) = 0;
            else
                w_ex_rotate_robust(moment) = 1;
            end
            w_be_rotate_robust(moment)=w(moment); %判断提取是否成功
        end
    end
    te_rotate_robust(l)=sum(abs(w_be_rotate_robust-w_ex_rotate_robust));
    BER_rotate_robust(l) = te_rotate_robust(l)/length(w_ex_rotate_robust);
end
%% 鲁棒性测试（抗缩放攻击）
for l = 1 : 16%6%
    K_tem_resize_robust =imresize(uint8(Iw2),0.4+l*0.1);%imresize(uint8(Iw2),0.2+l*0.3);%
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
            MRnm_w_resize_robust(k) = (Mnm_w2_resize_robust(4,k)/Mnm_w2_resize_robust(4,1))*T(k);
            MRnm_w_j_resize_robust(1,k)=round((abs(MRnm_w_resize_robust(k))-d_0(moment))/Delta)*Delta+d_0(moment); %第一行存储随机数组为0时的情况
            MRnm_w_j_resize_robust(2,k)=round((abs(MRnm_w_resize_robust(k))-d_1(moment))/Delta)*Delta+d_1(moment); %第二行存储随机数组为1时的情况
            if (abs(MRnm_w_resize_robust(k))-abs(MRnm_w_j_resize_robust(1,k)))^2 ...
                    <= (abs(MRnm_w_resize_robust(k))-abs(MRnm_w_j_resize_robust(2,k)))^2 %若原zernike矩更接近随机数组为0时的情况
                w_ex_resize_robust(moment) = 0;
            else
                w_ex_resize_robust(moment) = 1;
            end
            w_be_resize_robust(moment)=w(moment); %判断提取是否成功
        end
    end
    te_resize_robust(l)=sum(abs(w_be_resize_robust-w_ex_resize_robust));
    BER_resize_robust(l) = te_resize_robust(l)/length(w_ex_resize_robust);
end
%% 鲁棒性测试（抗高斯噪声攻击）
for l = 1 : 13 %7%
    K_tem_gaussian_robust = imnoise(uint8(Iw2), 'gaussian', 0, 0.005+(l-1)*0.002);%方差为0.03的高斯噪声 %imnoise(uint8(Iw2), 'gaussian', 0, 0.005+(l-1)*0.004); %
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
            MRnm_w_gaussian_robust(k) = (Mnm_w2_gaussian_robust(4,k)/Mnm_w2_gaussian_robust(4,1))*T(k);
            MRnm_w_j_gaussian_robust(1,k)=round((abs(MRnm_w_gaussian_robust(k))-d_0(moment))/Delta)*Delta+d_0(moment); %第一行存储随机数组为0时的情况
            MRnm_w_j_gaussian_robust(2,k)=round((abs(MRnm_w_gaussian_robust(k))-d_1(moment))/Delta)*Delta+d_1(moment); %第二行存储随机数组为1时的情况
            if (abs(MRnm_w_gaussian_robust(k))-abs(MRnm_w_j_gaussian_robust(1,k)))^2 ...
                    <= (abs(MRnm_w_gaussian_robust(k))-abs(MRnm_w_j_gaussian_robust(2,k)))^2 %若原zernike矩更接近随机数组为0时的情况
                w_ex_gaussian_robust(moment) = 0;
            else
                w_ex_gaussian_robust(moment) = 1;
            end
            w_be_gaussian_robust(moment)=w(moment); %判断提取是否成功
        end
    end
    te_gaussian_robust(l)=sum(abs(w_be_gaussian_robust-w_ex_gaussian_robust));
    BER_gaussian_robust(l) = te_gaussian_robust(l)/length(w_ex_gaussian_robust);
end
%% 鲁棒性测试（抗JPEG攻击）
for l = 1 : 10% 5%
%     imwrite(uint8(Iw2),'Iw_jpeg_compress.jpg','Quality',10+(l-1)*20);
    imwrite(uint8(Iw2),'Iw_jpeg_compress.jpg','Quality',10*l);
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
            MRnm_w_jpeg_robust(k) = (Mnm_w2_jpeg_robust(4,k)/Mnm_w2_jpeg_robust(4,1))*T(k);
            MRnm_w_j_jpeg_robust(1,k)=round((abs(MRnm_w_jpeg_robust(k))-d_0(moment))/Delta)*Delta+d_0(moment); %第一行存储随机数组为0时的情况
            MRnm_w_j_jpeg_robust(2,k)=round((abs(MRnm_w_jpeg_robust(k))-d_1(moment))/Delta)*Delta+d_1(moment); %第二行存储随机数组为1时的情况
            if (abs(MRnm_w_jpeg_robust(k))-abs(MRnm_w_j_jpeg_robust(1,k)))^2 ...
                    <= (abs(MRnm_w_jpeg_robust(k))-abs(MRnm_w_j_jpeg_robust(2,k)))^2 %若原zernike矩更接近随机数组为0时的情况
                w_ex_jpeg_robust(moment) = 0;
            else
                w_ex_jpeg_robust(moment) = 1;
            end
            w_be_jpeg_robust(moment)=w(moment); %判断提取是否成功
        end
    end
    te_jpeg_robust(l)=sum(abs(w_be_jpeg_robust-w_ex_jpeg_robust));
    BER_jpeg_robust(l) = te_jpeg_robust(l)/length(w_ex_jpeg_robust);
end
%% 鲁棒性测试（抗JPEG2000攻击）
for l = 1 : 10%5%
%     imwrite(uint8(Iw2),'Iw_jpeg2000_compress.jp2','CompressionRatio',10+(l-1)*20);
    imwrite(uint8(Iw2),'Iw_jpeg2000_compress.jp2','CompressionRatio',10*l);
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
            MRnm_w_jpeg2000_robust(k) = (Mnm_w2_jpeg2000_robust(4,k)/Mnm_w2_jpeg2000_robust(4,1))*T(k);
            MRnm_w_j_jpeg2000_robust(1,k)=round((abs(MRnm_w_jpeg2000_robust(k))-d_0(moment))/Delta)*Delta+d_0(moment); %第一行存储随机数组为0时的情况
            MRnm_w_j_jpeg2000_robust(2,k)=round((abs(MRnm_w_jpeg2000_robust(k))-d_1(moment))/Delta)*Delta+d_1(moment); %第二行存储随机数组为1时的情况
            if (abs(MRnm_w_jpeg2000_robust(k))-abs(MRnm_w_j_jpeg2000_robust(1,k)))^2 ...
                    <= (abs(MRnm_w_jpeg2000_robust(k))-abs(MRnm_w_j_jpeg2000_robust(2,k)))^2 %若原zernike矩更接近随机数组为0时的情况
                w_ex_jpeg2000_robust(moment) = 0;
            else
                w_ex_jpeg2000_robust(moment) = 1;
            end
            w_be_jpeg2000_robust(moment)=w(moment); %判断提取是否成功
        end
    end
    te_jpeg2000_robust(l)=sum(abs(w_be_jpeg2000_robust-w_ex_jpeg2000_robust));
    BER_jpeg2000_robust(l) = te_jpeg2000_robust(l)/length(w_ex_jpeg2000_robust);
end
%% 重构出与原图近似的中间无水印图像，用以进行二阶段嵌入（辅助信息计算部分，用于测试三01）
if MODE==1
    Irw_re=PCET_reconstruct_func(N,M_3); %重构出中间无水印图像
elseif MODE==2
    Irw_re=PCT_reconstruct_func(N,M_3); 
elseif MODE==3
    Irw_re=PST_reconstruct_func(N,M_3); 
end

Irw_re(isnan(Irw_re))=0;
I_re = round(Irw_re + Iw2);
I_re(I_re>255)=255;
I_re(I_re<0)=0;
err = double(I)-I_re;
psnr_Iw_re = psnr(I,uint8(I_re)) %计算中间无水印图像与原图的PSNR（测试结果一般>70）
%% 计算重构出来的图像与原图像误差大小，并计算二阶段需要嵌入的数据量（辅助信息计算部分，用于测试三02）
% 选择内切圆中的误差像素
[X,Y]=meshgrid(-1:(2/(N-1)):1,-1:(2/(N-1)):1);
[~,r] = cart2pol(X,Y); %直角坐标转化为极坐标
idx = uint8(r<=1);

temp = 0;
for i = 1 : N
    for j = 1 : N
        if (idx(i, j) == 1)
            temp = temp + 1;
            err_incircle(temp) = uint8(I_re(i,j))-I(i,j);
            continue
        end
    end
end
% 整体矩阵压缩
tem_length1 = length(dec2bin(max(abs(err_incircle))));
[ dq_1 ] = signed_to_bin(err_incircle,tem_length1+1); %差值转二进制（此处差值最大为17，五位二进制即可；计算得出共需648bits）
dq_C = cell(1,1);
dq_C{1} = dq_1;
dq_data = Arith07(dq_C); %算数编码压缩
[ dq_D ] = unsigned_to_bin( dq_data,8 );%编码值转二进制
dq_beta=dq_D; %可逆水印（经过算数编码压缩）
%% 可逆水印嵌入
err = dq_beta;
err=logical(err);
[Iw_reversible, ~, Ok, ~, ~, ~, ~, ~, ~] ...
        = reversible_embedding(Iw2, err, N, N, idx) ;
psnr_Iw3 = psnr(I,uint8(Iw_reversible))
 imwrite(uint8(Iw_reversible),'Iw_reversible.bmp'); %测试输出图像
%% 可逆水印提取
% [Iw_1,err_info] = reversible_decodding(Iw_reversible, N, N, idx); %可逆提取
% check_img=isequal(Iw_1,Iw2); %验证图像提取成功 %Iw2是鲁棒水印图像
% check_err= isequal(err_info,err); %验证水印提取成功
% 
% % 解码
% data_2=err_info; %经过算数编码压缩时
% [ data ] = bin_to_unsigned( data_2,8);
% xR = Arith07(data'); %算数解码
% d1_2 = xR{1};
% [ d1 ] =  bin_to_signed( d1_2(:)',tem_length1+1);%得到原始差值
% check_info=isequal(err_incircle,d1); %验证可逆嵌入和可逆提取得到的信息相同
% I_ori=uint8(I_re);
% temp = 0;
% for i = 1 : N
%     for j = 1 : N
%         if (idx(i, j) == 1)
%             temp = temp + 1;
%             I_ori(i,j)=uint8(I_re(i,j))-uint8(d1(temp));
%         end
%     end
% end
% check_I=isequal(I_ori,I); %验证水印可逆，并提取原始图像
% psnr_Iw4 = psnr(I_ori,I) 
% %理论上提取水印后的图像与原始图像完全一致，但此处得到的却稍有偏差，暂时不确定是何原因。
%% 
% re=uint8(I_re)-I;
% I_or=uint8(I_re)-re;
% isequal(I_or,I) %这样都不能完全一致，有点不能理解
