function [Iw1,reversible_watermarking,psnr_Iw1] = embedded_main(I, nMax, T, Delta, w,MODE)
% % 目前本代码未复现原图提取的工作，若有需要再行添加。
%输入：图像img，矩阵最大阶数nMax，振幅大小T，步长Delta，水印长度wl
%输出：鲁棒嵌入图像lw1，补偿信息reversible_watermarking，鲁棒嵌入图像PSNR
img=double(I);
wl=length(w);
%% 选择需要计算的PHT矩
% MMT=PCET_func(I,nMax);
if MODE==1
    [MMT,~]=PCET_func(I,nMax);
elseif MODE==2
    [MMT,H]=FrPCET_func(I,nMax,1.4);
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
% temp(5,:)=1:length(MMT); %矩的序号
[Mnm,ind]=sortrows(temp'); % ind从前到后的顺序代表了阶数和重复数递增的顺序
Mnm = Mnm'; ind = ind'; %E是调整顺序后的PHT矩

%% 确认嵌入的矩
moment = 0;
for k = 1 : length(Mnm)
    if MODE == 1
        if mod(Mnm(3,k), 4) ~= 0&& Mnm(3,k) >=0 
                moment = moment + 1;
                tem(moment)=k; 
        end
    end
end
insert_palace = tem(1:2*wl); %选择num个靠前的矩进行嵌入
%% 鲁棒嵌入&计算补偿信息
i = 0;
ti = 0;
lastK = 1;
num = 0;
for k = 1 : length(Mnm)
    if ismember(k,insert_palace)
        ti = ti + 1;
        if ti == 2
        num = num + 1;
        i = i + 1;
        MR(i)=Mnm(4,lastK)*T; %ZR为论文中归一化后的AR
        De(i)=abs(MR(i))-floor(abs(MR(i)));
        
%         
%         if w(i)==1 %论文中公式（12）
%             MRw(i)=floor(floor(abs(MR(i)))/Delta)*Delta+(3/4)*Delta+De(i);
%         elseif w(i)==0
%             MRw(i)=floor(floor(abs(MR(i)))/Delta)*Delta+(1/4)*Delta+De(i);
%         end   
        i = i + 1;
        MR(i)=Mnm(4,k)*T; %ZR为论文中归一化后的AR
        De(i)=abs(MR(i))-floor(abs(MR(i)));
%          if w(i)==1 %论文中公式（12）
%             MRw(i)=floor(floor(abs(MR(i)))/Delta)*Delta+(3/4)*Delta+De(i);
%         elseif w(i)==0
%             MRw(i)=floor(floor(abs(MR(i)))/Delta)*Delta+(1/4)*Delta+De(i);
%         end
%       
%         
        qx = spheredecodetoMLwi([abs(MR(i-1));abs(MR(i))],w(num));
        MRw(i-1) = qx(1);
        MRw(i) = qx(2);





        Mw(k)=(abs(MRw(i))./abs(MR(i))).*Mnm(4,k); %Zw为论文中嵌入鲁棒水印后的zernike矩Aw %论文中公式（16）
        if MODE == 1
            %（PCET在修改第nm个时还需同时修改第(-n)(-m)个）
            [~,col]=find(Mnm(2,:)==-Mnm(2,k) & Mnm(3,:)==-Mnm(3,k));
            Mw(col) = conj(Mw(k));
            M1(1,k)=Mnm(1,k);M1(2,k)=Mnm(2,k);M1(3,k)=Mnm(3,k);
            M1(4,k)=Mw(k)-Mnm(4,k);
            M1(1,col)=Mnm(1,col);M1(2,col)=Mnm(2,col);M1(3,col)=Mnm(3,col);
            M1(4,col)=Mw(col)-Mnm(4,col); % 水印嵌入更改的矩，然后将其进行重构
        end

        Mw(lastK)=(abs(MRw(i-1))./abs(MR(i-1))).*Mnm(4,lastK); %Zw为论文中嵌入鲁棒水印后的zernike矩Aw %论文中公式（16）
        if MODE == 1
            %（PCET在修改第nm个时还需同时修改第(-n)(-m)个）
            [~,col]=find(Mnm(2,:)==-Mnm(2,lastK) & Mnm(3,:)==-Mnm(3,lastK));
            Mw(col) = conj(Mw(lastK));
            M1(1,lastK)=Mnm(1,lastK);M1(2,lastK)=Mnm(2,lastK);M1(3,lastK)=Mnm(3,lastK);
            M1(4,lastK)=Mw(lastK)-Mnm(4,lastK);
            M1(1,col)=Mnm(1,col);M1(2,col)=Mnm(2,col);M1(3,col)=Mnm(3,col);
            M1(4,col)=Mw(col)-Mnm(4,col); % 水印嵌入更改的矩，然后将其进行重构
        end
        ti = 0;
        end
        lastK  = k;
%         Irw = Irw + (Mw(i)-Mnm(4,k)).*H{Mnm(5,k)}+(conj(Mw(i))-conj(Mnm(4,k))).*conj(H{Mnm(5,k)});
    end
end
if MODE==1
    Irw1=PCET_reconstruct_func(size(img,1),M1); %重构出水印差值图像，并加上原图得到水印图像
elseif MODE==2
    Irw1=FrPCET_reconstruct_func(size(img,1),M1,1.4);
%     Irw1=PCT_reconstruct_func(size(img,1),M1); 
elseif MODE==3
    Irw1=PST_reconstruct_func(size(img,1),M1); 
end
% % 不使用舍入重构操作时注释
% Irw1(isnan(Irw1))=0; %矩外的NaN部分置零
% Iw1 = round(double(I) + Irw1);
% Iw1(Iw1>255)=255;
% Iw1(Iw1<0)=0;
% psnr_Iw1 = psnr(I,uint8(Iw1)) %计算鲁棒水印嵌入后的PSNR

%% 使用舍入重构操作时注释
Irw1(isnan(Irw1))=0; %矩外的NaN部分置零
Iw1 = round(double(I) + Irw1);
Iw1(Iw1>255)=255;
Iw1(Iw1<0)=0;
% 此时的Iw1就是鲁棒水印图像
imwrite(uint8(Iw1),'Iw1.bmp'); %测试输出图像
psnr_Iw1 = psnr(uint8(img),uint8(Iw1)); %计算鲁棒水印嵌入后的PSNR

% Iw1 = PCET_reconstruct_func(size(img,1),Mnm);

% %% 选择需要计算的PHT矩
% if MODE==1
%     [MMT_1,~]=PCET_func(uint8(Iw1),nMax);
% elseif MODE==2
%     [MMT_1,~]=PCT_func(uint8(Iw1),nMax);
% elseif MODE==3
%     [MMT_1,~]=PST_func(uint8(Iw1),nMax);
% else
%     disp('Error!');
%     return;
% end
% %% 首先确认水印嵌入顺序
% temp_1(1,:) = abs(MMT_1(1,:)+1i*MMT(2,:)); %模从小到大
% temp_1(2,:)=MMT_1(1,:); %阶数
% temp_1(3,:)=MMT_1(2,:); %重复数
% temp_1(4,:)=MMT_1(3,:); %矩的大小
% [Mnm_1,ind_1]=sortrows(temp_1'); % ind从前到后的顺序代表了阶数和重复数递增的顺序
% Mnm_1 = Mnm_1'; ind_1 = ind_1'; %E是调整顺序后的PHT矩
% 
% %% 获得预恢复的图像I波浪
% %以下带_1的变量均为文中带波浪线的变量
% i = 0;
% for k = 1 : length(Mnm_1)
%     if ismember(k,insert_palace)
%     i = i + 1;
%     MRw_1(i)=Mnm_1(4,k)*T; %ZR为论文中归一化后的AR    RW
%     MR_1(i)=abs(MRw_1(i))+dq(i)-dw(i); %论文中公式（19）
%     M_1(k)=(abs(MR_1(i))/abs(MRw_1(i)))*Mnm_1(4,k); %Z_1为论文中A波浪；此为论文公式（20）
%     %Ir_1= Ir_1 +  (M_1(i)-Mnm_1(4,k)).*H{Mnm(5,k)}+(conj(M_1(i))-conj(Mnm_1(4,k))).*conj(H{Mnm(5,k)});
%     if MODE == 1
%             %（PCET在修改第nm个时还需同时修改第(-n)(-m)个）
%             [~,col]=find(Mnm_1(2,:)==-Mnm_1(2,k) & Mnm_1(3,:)==-Mnm_1(3,k));
%             M_1(col) = conj(M_1(k));
%             M2(1,k)=Mnm_1(1,k);M2(2,k)=Mnm_1(2,k);M2(3,k)=Mnm_1(3,k);
%             M2(4,k)=M_1(k)-Mnm_1(4,k);
%             M2(1,col)=Mnm_1(1,col);M2(2,col)=Mnm_1(2,col);M2(3,col)=Mnm_1(3,col);
%             M2(4,col)=M_1(col)-Mnm_1(4,col); % 水印嵌入更改的矩，然后将其进行重构
%         elseif MODE == 2
%             %（PCT在修改第nm个时还需同时修改第n(-m)个）
%             [~,col]=find(Mnm_1(2,:)==Mnm_1(2,k) & Mnm_1(3,:)==-Mnm_1(3,k));
%             M_1(col) = conj(M_1(k));
%             M2(1,k)=Mnm_1(1,k);M2(2,k)=Mnm_1(2,k);M2(3,k)=Mnm_1(3,k);
%             M2(4,k)=M_1(k)-Mnm_1(4,k);
%             M2(1,col)=Mnm_1(1,col);M2(2,col)=Mnm_1(2,col);M2(3,col)=Mnm_1(3,col);
%             M2(4,col)=M_1(col)-Mnm_1(4,col); % 水印嵌入更改的矩，然后将其进行重构
%         elseif MODE == 3
%             %（PCT在修改第nm个时还需同时修改第n(-m)个）
%             [~,col]=find(Mnm_1(2,:)==Mnm_1(2,k) & Mnm_1(3,:)==-Mnm_1(3,k));
%             M_1(col) = conj(M_1(k));
%             M2(1,k)=Mnm_1(1,k);M2(2,k)=Mnm_1(2,k);M2(3,k)=Mnm_1(3,k);
%             M2(4,k)=M_1(k)-Mnm_1(4,k);
%             M2(1,col)=Mnm_1(1,col);M2(2,col)=Mnm_1(2,col);M2(3,col)=Mnm_1(3,col);
%             M2(4,col)=M_1(col)-Mnm_1(4,col); % 水印嵌入更改的矩，然后将其进行重构
%         end
%     end
% end
% 
% if MODE==1
%     Irw2=PCET_reconstruct_func(size(img,1),M2); %重构出水印差值图像，并加上原图得到水印图像
% elseif MODE==2
%     Irw2=PCT_reconstruct_func(size(img,1),M2); 
% elseif MODE==3
%     Irw2=PST_reconstruct_func(size(img,1),M2); 
% end
% 
% %% 使用舍入重构操作时注释
% Irw2(isnan(Irw2))=0; %矩外的NaN部分置零
% Iw2 = round(Iw1 + Irw2);
% Iw2(Iw2>255)=255;
% Iw2(Iw2<0)=0;
% imwrite(uint8(Iw2),'Iw2.bmp'); %测试输出图像
% psnr_Iw2 = psnr(uint8(img),uint8(Iw2)); %计算鲁棒水印嵌入后的PSNR
% dr = Iw2 - img; %论文中公式（23）；用于可逆嵌入
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % 可逆嵌入准备工作（先用论文49算数压缩三个误差……
% % 计算图像的256位（16*16）的平均哈希；作为脆弱性认证补偿信息的一部分
% comp_Rows = 16;
% comp_Cols = 16;
% [hash_value] = aHash(img, comp_Rows, comp_Cols); %（此处需256bits作为哈希序列长度）
% 
% % dq算数编码
% [ dq_1 ] =  unsigned_to_bin( dq,7 ); %差值转二进制（此处差值最大为17，五位二进制即可；计算得出共需648bits）
% dq_C = cell(1,1);
% dq_C{1} = dq_1;
% dq_data = Arith07(dq_C); %算数编码压缩
% [ dq_D ] = unsigned_to_bin( dq_data,8 );%编码值转二进制
% 
% dq_beta=dq_D; %可逆水印（经过算数编码压缩）
%  
% % dw算数编码
% dw_J = dw * 4 / Delta; %（尝试1：由于水印误差有小数，故在转化前乘4除Delta，再在解码时将其除去）
% [ dw_1 ] =  unsigned_to_bin( dw_J,2 ); %差值转二进制（有符号的数字转二进制；计算得出共需216bits）
% dw_C = cell(1,1);
% dw_C{1} = dw_1;
% dw_data = Arith07(dw_C); %算数编码压缩
% [ dw_D ] = unsigned_to_bin( dw_data,8 ); %编码值转二进制
% 
% dw_beta=dw_D; %可逆水印（经过算数编码压缩）
%  
% % dr算数编码
% d_max=max(max(dr));
% d_min=min(min(dr));
% % [x,y]=find(date==min(min(dr))) ;
% [ dr_1 ] =  signed_to_bin(dr,4); %差值转二进制（有符号的数字转二进制；计算得出共需32bits）
% dr_C = cell(1,1);
% dr_C{1} = dr_1;
% dr_data = Arith07(dr_C); %算数编码压缩               dr_data=[248;16;69;120]
% [ dr_D ] = unsigned_to_bin( dr_data,8 );%编码值转二进制 
% dr_beta=dr_D; %可逆水印（经过算数编码压缩）
% 
% % 可逆嵌入与提取（……用论文25将误差和哈希值可逆嵌入Iw1的内切圆外部，得到Iw3，即为可逆鲁棒水印图像）
% % 明确待嵌入内容：哈希(256bits)；dw(216)；dq(648~656)；
% reversible_watermarking=[hash_value, dw_beta, dr_beta, dq_beta];
% reversible_watermarking=logical(reversible_watermarking);
reversible_watermarking=[0,1];
