close all;clc;clear;
foreground = im2double(imread('test2_source.jpg'));
background = im2double(imread('test2_target.png'));
BW = roipoly(foreground);

figure(1);
subplot(2,4,1);
imshow(foreground);
title('foreground');

subplot(2,4,2);
imshow(background);
title('background');

off_x = 220;
off_y = 125;

%Find the editing area
[x,y] = find(BW);
min_x = min(x) - 1;
max_x = max(x) + 1;
min_y = min(y) - 1;
max_y = max(y) + 1;

mask = BW(min_x:max_x,min_y:max_y);
source = foreground(min_x:max_x,min_y:max_y,:);
target = background(min_x+off_x:max_x+off_x,min_y+off_y:max_y+off_y,:);

subplot(2,4,3);
imshow(source);
title('source');

subplot(2,4,4);
imshow(target);
title('target');

subplot(2,4,5);
imshow(mask);
title('mask');


%Mask have no boundary, and boundary mask
small_mask = imerode(mask,[0 1 0;1 1 1;0 1 0]);
boundary = xor(mask,small_mask); 

subplot(2,4,6);
imshow(boundary);
title('boundary');

%Build the Guided Matrix
boundary_pixel = zeros(size(target));
for nDim = 1:3
    boundary_pixel(:,:,nDim) = target(:,:,nDim) .* boundary;
end
lapla_source = imfilter(source,[0 -1 0;-1 4 -1;0 -1 0]);
lapla_boundary = imfilter(boundary_pixel,[0 1 0;1 0 1;0 1 0]);
lapla_target = imfilter(target,[0 -1 0;-1 4 -1;0 -1 0]);

subplot(2,4,7);
imshow(lapla_source);
title('laplacian source');

subplot(2,4,8);
imshow(lapla_boundary);
title('laplacian boundary');

%Ax = b
%Build the NumGrid
num_grid = zeros(size(small_mask));
num_small = length(find(small_mask)); 
small_index = find(small_mask(:));
num_grid(small_index) = 1:num_small;
%Build the A
A = delsq(num_grid);
whole_img = background;

source_up = imfilter(source,[0 -1 0;0 1 0;0 0 0]);
target_up = imfilter(target,[0 -1 0;0 1 0;0 0 0]);

source_down = imfilter(source,[0 0 0;0 1 0;0 -1 0]);
target_down = imfilter(target,[0 0 0;0 1 0;0 -1 0]);

source_left = imfilter(source,[0 0 0;-1 1 0;0 0 0]);
target_left = imfilter(target,[0 0 0;-1 1 0;0 0 0]);

source_right = imfilter(source,[0 0 0;0 1 -1;0 0 0]);
target_right = imfilter(target,[0 0 0;0 1 -1;0 0 0]);

for nDim = 1:3
    b = lapla_target(:,:,nDim);
    %Build b (Guide Matrix) 
    %Up gradience
    up = source_up(:,:,nDim);
    for i=1:size(up,1)
        for j = 1:size(up,2)
            if abs(source_up) <= abs(target_up)
                up(i,j) = target_up(i,j);
            end
        end
    end
    
    %Down gradience
    down = source_down(:,:,nDim);
    for i=1:size(down,1)
        for j = 1:size(down,2)
            if abs(source_down) <= abs(target_down)
                down(i,j) = target_down(i,j);
            end
        end
    end
    %Left gradience
    left = source_left(:,:,nDim);
    for i=1:size(left,1)
        for j = 1:size(left,2)
            if abs(source_left) <= abs(target_left)
                left(i,j) = target_left(i,j);
            end
        end
    end
    
    %Right gradience
    right = source_right(:,:,nDim);
    for i=1:size(right,1)
        for j = 1:size(right,2)
            if abs(source_right) <= abs(target_right)
                right(i,j) = target_right(i,j);
            end
        end
    end
    %Add gradience up to get the divergence
    b = up + down + left + right + b;
    b = b + lapla_boundary(:,:,nDim);
    %To vector
    b = b(:);
    b = b(small_index);
    %Matrix Division
    result = A\b;
    
    %Append the result back to background
    I = target(:,:,nDim);
    I = I .* (1 - mask);
    I(small_index) = result;
    whole_img(min_x+off_x:max_x+off_x,min_y+off_y:max_y+off_y,nDim)= I + boundary_pixel(:,:,nDim);
end

figure('name','Task 3 - Final Image');
imshow(whole_img);


