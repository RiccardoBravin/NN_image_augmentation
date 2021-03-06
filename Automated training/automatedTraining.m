%% DATA MANIPULATION
im_dim=[224 224];%input size of ResNet18
num_classes = max(LBLS); %numero di classi di dati

if(size(DIVS,2) == size(PATS,1))
    tr_data_sz = DIVS(fold); %numero di immagini per il training
else
    tr_data_sz = DIVS(1); %numero di immagini per il training
end

training_imgs = zeros(im_dim(1), im_dim(2), 3, tr_data_sz, 'uint8'); %inizializzazione dello spazio di memoria  
for pattern = 1:tr_data_sz              %for all the images of training
    I=IMGS{PATS(fold,pattern)};         %image for the training
    I=imresize(I,im_dim);               %resize image
    if(size(I,3) == 3)
        training_imgs(:,:,:,pattern) = I;   %add to the training images
    elseif(size(I,3) == 1)
        training_imgs(:,:,1,pattern) = I;   %add to the training images
        training_imgs(:,:,2,pattern) = I;
        training_imgs(:,:,3,pattern) = I;
    end
end

training_lbls = LBLS(PATS(fold,1:tr_data_sz)); %lables for the training images
training_lbls = categorical(training_lbls);

test_imgs = zeros(im_dim(1), im_dim(2), 3, DIM - tr_data_sz, 'uint8'); %inizializzazione dello spazio di memoria  
for pattern = tr_data_sz+1:DIM          %for all the images of test
    I=IMGS{PATS(fold,pattern)};         %image for the test
    I=imresize(I,im_dim);                   %resize image
    if(size(I,3) == 3)
        test_imgs(:,:,:,pattern-tr_data_sz) = I;   %add to the test images
    elseif(size(I,3) == 1)
        test_imgs(:,:,1,pattern-tr_data_sz) = I;
        test_imgs(:,:,2,pattern-tr_data_sz) = I;
        test_imgs(:,:,3,pattern-tr_data_sz) = I;
    end
end

test_lbls = LBLS(PATS(fold,tr_data_sz+1:DIM)); %lables for the test images
test_lbls = categorical(test_lbls);

training_imgs_bk = training_imgs;
training_lbls_bk = training_lbls;

%% TRAINING OPTIONS
options = trainingOptions('adam',...                    %sgdm
    'Plots','training-progress',...                     %training-progress
    'Verbose', false,...                                %false                          
    'MaxEpochs', 10,...                                  %20
    'MiniBatchSize', 50,...                             %30
    'Shuffle', 'every-epoch',...                        %every-epoch
...%     'ValidationData', {test_imgs, test_lbls},...        %
...%     'ValidationFrequency',30,...                        %30
...%     'ValidationPatience',20,...                         %5
    'InitialLearnRate',0.0001,...                       %0.001
    'LearnRateSchedule','piecewise',...                 %piecewise
    'LearnRateDropPeriod', 5 ...                        %5
);

%% NETWORK MANIPULATION
%To retrain the network on a new classification task, follow the steps of Transfer Learning .
%Load the ResNet-50 model and change the names of the layers that you remove and connect
%to match the names of the ResNet-50 layers:
%remove the 'ClassificationLayer_fc1000', 'fc1000_softmax', and 'fc1000'layers, and connect to the 'avg_pool' layer.

lgraph = layerGraph(resnet18); %Scelta del network da utilizzare
lgraph = removeLayers(lgraph, {'ClassificationLayer_predictions','prob','fc1000'});
newLayers = [
    fullyConnectedLayer(num_classes,'Name','fc','WeightLearnRateFactor',20,'BiasLearnRateFactor', 20)
    softmaxLayer('Name','softmax')
    classificationLayer('Name','classoutput')];
lgraph = addLayers(lgraph,newLayers);
lgraph = connectLayers(lgraph,'pool5','fc');

%% TRAINING & DATA AUGMENTATION
acc_i = 1; %accuracy index initializer

disp("No augmentation");
RadonT;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "No augmentation";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix
accuracy{fold}{6,acc_i} = test_lbls; %saving the lables in the first slot so that they can be used later


%% Classic augmentation

acc_i = acc_i+1;

Classic;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "Classic x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;


%% Elastic deformation

acc_i = acc_i+1;

Deformation;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "Deformation x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% Color Reduction

acc_i = acc_i+1;

ColorReduction;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "ColorReduction x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% Discrete Cosine Transform

acc_i = acc_i+1;

DCT;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "DCT x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% Fourier Transform

acc_i = acc_i+1;

FFT;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "FFT x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% Deconvolution

acc_i = acc_i+1;

Deconvolution;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "Deconvolution x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% Laplacian

acc_i = acc_i+1;

Laplacian;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "Laplacian x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% FFT Combine

acc_i = acc_i+1;

FFTCombine;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "FFT Combine x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;


%% ContentFill

acc_i = acc_i+1;

ContentFill;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "ContentFill x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% PixelShuffle

acc_i = acc_i+1;

PixelShuffle;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "PixelShuffle x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% SVD
acc_i = acc_i+1;

SingValDec;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "SVD x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% Hilbert transform

acc_i = acc_i+1;

HilbertTransform;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "Hilbert transform x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% Hampel

acc_i = acc_i+1;

Hampel;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "Hampel x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% SuperPixel Deform PxShuffle ContentFill
acc_i = acc_i+1;

SuperPxDeformShuffFill;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "SuperPixel,Deformation,PixelShuffle,ContentFill x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;


%% Cascade All
acc_i = acc_i+1;

CascadeAll;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "CascadeAll x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% DCTDeform
acc_i = acc_i+1;

DCTDeform;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "DCT e Deform x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% DCTSuperPxHilbertHampel
acc_i = acc_i+1;

DCTSuperPxHilbertHampel;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "DCT, SuperPixel, Hilbert e Hampel x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% HampelHilbertDCTLaplacian
acc_i = acc_i+1;

HampelHilbertDCTLaplacian;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "Hampel, Hilbert, DCT e Laplacian x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;

%% Classic plus my augmentation
acc_i = acc_i+1;

ClassicPP;

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options); %training with modified dataset

[outclass, score] =  classify(netTransfer,test_imgs); %classification with test images

accuracy{fold}{1,acc_i} = "Classic++ x1";
accuracy{fold}{2,acc_i} = sum(outclass' == test_lbls)/size(test_lbls,2); %accuracy of test set
accuracy{fold}{3,acc_i} = outclass; 
accuracy{fold}{4,acc_i} = score;
accuracy{fold}{5,acc_i} = confusionmat(test_lbls',outclass); %confusion matrix

training_imgs = training_imgs_bk;
training_lbls = training_lbls_bk;
