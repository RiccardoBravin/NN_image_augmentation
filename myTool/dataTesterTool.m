%% LOADING DATA

clear all
close all force
warning off

load('paintings.mat','DATA');%to load the dataset used in this example

IMGS = DATA{1}; %tutte le immagini
LBLS = DATA{2}; %tutti i label
PATS = DATA{3}; %indici per la suddivisione dei dati
DIVS = DATA{4}; %divisori per gli indici
DIM = DATA{5};  %numero totale di immagini presenti

%% DATA MANIPULATION

im_dim=[224 224];%input size of ResNet50
fold = 2; %DECIDI QUALE FOLD UTILIZZARE PER GLI INDICI
num_classes = max(LBLS); %numero di classi di dati

tr_data_sz = DIVS(fold); %numero di immagini per il training

training_imgs = zeros(im_dim(1), im_dim(2), 3, tr_data_sz, 'uint8'); %inizializzazione dello spazio di memoria  
for pattern = 1:tr_data_sz %for all the images of training
    I=IMGS{PATS(fold,pattern)};         %image for the training
    I=imresize(I,im_dim);               %resize image
    training_imgs(:,:,:,pattern) = I;   %add to the training images
end

training_lbls = LBLS(PATS(fold,1:tr_data_sz)); %lables for the training images
training_lbls = categorical(training_lbls);

test_imgs = zeros(im_dim(1), im_dim(2), 3, DIM - tr_data_sz, 'uint8'); %inizializzazione dello spazio di memoria  
for pattern = tr_data_sz+1:DIM %for all the images of test
    I=IMGS{PATS(fold,pattern)};         %image for the test
    I=imresize(I,im_dim);               %resize image
    test_imgs(:,:,:,pattern-tr_data_sz) = I;   %add to the test images
end

test_lbls = LBLS(PATS(fold,tr_data_sz+1:DIM)); %lables for the test images
test_lbls = categorical(test_lbls);

%% DATA AUGMENTATION
append=1;%da dove partire a inserire immagini

iterations = 1; %cambiare prima di ogni chiamata a file per modificare il numero di immagini generate
interval = [1:tr_data_sz];%intervallo da cui campionare immagini

%inserire augmentation potenzialmente modificando append, iterations e interval
ColorShift;

training_imgs = training_imgs(:,:,:,tr_data_sz+1:size(training_lbls,2));
training_lbls = training_lbls(tr_data_sz+1:size(training_lbls,2));
%% TRAINING OPTIONS

options = trainingOptions('adam',...                    %sgdm
    'Plots','none',...                 %training-progress
    'Verbose', false,...                                 %false
    'MaxEpochs', 9,...                                  %20
    'MiniBatchSize', 30,...                             %30
    'Shuffle', 'every-epoch',...                        %every-epoch
    'ValidationData', {test_imgs, test_lbls},...        %
    'ValidationFrequency',20,...                        %30
    'ValidationPatience',100,...                        %5
    'InitialLearnRate',0.0001,...                       %0.001
    'LearnRateSchedule','piecewise',...                 %piecewise
    'LearnRateDropPeriod', 4 ...                        %2
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

% lgraph = layerGraph(resnet50); %Scelta del network da utilizzare
% lgraph = removeLayers(lgraph, {'ClassificationLayer_fc1000','fc1000_softmax','fc1000'});
% newLayers = [
%     fullyConnectedLayer(num_classes,'Name','fc','WeightLearnRateFactor',20,'BiasLearnRateFactor', 20)
%     softmaxLayer('Name','softmax')
%     classificationLayer('Name','classoutput')];
% lgraph = addLayers(lgraph,newLayers);
% lgraph = connectLayers(lgraph,'avg_pool','fc');

%% TRAINING
disp(" 2x")

netTransfer = trainNetwork(training_imgs, training_lbls, lgraph, options);

[outclass, score{fold}] =  classify(netTransfer,test_imgs);
accuracy = sum(outclass' == test_lbls)/size(test_lbls,2)
accuracy = [1:num_classes;histcounts(outclass((test_lbls' == outclass)))./histcounts(outclass)]

%% Checking features

img = training_imgs(:,:,:,1);
Y = classify(netTransfer,img);

map = imageLIME(netTransfer,img,Y);
imshow(img,'InitialMagnification',150)
hold on
imagesc(map,'AlphaData',0.5)
colormap jet
colorbar

hold off
%% checking 2
map = imageLIME(netTransfer,img,Y, ...
    "Segmentation","grid",...
    "OutputUpsampling","bicubic",...
    "NumFeatures",100,...
    "NumSamples",6000,...
    "Model","linear");

imshow(img,'InitialMagnification', 150)
hold on
imagesc(map,'AlphaData',0.5)
colormap jet
hold off