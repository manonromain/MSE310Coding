%% RAC - MBADMM - non negative least squares
% MSE 310 Linear Programming
% project 3
% Stephen Palmieri


%% RAC
clear all;close all;clc;
n = 10;
p = 20;
n = 100;
p = 200;
blocks = 5;
rng(5)
y = sprandn(n,1,.1);
X = sprandn(n,p,.1);

beta_true = pos(sprandn(p,1,.1));
y = X*beta_true;

beta0 = pos(sprandn(p,1,.1));
z0 = pos(sprandn(p,1,.1));
mu0 = pos(sprandn(p,1,.1));
gamma = 10;

k = 1;
err(k) = norm(beta_true-beta0,2);
err_bz(k) = norm(beta0-z0,2);
toler = 1e-4;
maxIter = 1000;
for ii = 1:maxIter

[beta_out,z_out,mu_out] = rac_nnls(y,X,beta0,z0, mu0, blocks);
beta0 = beta_out;
z0 = z_out;
mu0 = mu_out;
beta(:,k) = beta_out;
z(:,k) = z_out;
mu(:,k) = mu_out;
obj(k) = 1/(2*n) * (y-X*beta_out)'*(y-X*beta_out);
obj_al(k) = obj(k) + gamma/2*norm(beta_out-z_out,2)^2 - mu_out'*(beta_out-z_out);
k = k+1;

% err(k) = norm(beta_out-z_out,2);
err(k) = norm(beta_true-beta_out,2);
err_bz(k) = norm(beta_out-z_out,2);
% if abs(err(k)-err(k-1))  < toler
if err(k) < toler
    disp('below tolerance')
    break
else
end

end

figure
plot(1:k,err)
xlabel('iterations')
ylabel('error')
title('l-2 norm \beta error from true value')

figure
plot(1:k,err_bz)
xlabel('iterations')
ylabel('error')
title('l-2 norm (\beta - z) error')

figure
plot(obj)
hold on
% plot(obj_al)
legend('original obj','augmented Lagrangian')
xlabel('iterations')
ylabel('objective loss')
title('Non-negative Least Squares Objective Loss vs Iterations using RAC-MBADMM')

%% Randomly Permute Comparison - Section IV
clear all;close all;clc;
n = 100;
p = 200;
blocks = p;

rng(5)
y = sprandn(n,1,.1);
X = sprandn(n,p,.1);

beta_true = pos(sprandn(p,1,.1));
y = X*beta_true;

beta0 = pos(sprandn(p,1,.1));
z0 = pos(sprandn(p,1,.1));
mu0 = pos(sprandn(p,1,.1));
gamma = 10;

k = 1;
err(k) = norm(beta_true-beta0,2);
err_bz(k) = norm(beta0-z0,2);
toler = 1e-3;
maxIter = 1000;

for ii = 1:maxIter

[beta_out,z_out,mu_out] = rp_nnls(y,X,beta0,z0, mu0, blocks);
beta0 = beta_out;
z0 = z_out;
mu0 = mu_out;
beta(:,k) = beta_out;
z(:,k) = z_out;
mu(:,k) = mu_out;
obj(k) = 1/(2*n) * (y-X*beta_out)'*(y-X*beta_out);
obj_al(k) = obj(k) + gamma/2*norm(beta_out-z_out,2)^2 - mu_out'*(beta_out-z_out);
k = k+1;

% err(k) = norm(beta_out-z_out,2);
err(k) = norm(beta_true-beta_out,2);
err_bz(k) = norm(beta_out-z_out,2);
if err(k) <toler
    disp('below tolerance')
    break
else
end

end
figure
plot(1:k,err)
xlabel('iterations')
ylabel('error')
title('l-2 norm \beta error from true value')

figure
plot(1:k,err_bz)
xlabel('iterations')
ylabel('error')
title('l-2 norm (\beta - z) error')

figure
plot(obj)
hold on
plot(obj_al)
legend('original obj','augmented Lagrangian')
xlabel('iterations')
ylabel('objective loss')
title('Non-negative Least Squares Objective Loss vs Iterations using RP-MBADMM')

