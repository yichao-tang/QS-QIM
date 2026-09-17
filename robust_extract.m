function [w_3] = robust_extract(Iw_1, nMax, T, Delta , w ,MODE) 
%输入：图像Iw_1，矩阵最大阶数nMax，振幅大小T，步长Delta，水印长度wl
%输出：提取的鲁棒水印w_3
%% 鲁棒水印提取（需要测试鲁棒性时使用）
wl=length(w);
%% 选择需要计算的PHT矩
if MODE==1
    [MMT,~]=PCET_func(uint8(Iw_1),nMax);
elseif MODE==2
    [MMT,H]=FrPCET_func(uint8(Iw_1),nMax,1.4);
%     [MMT,H]=PCT_func(I,nMax);
elseif MODE==3
    [MMT,H]=PST_func(I,nMax);
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
% temp(5,:)=1:length(MMT); %矩的大小
[Mnm,ind]=sortrows(temp'); % ind从前到后的顺序代表了阶数和重复数递增的顺序
Mnm = Mnm'; ind = ind'; %E是调整顺序后的PHT矩

%% 确认嵌入的矩
moment = 0;
for k = 1 : length(Mnm)
    if MODE == 1
        if mod(Mnm(3,k), 4) ~= 0 
            if Mnm(3,k) >=0 
                moment = moment + 1;
                tem(moment)=k; 
            end
        end
    elseif MODE == 2
        if mod(Mnm(3,k), 4) ~= 0 && Mnm(3,k) >= 0%&& Mnm(2,k)>=0 && Mnm(3,k) > 0
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
insert_palace = tem(1:2*wl); %选择num个靠前的矩进行嵌入
% w =randi([0,1],1,wl); 
%% 正式提取
i = 0;
ti = 0;
lastK = 1;
num = 0;
for k = 1 : length(Mnm)
    if ismember(k,insert_palace)
        
        ti = ti + 1;
        if ti == 2
            i = i + 1;
            MR2(i)=Mnm(4,lastK)*T; %ZR为论文中归一化后的AR
            num = num + 1;
            i = i + 1;
            MR2(i)=Mnm(4,k)*T;


            [H,J,d,~]= getPa();
            [~,wi,~] = spheredecodetoML( [abs(MR2(i-1));abs(MR2(i))], d, H,J);
            w_3(num)=wi;
            ti = 0;
        end
        lastK  = k;    
    end
end


w_3 ;



