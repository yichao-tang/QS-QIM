function [highBound ,lowBound ]= BoundsZk(di,R,sk_k1,k)
    z = di(k)/R(k,k);

    z = abs(z);
    highBound = floor(z + sk_k1(k));
    lowBound = ceil(-1*z + sk_k1(k))-1;
end