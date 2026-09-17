function bit = msg2Bin(msg,dimension)
    [mr,number] = size(msg);
    bit  = zeros(dimension,number);
    for i = 1 : number
         temp = msg(mr,i);
         for j = dimension-1 :-1: 0
               bit(dimension-j,i) = floor(temp/2^j);
               temp = mod(temp,2^j);
         end
    end
    bit = reshape(bit,1,[]);
end