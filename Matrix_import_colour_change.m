foreground = im2double(imread('task_5.jpg'));
BW = roipoly(foreground);

%luminance = 0.2989 red + 0.5870 green + 0.1140 blue.
luminance = zeros(size(foreground));
luminance(:,:,1) =  foreground(:,:,1)*0.2989;
luminance(:,:,2) =  foreground(:,:,2)*0.5870;
luminance(:,:,3) =  foreground(:,:,3)*0.1140;

%Find the editing area
[x,y] = find(BW);
min_x = min(x) - 1;
max_x = max(x) + 1;
min_y = min(y) - 1;
max_y = max(y) + 1;

mask = BW(min_x:max_x,min_y:max_y);
target = luminance(min_x:max_x,min_y:max_y,:);
source = foreground(min_x:max_x,min_y:max_y,:);

%Mask have no boundary, and boundary mask
small_mask = imerode(mask,[0 1 0;1 1 1;0 1 0]);
boundary = xor(mask,small_mask); 

%Produce area images
selected_area = zeros(size(source));
boundary_pixel = zeros(size(source));
small_area = zeros(size(source));

for nDim = 1:3
    selected_area(:,:,nDim) = source(:,:,nDim) .* mask;
    boundary_pixel(:,:,nDim) = target(:,:,nDim) .* boundary;
    small_area(:,:,nDim) = source(:,:,nDim) .* small_mask;
end

%Jacobian 
lapla_boundary = imfilter(boundary_pixel,[0 1 0;1 0 1;0 1 0]);
lapla_target = imfilter(target,[0 -1 0;-1 4 -1;0 -1 0]);
lapla_source = imfilter(source,[0 -1 0;-1 4 -1;0 -1 0]);
%Ax = b
%Build the NumGrid
num_grid = zeros(size(small_mask));
num_small = length(find(small_mask)); 
small_index = find(small_mask(:));
num_grid(small_index) = 1:num_small;
%Build the A
A = delsq(num_grid);
whole_img = luminance;

for nDim = 1:3
    %Build b (Guide Matrix)
        %Build b (Guide Matrix)
    b = lapla_source(:,:,nDim);
    b = b + lapla_boundary(:,:,nDim);
    
    %To vector
    b = b(:);
    b = b(small_index);
    
    %Matrix division
    result = A\b;
    
    %Append result to background
    I = target(:,:,nDim);
    I = I .* (1 - mask);
    I(small_index) = result;
    whole_img(min_x:max_x,min_y:max_y,nDim)= I + boundary_pixel(:,:,nDim);
end

%Convert back to RGB
whole_img(:,:,1) =  whole_img(:,:,1)/0.2989;
whole_img(:,:,2) =  whole_img(:,:,2)/0.5870;
whole_img(:,:,3) =  whole_img(:,:,3)/0.1140;
figure('name','Task 3 - Final Image');
imshow(whole_img);
