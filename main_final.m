clc;clear;

%% xiang （128bits）
%（由于该文章只使用了鲁棒水印嵌入，实际上按照文中参数并不能实现可逆性）
num=128; %水印嵌入位数
nMax= 64; 
seed_nums = 0;                  % 可扩展为 0:9 等多组种子，此处仅用 0
num_images_to_test = 72;   % 随机选取的图像数量


%% 图像读取
file_path =  'testset\';% 图像文件夹路径 testset BOWS2OrigEp3
img_path_list = dir(fullfile(file_path, 'NB*.bmp'));  % 仅匹配 NB 开头的 bmp 文件

% img_path_list1 = dir(strcat(file_path,'*.bmp'));%获取该文件夹中所有bmp格式的图像  
% img_path_list2 = dir(strcat(file_path,'*.tif'));
% img_path_list3 = dir(strcat(file_path,'*.tiff'));
% img_path_list4 = dir(strcat(file_path,'*.gif'));
% img_path_list5 = dir(strcat(file_path,'*.pgm'));
% % DATA_all = CatStructFields(img_path_list1, img_path_list2, 2);
% img_path_list=[img_path_list1;img_path_list2;img_path_list3; img_path_list4,img_path_list5];

% for i=1:k
%     name=file(i).name;
%     I{i}=imread(name);
%     figure(i);
%     imshow(I{i});
% end
% standard_img = [483,652,746,547,765,473,965,348,69,196];
% standard_img = [1];

if isempty(img_path_list)
    error('在 %s 中没有找到 NB 开头的图像文件。', file_path);
end

total_files = length(img_path_list);
fprintf('共找到 %d 个符合条件的图像文件。\n', total_files);

% 随机选取指定数量的图像（如果总数少于需要数量，则全选并发出警告）
if total_files < num_images_to_test
    warning('文件夹中符合条件的图像数量 (%d) 少于需要测试的数量 (%d)，将测试所有图像。', total_files, num_images_to_test);
    selected_indices = 1:total_files;
else
    selected_indices = randsample(total_files, num_images_to_test);
end
fprintf('随机选取的图像索引：%s\n', mat2str(selected_indices));

% 预分配结果存储结构
num_tests = length(selected_indices) * length(seed_nums);
results = table();
results.ImageName = strings(num_tests, 1);
results.Seed = zeros(num_tests, 1);
results.PSNR = zeros(num_tests, 1);
results.BER_Gaussian_1 = zeros(num_tests, 1);
results.BER_Gaussian_2 = zeros(num_tests, 1);
results.BER_Gaussian_3 = zeros(num_tests, 1);
results.BER_Salt_1 = zeros(num_tests, 1);
results.BER_Salt_2 = zeros(num_tests, 1);
results.BER_Salt_3 = zeros(num_tests, 1);
results.BER_Median_3 = zeros(num_tests, 1);
results.BER_Median_5 = zeros(num_tests, 1);
results.BER_Median_7 = zeros(num_tests, 1);

test_idx = 0;   % 结果表中的行索引

%% 主循环
for img_idx = 1:length(selected_indices)
    tic;
    j = selected_indices(img_idx);
    image_name = img_path_list(j).name;
    image = imread(fullfile(file_path, image_name));
    
    % 预处理
    mysize = size(image);
    if numel(mysize) == 2
        % 灰度图直接使用
    elseif mysize(3) >= 3
        image = image(:,:,1:3);     % 取前三个通道
    else
        error('不支持的图像通道数。');
    end
    
    % 统一调整尺寸为 512x512
    [rows, cols, ~] = size(image);
    if rows ~= 512 || cols ~= 512
        image = imresize(image, [512, 512]);
    end
    
    % 对每个随机种子进行测试
    for s = 1:length(seed_nums)
        seed_num = seed_nums(s);
        test_idx = test_idx + 1;
        
        fprintf('\n>>> 处理图像: %s, 种子: %d\n', image_name, seed_num);
        
        % 调用主函数
        [psnr_val, BER_gauss, BER_salt, BER_median] = main_color(image, seed_num, 1);
        
        % 存储结果
        results.ImageName(test_idx) = string(image_name);
        results.Seed(test_idx) = seed_num;
        results.PSNR(test_idx) = psnr_val;
        results.BER_Gaussian_1(test_idx) = BER_gauss(1);
        results.BER_Gaussian_2(test_idx) = BER_gauss(2);
        results.BER_Gaussian_3(test_idx) = BER_gauss(3);
        results.BER_Salt_1(test_idx) = BER_salt(1);
        results.BER_Salt_2(test_idx) = BER_salt(2);
        results.BER_Salt_3(test_idx) = BER_salt(3);
        results.BER_Median_3(test_idx) = BER_median(1);
        results.BER_Median_5(test_idx) = BER_median(2);
        results.BER_Median_7(test_idx) = BER_median(3);
    end
    toc;
