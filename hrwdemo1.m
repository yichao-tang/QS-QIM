
clc
clear
image=imread('01.lena.bmp');
N=size(image,1);
mysize=size(image,2);
a=ones(1,128);
[X,Y]=meshgrid(-1:(2/(N-1)):1,-1:(2/(N-1)):1);
[theta,r] = cart2pol(X,Y);
idx = uint8(r<=1);
img2=image.*idx;
