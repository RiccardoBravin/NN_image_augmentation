append = 1;%da dove partire a inserire immagini
iterations = 1; %cambiare prima di ogni chiamata a file per modificare il numero di immagini generate
interval = [1:tr_data_sz];%intervallo da cui campionare immagini


for pattern = interval
    i = 1;
    while i <= iterations
        img(:,:,:)=training_imgs(:,:,:,pattern);
        
        rand = 3;%randi([1,3]);
        if rand == 1
            img = locallapfilt(img, rand()/2,rand()/3);
        elseif rand == 2
            img = locallapfilt(img, rand()/7,3,'NumIntensityLevels', randi([10,15]));
        else
            img = locallapfilt(img, 0.1,rand()+0.5,rand()+1);
        end
        
        %montage({training_imgs(:,:,:,pattern), img}); pause(1);

        training_imgs(:,:,:,tr_data_sz+append) = img;
        training_lbls(tr_data_sz+append)=training_lbls(pattern);
        append = append + 1;
        i = i + 1;
        
    end
end

clearvars i pattern img types
clearvars interval append iterations