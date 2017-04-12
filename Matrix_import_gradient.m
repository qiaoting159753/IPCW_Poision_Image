close all;clc;clear;
foreground = im2double(imread('foreground.jpg'));
background = im2double(imread('background.jpg'));
BW = roipoly(foreground);

figure(1);
subplot(2,4,1);
imshow(foreground);
title('foreground');

subplot(2,4,2);
imshow(background);
title('background');

off_x = 60;
off_y = 125;

%Find the editing area
[x,y] = find(BW);
min_x = min(x) - 1;
max_x = max(x) + 1;
min_y = min(y) - 1;
max_y = max(y) + 1;

%Cut the image to patch
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

for nDim = 1:3
    %Build b (Guide Matrix)
    b = lapla_source(:,:,nDim);
    b = b + lapla_boundary(:,:,nDim);
    
    %To vector
    b = b(:);
    b = b(small_index);
    
    %Matrix division
    result = A\b;
    
    %Append the image back to background
    I = target(:,:,nDim);
    I = I .* (1 - mask);
    
    I(small_index) = result;
    whole_img(min_x+off_x:max_x+off_x,min_y+off_y:max_y+off_y,nDim)= I + boundary_pixel(:,:,nDim);
end

figure('name','Task 3 - Final Image');
imshow(whole_img);


