foreground = im2double(imread('foreground.jpg'));
background = im2double(imread('background.jpg'));

figure(1);
BW = roipoly(foreground);

bsize = size(background); 
mask = zeros(bsize);

%Define the relative position of the area 
offset_x = 60;
offset_y = 125;

%Build the mask
fsize = size(BW);
for row = 1:fsize(1)
    for col = 1:fsize(2)
        mask(offset_x + row,offset_y + col,:) = BW(row,col);
    end
end

%Build the new raw image 
new_img = zeros(bsize);
for row = 1:bsize(1)
    for col = 1:bsize(2)
        if mask(row,col,1) == 1
            new_img(row,col,:) = foreground(row-offset_x,col-offset_y,:);
        else
            new_img(row,col,:) = background(row,col,:);
        end
    end
end

imwrite(uint8(new_img),'X.png');

%Calculate gradient
hori = [0,-1,1];
vert = [0;-1;1];

fore_grad_h = imfilter(foreground,hori,'replicate');
fore_grad_v = imfilter(foreground,vert,'replicate');

back_grad_h = imfilter(background,hori,'replicate');
back_grad_v = imfilter(background,vert,'replicate');

%Build the gradient images 
hori = zeros(bsize);
verti = zeros(bsize);
for row = 1:bsize(1)
    for col = 1:bsize(2)
        if mask(row,col,1) == 1
            hori(row,col,:) = fore_grad_h(row-offset_x,col-offset_y,:);
            verti(row,col,:) = fore_grad_v(row-offset_x,col-offset_y,:);
        else
            hori(row,col,:) = back_grad_h(row,col,:);
            verti(row,col,:) = back_grad_v(row,col,:);
        end
    end
end

lapla = grad2lapla(hori,verti);
iterations = 1000;
threshold = 0.001;
result = new_img;
previous = result;
previous_diff = 1E32;

for i = 1:iterations
    row = 1;
    col = 1;
    
    %Top left corner
    for channel = 1:size(new_img,3);   
        if( mask(row,col,channel) > 0 )
            d = (lapla(row,col,channel) + result(row+1,col,channel) + result(row,col+1,channel) ) / 2 - result(row,col,channel);
            result(row,col,channel) = result(row,col,channel) + 1.9 * d;
        end
    end
    
    %Top right corner
    col = size(new_img,2);
    for channel = 1:size(new_img,3)   
        if( mask(row,col,channel) > 0 )
            d = (lapla(row,col,channel) + result(row+1,col,channel) + result(row,col-1,channel) ) / 2 - result(row,col,channel);
            result(row,col,channel) = result(row,col,channel) + 1.9 * d;
        end
    end
    
    %Bottom left corner
    row = size(new_img,1);
    col = 1;
    for channel = 1:size(new_img,3)   
        if( mask(row,col,channel) > 0 )
            d = (lapla(row,col,channel) + result(row-1,col,channel) + result(row,col+1,channel) ) / 2 - result(row,col,channel);
            result(row,col,channel) = result(row,col,channel) + 1.9 * d;
        end
    end
    
    %Bottom right corner
    col = size(new_img,2);
    row = size(new_img,1);
    for channel = 1:size(new_img,3)   
        if( mask(row,col,channel) > 0 )
            d = (lapla(row,col,channel) + result(row-1,col,channel) + result(row,col-1,channel) ) / 2 - result(row,col,channel);
            result(row,col,channel) = result(row,col,channel) + 1.9 * d;
        end
    end
    
    
    %First Row 
    row = 1;
    for col = 2:size(new_img,2)-1
        for channel = 1:size(new_img,3)   
            if( mask(row,col,channel) > 0 )
                d = (lapla(row,col,channel) + result(row+1,col,channel) + result(row,col-1,channel) + result(row,col+1,channel) ) / 3 - result(row,col,channel);
                result(row,col,channel) = result(row,col,channel) + 1.9 * d;
            end
        end
    end
    
    %Last Row
    row = size(new_img,1);
    for col = 2:size(new_img,2)-1;
        for channel = 1:size(new_img,3)   
            if( mask(row,col,channel) > 0 )
                d = (lapla(row,col,channel) + result(row-1,col,channel) + result(row,col-1,channel) + result(row,col+1,channel) ) / 3 - result(row,col,channel);
                result(row,col,channel) = result(row,col,channel) + 1.9 * d;
            end
        end
    end
    
    %First Column
    col = 1;
    for row = 2:size(new_img,1)-1
        for channel = 1:size(new_img,3)   
            if( mask(row,col,channel) > 0 )
                d = (lapla(row,col,channel) + result(row-1,col,channel) + result(row,col+1,channel) + result(row+1,col,channel) ) / 3 - result(row,col,channel);
                result(row,col,channel) = result(row,col,channel) + 1.9 * d;
            end
        end
    end
    
    %Last Column
    col = size(new_img,2);
    for row = 2:size(new_img,1)-1
        for channel = 1:size(new_img,3)   
            if( mask(row,col,channel) > 0 )
                d = (lapla(row,col,channel) + result(row-1,col,channel) + result(row,col-1,channel) + result(row+1,col,channel) ) / 3 - result(row,col,channel);
                result(row,col,channel) = result(row,col,channel) + 1.9 * d;
            end
        end
    end
    
    %Main Image
    for row = 2:size(new_img,1)-1
        for col = 2:size(new_img,2) -1 
            for channel = 1:size(new_img,3)   
                if( mask(row,col,channel) > 0 )
                    d = (lapla(row,col,channel) + result(row+1,col,channel) +result(row-1,col,channel) + result(row,col-1,channel) + result(row,col+1,channel) ) / 4 - result(row,col,channel);
                    result(row,col,channel) = result(row,col,channel) + 1.9 * d;
                end
            end
        end 
    end
    
    difference = abs(result - previous);
    max_differ = max(difference(:));
    
    if( abs(previous_diff - max_differ)/previous_diff < threshold )
        break;
    end
    
    previous = result;
    previous_diff = max_differ;
end

imwrite(uint8(result),'result.png');
figure(2)
imshow(result);