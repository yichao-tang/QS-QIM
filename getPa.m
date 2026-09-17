function  [H,J,d,Gc]= getPa()
    H = [sqrt(3)/2,0;1/2,1];
    J = 2;
    ti = getTi();
    H = H * ti;
    d = 2*ti;
    
    Gc = J * H;
end