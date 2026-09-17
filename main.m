function [psnr_Iw1,BER_gaussian_robust, BER_salt_robust, BER_median_robust] = main(I ,seed_num , MODE) 
% BER_jpeg2000_robust,
img=double(I);
nMax=28; %nMax为阶数和重复数，用于控制最大嵌入容量
wl=128; %num为水印长度 
% 1.PCET(T=15时能嵌入191bits)；2.PCT(T=15时只能嵌入96bits)；3.PST(T=15时只能嵌入84bits)
% 1.PCET(T=13时能嵌入128bits) 2.PCT(T=18时能嵌入128bits)；3.PST(T=19时能嵌入128bits)
% 1.PCET(T=18时能嵌入256bits) 2.PCT(T=26时能嵌入256bits)；3.PST(T=27时能嵌入256bits)
Delta=32;%32;%固定值
T=100;
%rng('default'); 
rng(seed_num,'twister');
%% 预备环节（实验所需参数初始化）
N=size(I,1);
w =randi([0,1],1,wl); 
i=1;

    
    if MODE==1
        nMax=26;
        Delta=36;
    elseif MODE==2
        nMax=26;
        Delta=32;
    elseif MODE==3
        nMax=19;
        Delta=70;
    end
    %% 鲁棒嵌入
    [Iw1,reversible_watermarking{i},psnr_Iw1(i)] = embedded_main(I, nMax, T, Delta, w,MODE);

%     %% 可逆嵌入
%     [Iw3, PSNR_Iw1_Iw3, Ok, per1, per2, ~, ~, ~, ~] = reversible_embedding(Iw1, reversible_watermarking{i}) ;
%     psnr_Iw3(i) = psnr(uint8(img),uint8(Iw3)); %计算可逆水印嵌入后的PSNR  
% 
%     %% 可逆提取
%     [Iw_1,reversi] = reversible_decodding(Iw3,numel(reversible_watermarking{i})); 

    %% 鲁棒水印提取（需要测试鲁棒性时使用）
    [w_3] = robust_extract(Iw1, nMax, T, Delta , w , MODE ) ;
    w3 = w_3;
    check_w=isequal(w,w3); %判断是否原图是否恢复
    BER_robust(i) = sum(abs(w3-w))/length(w);
    i=i+1;
    
    
    
    %% 椒盐噪声
    for l = 1 : 3
    K_tem_salt_robust=imnoise(uint8(Iw1),'salt & pepper',0.025+(l-1)*0.002);
    %% 接下来对攻击后的水印图像进行水印提取操作，并记录（不同算法的细节不同）
    [w_ex_salt_robust] = robust_extract(K_tem_salt_robust, nMax, T, Delta , w , MODE ) ;
    %% 计算误码率（嵌入水印和受到攻击后提取出的水印进行比较）
        te_salt_robust(l)=sum(abs(w-w_ex_salt_robust));
        BER_salt_robust(l) = te_salt_robust(l)/length(w);
    end

    %% 加性高斯噪声攻击（AWGN
    for l = 1 : 3 
        K_gaussian_robust(l,:,:)=imnoise(uint8(Iw1), 'gaussian', 0, 0.025+(l-1)*0.002);%高斯噪声
        K_tem_gaussian_robust = squeeze(K_gaussian_robust(l,:,:));%生成受到攻击后的水印图像
        %%接下来对攻击后的水印图像进行水印提取操作，并记录（不同算法的细节不同）
        [w_ex_gaussian_robust] = robust_extract(K_tem_gaussian_robust, nMax, T, Delta , w , MODE ) ;
        %%计算误码率（嵌入水印和受到攻击后提取出的水印进行比较）
        te_gaussian_robust(l)=sum(abs(w-w_ex_gaussian_robust));
        BER_gaussian_robust(l) = te_gaussian_robust(l)/length(w);
    end
     %% JPEG2000压缩攻击