end

%% 保存结果到 Excel
output_filename = 'watermark_results.xlsx';
writetable(results, output_filename);
fprintf('\n实验结果已保存至: %s\n', output_filename);

% 也可在命令行显示汇总统计
disp('===== 实验结果汇总 =====');
disp(results);
%% %
% temp = 0;   % 计数器
% 
% for idx = 1:length(selected_indices)
%     tic;
%     j = selected_indices(idx);
%     image_name = img_path_list(j).name;
%     image = imread(fullfile(file_path, image_name));
%     
%     % 预处理
%     mysize = size(image);
%     % 如果是彩色图像，保留三通道；单通道直接使用
%     if numel(mysize) == 2
%         image = image;  % 灰度图
%     elseif mysize(3) > 2
%         image = image(:,:,1:3); % 仅取前三个通道（RGB）
%     end
%     
%     % 统一调整尺寸为 512x512
%     [rows, cols, ~] = size(image);
%     if rows ~= 512 || cols ~= 512
%         image = imresize(image, [512, 512]);
%     end
%     
%     temp = temp + 1;
%     
%     % 水印嵌入与测试
%     for seed_num = 0  % 可扩展为 0:9 等多组种子
%         [psnr, BER_gaussian_robust, BER_salt_robust, BER_median_robust] ...
%             = main_color(image, seed_num, 1);
%         % 可在此处保存结果
%     end
%     toc;
% end

%% 
% % standard_img=randsample(1:1500,10);
% % img_num = length(img_path_list);%获取图像总数量
% 
% if img_num > 0 %有满足条件的图像
%     temp=0;%用于同时测试多个图像的鲁棒性
%     for j = standard_img%standard_img%151:200%standard_img %逐一读取图像
%         image_name = img_path_list(j).name;% 图像名
%         image =  imread(strcat(file_path,image_name));
%         % 预处理
%         mysize=size(image);
%         % 如果是彩色图像，保留三通道；如果是单通道，直接使用
%         if numel(mysize) == 2
%             image = image(:,:,1);  % 灰度图直接使用
%         elseif mysize(3) > 2
%             image = image(:,:,1:3); % 仅取前三个通道（RGB）
%         end
% %         
% %         if numel(mysize)>2
% %             if mysize(3) ==2
% %                 image = image(:,:,1);
% %             else
% %                 image=rgb2gray(image); %将彩色图像转换为灰度图像
% %             end
% %         end
%         [image_Rows, image_Cols]=size(image);
%         if image_Rows~=512 || image_Cols~=512
%             image =imresize(uint8(image),[512,512]);
%         end
%         temp=temp+1;
% %         imshow(uint8(image));
%         % 水印嵌入
%         for seed_num = 0%:1:9
%             [psnr,BER_gaussian_robust, BER_salt_robust, BER_median_robust]...
%             = main_color(image, seed_num,1); % 用于测试鲁棒性
% %             [amplitude_d(temp,:)]= embedded_main(image, seed_num,2);
%             % , BER_resize_robust(temp,:), ...
% %                 BER_gaussian_robust(temp,:), BER_jpeg_robust(temp,:), BER_jpeg2000_robust(temp,:)
% %             Card(temp,:) = [T_start;j;seed_num];
% %             save lena_128_encode
%         end
%     end
% end