%% functions

function [beta, z, mu] = rac_nnls(y, X, beta, z, mu, blocks)
% alpha = 1.8; %this should be the same as the gamma according to their
% paper

gamma = 1;
% gamma = 1000;
[n,p] = size(X); 
block_size = floor(p/blocks);
or = randperm(2*p);

% for each block
    for j = 1:blocks
        idx_lb = (j-1)*block_size +1;
        idx_ub = idx_lb + block_size -1;
        indices = or(idx_lb:idx_ub);
        for ii = 1:block_size
            val = indices(ii);
            
            if val < p %update beta
                tmpX = X(:,indices(ii));
                tmp(ii) = (1/n*tmpX'*tmpX + gamma) \ (1/n* tmpX'*y + mu(indices(ii)) + gamma*z(indices(ii)));
            else %update z
                if val == 2*p
                    val_idx = val-p;
                elseif val == p
                    val_idx = val-p+1;
                else
                    val_idx = val-p+1;
                end
                tmp(ii) = pos(-mu(val_idx) / gamma + beta(val_idx));
            end
        end
        for jj = 1:block_size
            if indices(jj) < p
                beta(indices(jj)) = tmp(jj);
            else
                if indices(jj) == 2*p
                    val_idx = indices(jj)-p;
                elseif indices(jj) == p
                    val_idx = indices(jj)-p+1;
                else
                    val_idx = indices(jj)-p+1;
                end
                z(val_idx) = tmp(jj);
            end
        end
        
%         tmpX = X(:,indices);
%         beta(indices) = -inv(1/n*tmpX'*tmpX + gamma*eye(block_size)) *(1/n* tmpX'*y - mu(indices) - gamma*z(indices));
%         beta(indices) = (1/n*tmpX'*tmpX + gamma*eye(block_size)) \ (1/n* tmpX'*y + mu(indices) + gamma*z(indices));
        
    end
    %max(z,0) is what pos does
%     z = pos(-mu./(gamma) + beta);
    mu = mu - gamma*(beta-z);
    
end

function [beta, z, mu] = rp_nnls(y, X, beta, z, mu, blocks)
% alpha = 1.8; %this should be the same as the gamma according to their
% paper

gamma = 1;
[n,p] = size(X); 
block_size = floor(p/blocks);
or = randperm(2*p);

% for each block
    for j = 1:blocks
        idx_lb = (j-1)*block_size +1;
        idx_ub = idx_lb + block_size -1;
        indices = or(idx_lb:idx_ub);
        for ii = 1:block_size
            val = indices(ii);
            
            if val < p %update beta
                tmpX = X(:,indices(ii));
                tmp(ii) = (1/n*tmpX'*tmpX + gamma) \ (1/n* tmpX'*y + mu(indices(ii)) + gamma*z(indices(ii)));
            else %update z
                if val == 2*p
                    val_idx = val-p;
                elseif val == p
                    val_idx = val-p+1;
                else
                    val_idx = val-p+1;
                end
                tmp(ii) = pos(-mu(val_idx) / gamma + beta(val_idx));
            end
        end
        for jj = 1:block_size
            if indices(jj) < p
                beta(indices(jj)) = tmp(jj);
            else
                if indices(jj) == 2*p
                    val_idx = indices(jj)-p;
                elseif indices(jj) == p
                    val_idx = indices(jj)-p+1;
                else
                    val_idx = indices(jj)-p+1;
                end
                z(val_idx) = tmp(jj);
            end
        end
        
%         tmpX = X(:,indices);
%         beta(indices) = -inv(1/n*tmpX'*tmpX + gamma*eye(block_size)) *(1/n* tmpX'*y - mu(indices) - gamma*z(indices));
%         beta(indices) = (1/n*tmpX'*tmpX + gamma*eye(block_size)) \ (1/n* tmpX'*y + mu(indices) + gamma*z(indices));
        
    end
    %max(z,0) is what pos does
%     z = pos(-mu./(gamma) + beta);
    mu = mu - gamma*(beta-z);
    
end