%     for l = 1 : 4
%         imwrite(uint8(Iw1),'Iw_jpeg2000_compress.jp2','CompressionRatio',60+10*l);
%         K_jpeg2000_robust(l,:,:)=imread('Iw_jpeg2000_compress.jp2');
%         K_tem_jpeg2000_robust = squeeze(K_jpeg2000_robust(l,:,:));
%         %imshow(K_tem_jpeg2000_robust);
%         %%接下来对攻击后的水印图像进行水印提取操作，并记录（不同算法的细节不同）
%         [w_ex_jpeg2000_robust] = robust_extract(K_tem_jpeg2000_robust, nMax, T, Delta , w , MODE ) ;
%         %%计算误码率（嵌入水印和受到攻击后提取出的水印进行比较）
%         te_jpeg2000_robust(l)=sum(abs(w-w_ex_jpeg2000_robust));
%         BER_jpeg2000_robust(l) = te_jpeg2000_robust(l)/length(w);
%     end

%% 中值滤波攻击
median_sizes = [3, 5, 7];
BER_median_robust = zeros(1, length(median_sizes));
for idx = 1:length(median_sizes)
    window_size = median_sizes(idx);
    K_tem_median_robust = medfilt2(uint8(Iw1), [window_size, window_size]);
    [w_ex_median_robust] = robust_extract(K_tem_median_robust, nMax, T, Delta, w, MODE);
    te_median_robust = sum(abs(w - w_ex_median_robust));
    BER_median_robust(idx) = te_median_robust / length(w);
end

