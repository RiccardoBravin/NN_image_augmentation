
for pattern = interval
    i = 1;
    while i <= iterations
        img(:,:,:)= training_imgs(:,:,:,pattern);

        img = imresize(img, randi([50,100],2,1));

        img = imresize(img, im_dim,'nearest');
        
        training_imgs(:,:,:,tr_data_sz+append) = img;
        training_lbls(tr_data_sz+append)=training_lbls(pattern);
        append = append + 1;
        i = i + 1;
        
    end
end

clearvars i pattern tform outputView img
