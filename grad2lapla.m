function lapla = grad2lapla (hori,verti)
    %Calculate the divergence of the gradient
    lapla = circshift(hori,[0,1]) + circshift(verti,[1,0]) - hori - verti;
end