%% 输出图像
% %% Gaussian 
% clf;
% hold on;
% plot(BER_gaussian_robust(1,:),'o-','color',[54,130,190]/256);
% plot(BER_gaussian_robust(2,:),'s-','color',[240,83,38]/256);
% plot(BER_gaussian_robust(3,:),'d-','color',[221,174,51]/256);
% set(gcf,'PaperUnits','centimeters','Position',[500 500 350 270]);
% set(gca, 'Linewidth',0.75,'FontSize',12,'FontName','Times New Roman','FontWeight','normal');
% xlabel('Variance','FontSize',13,'FontName','Times New Roman');
% ylabel('BER(%)','FontSize',13,'FontName','Times New Roman');
% title('Lena','FontSize',13,'FontName','Times New Roman');
% legend({'PCET {\itet al.}','PCT {\itet al.}','PST {\itet al.}'},'Location','northwest');
% xlim([0 13.5]);
% ylim([0 0.75]);
% set(gca,'ytick',0:0.2:0.6);
% set(gca,'yticklabel',{'0','20','40','60'});
% set(gca,'xtick',[1:2.5:13]);
% set(gca,'xticklabel',{'0.005','0.01','0.015','0.02','0.025'});
% box on
% %print(gcf,'-dtiffn','-r95','Gaussian_01_Lena.tif');
% % print(gcf, '-depsc','-r95','Gaussian_01_Lena.eps');
% hold off;
% 
% %% JPEG 
% clf;
% hold on;
% plot(BER_jpeg_robust(1,:),'o-','color',[54,130,190]/256);
% plot(BER_jpeg_robust(2,:),'s-','color',[240,83,38]/256);
% plot(BER_jpeg_robust(3,:),'d-','color',[221,174,51]/256);
% set(gcf,'PaperUnits','centimeters','Position',[500 500 350 270]);
% set(gca, 'Linewidth',0.75,'FontSize',12,'FontName','Times New Roman','FontWeight','normal');
% xlabel('JPEG Quality Factors','FontSize',13,'FontName','Times New Roman');
% ylabel('BER(%)','FontSize',13,'FontName','Times New Roman');
% title('Lena','FontSize',13,'FontName','Times New Roman');
% legend({'PCET {\itet al.}','PCT {\itet al.}','PST {\itet al.}'},'Location','northwest');
% axis([0 10 0 1]);
% ylim([0 0.75]);
% set(gca,'ytick',0:0.2:0.6);
% set(gca,'yticklabel',{'0','20','40','60'});
% set(gca,'xtick',[0:5:10]);
% set(gca,'xticklabel',{'0','50','100'});
% box on
% %print(gcf,'-dtiffn','-r95','JPEG_01_Lena.tif');
% % print(gcf, '-depsc','-r95','JPEG_01_Lena.eps');
% hold off;
% 
% %% JPEG2000 
% clf;
% hold on;
% plot(BER_jpeg2000_robust(1,:),'o-','color',[54,130,190]/256);
% plot(BER_jpeg2000_robust(2,:),'s-','color',[240,83,38]/256);
% plot(BER_jpeg2000_robust(3,:),'d-','color',[221,174,51]/256);
% set(gcf,'PaperUnits','centimeters','Position',[500 500 350 270]);
% set(gca, 'Linewidth',0.75,'FontSize',12,'FontName','Times New Roman','FontWeight','normal');
% xlabel('JPEG2000 CompressionRatio Ratios','FontSize',13,'FontName','Times New Roman');
% ylabel('BER(%)','FontSize',13,'FontName','Times New Roman');
% title('Lena','FontSize',13,'FontName','Times New Roman');
% legend({'PCET {\itet al.}','PCT {\itet al.}','PST {\itet al.}'},'Location','northwest');
% axis([0 10 0 1]);
% ylim([0 0.75]);
% set(gca,'ytick',0:0.2:0.6);
% set(gca,'yticklabel',{'0','20','40','60'});
% set(gca,'xtick',[0:5:10]);
% set(gca,'xticklabel',{'0','50','100'});
% box on
% %print(gcf,'-dtiffn','-r95','JPEG2000_01_Lena.tif');
% %print(gcf, '-depsc','-r95','JPEG2000_01_Lena.eps');
% hold off;
% 
% %% Rotation 
% clf;
% hold on;
% plot(BER_rotate_robust(1,:),'o-','color',[54,130,190]/256);
% plot(BER_rotate_robust(2,:),'s-','color',[240,83,38]/256);
% plot(BER_rotate_robust(3,:),'d-','color',[221,174,51]/256);
% set(gcf,'PaperUnits','centimeters','Position',[500 500 350 270]);
% set(gca, 'Linewidth',0.75,'FontSize',12,'FontName','Times New Roman','FontWeight','normal');
% xlabel('Angle in Degrees','FontSize',13,'FontName','Times New Roman');
% ylabel('BER(%)','FontSize',13,'FontName','Times New Roman');
% title('Lena','FontSize',13,'FontName','Times New Roman');
% legend({'PCET {\itet al.}','PCT {\itet al.}','PST {\itet al.}'},'Location','northwest');
% xlim([0 18]);
% ylim([0 0.15]);
% set(gca,'ytick',0:0.05:0.15);
% set(gca,'yticklabel',{'0','5','10','15'});
% set(gca,'xtick',[0:5:18]);
% set(gca,'xticklabel',{'0','100','200','300'});
% box on
% %print(gcf,'-dtiffn','-r95','Rotation_01_Lena.tif');
% %print(gcf, '-depsc','-r95','Rotation_01_Lena.eps');
% hold off;
% 
% %% Scale 
% clf;
% hold on;
% plot(BER_resize_robust(1,:),'o-','color',[54,130,190]/256);
% plot(BER_resize_robust(2,:),'s-','color',[240,83,38]/256);
% plot(BER_resize_robust(3,:),'d-','color',[221,174,51]/256);
% set(gcf,'PaperUnits','centimeters','Position',[500 500 350 270]);
% set(gca, 'Linewidth',0.75,'FontSize',12,'FontName','Times New Roman','FontWeight','normal');
% xlabel('Scale Factors','FontSize',13,'FontName','Times New Roman');
% ylabel('BER(%)','FontSize',13,'FontName','Times New Roman');
% title('Lena','FontSize',13,'FontName','Times New Roman');
% legend({'PCET {\itet al.}','PCT {\itet al.}','PST {\itet al.}'},'Location','northwest');
% ylim([0 0.15]);
% set(gca,'ytick',0:0.05:0.15);
% set(gca,'yticklabel',{'0','5','10','15'});
% set(gca,'xtick',[1:5:16]);
% set(gca,'xticklabel',{'0.5','1','1.5','2'});
% box on
% %print(gcf,'-dtiffn','-r95','Scale_01_Lena.tif');
% %print(gcf, '-depsc','-r95','Scale_01_Lena.eps');
% hold off;


