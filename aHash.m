function [hash_value] = aHash(img, comp_Rows, comp_Cols)
J=imresize(img, [comp_Rows, comp_Rows],'nearest');
a = mean(mean(J));
k=0;
for i =1 : comp_Rows
    for j =1 : comp_Cols
        k=k+1;
        if J(i, j) >= a
            hash_value(k)=1;
        else
            hash_value(k)=0;
        end
    end
end