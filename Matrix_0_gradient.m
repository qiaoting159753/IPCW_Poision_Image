foreground = im2double(imread('test1_target.jpg'));
foreground = rgb2gray(foreground);
BW = roipoly(foreground);

%Find the editing area
[x,y] = find(BW);
min_x = min(x) - 1;
max_x = max(x) + 1;
min_y = min(y) - 1;
max_y = max(y) + 1;

mask = BW(min_x:max_x,min_y:max_y);
source = foreground(min_x:max_x,min_y:max_y);

%Mask have no boundary, and boundary mask
small_mask = imerode(mask,[0 1 0;1 1 1;0 1 0]);
boundary = xor(mask,small_mask); 

%Build the Guided Matrix
boundary_pixel = source .* boundary;
lapla_boundary = imfilter(boundary_pixel,[0 1 0;1 0 1;0 1 0]);

%Ax = b
%Build the NumGrid
num_grid = zeros(size(small_mask));
num_small = length(find(small_mask)); 
small_index = find(small_mask(:));
num_grid(small_index) = 1:num_small;
%Build the A
A = delsq(num_grid);

whole_img = foreground;
%Build b    
b = zeros(size(source));
b = b + lapla_boundary;
b = b(:);
b = b(small_index);

%Matrix division    
result = A\b;
source = source .* (1 - mask);
    
%Append result back to background
source(small_index) = result;
whole_img(min_x:max_x,min_y:max_y)= source + boundary_pixel;

figure('name','Task 3 - Final Image');
imshow(whole_img);


