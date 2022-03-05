function [image]=method1dwt(im)
for i=1:3
    %apply DWT to every dimension of the image
    [cA, cH, cV, cD]= dwt2(im(:,:,i), 'db1');
    a = cA;
    h = cH;
    v = cV;
    d = cD;
    %set to 0 some value of the arrays returned by DWT
    cA(randi([0 1], size(cA, 1), size(cA, 2))==0)=0;
    cH(randi([0 1], size(cH, 1), size(cH, 2))==0)=0;
    cV(randi([0 1], size(cV, 1), size(cV, 2))==0)=0;
    cD(randi([0 1], size(cD, 1), size(cD, 2))==0)=0;
    %leave unmodified value in position (1,1)
    cA(1,1)=a(1,1);
    cH(1,1)=h(1,1);
    cV(1,1)=v(1,1);
    cD(1,1)=d(1,1);
    %inverse DWT
    image(:,:,i)= idwt2(cA, cH, cV, cD, 'db1');
end
%resize because DWT return an image with right dimension 
siz=size(im);
image =imresize(image,[siz(1) siz(2)]);
image=uint8(image);
    
end