for k = 1 : length(Mnm)
    if ismember(k,insert_palace)
        moment = moment + 1;
        if MODE == 1
            %（PCET在修改第nm个时还需同时修改第(-n)(-m)个）
            [~,col]=find(Mnm(2,:)==-Mnm(2,k) & Mnm(3,:)==-Mnm(3,k));
            M_z(k)=Mnm_w(4,k);
            M_z(col)=Mnm_w(4,col); % 水印嵌入更改的矩，然后将其进行重构
        elseif MODE == 2
            %（PCT在修改第nm个时还需同时修改第n(-m)个）
            [~,col]=find(Mnm(2,:)==Mnm(2,k) & Mnm(3,:)==-Mnm(3,k));
            M_z(k)=Mnm_w(4,k);
            M_z(col)=Mnm_w(4,col); % 水印嵌入更改的矩，然后将其进行重构
        elseif MODE == 3
            %（PCT在修改第nm个时还需同时修改第n(-m)个）
            [~,col]=find(Mnm(2,:)==Mnm(2,k) & Mnm(3,:)==-Mnm(3,k));
            M_z(k)=Mnm_w(4,k);
            M_z(col)=Mnm_w(4,col); % 水印嵌入更改的矩，然后将其进行重构
        end
    end
end