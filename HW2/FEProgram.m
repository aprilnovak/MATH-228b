clear all

num_nodes_per_elem = 3;         % linear triangular elements
qp_order = 1;                   % order of the quadrature rule

% form the permutation matrix for assembling the global matrices
[permutation] = permutation(num_nodes_per_elem);

% perform meshing using unstructured triangles
% t represents the Location Matrix (LM) - put in desired case number

test_case = 3;

switch(test_case)
    case 1
        pv = [0,0; 1,0; 1,1; 0,1; 0,0]; hmax = 0.15;
        [p, LM, e] = pmesh(pv, hmax, 0);
        dirichlet_nodes(1,:) = e(p(e,1) < 1e-6 | p(e,2) < 1e-6);
    case 2
        n = 32; phi = 2*pi*(0:n)'/n; hmax = 2*pi/n;
        pv = [cos(phi), sin(phi)];
        [p, LM, e] = pmesh(pv, hmax, 0);
        dirichlet_nodes(1,:) = e;
    case 3
        x = (0:0.1:1)'; y = 0.1 * cos(10*pi*x); hmax = 0.1;
        pv = [x, y; 0.5, 0.6; 0, 0.1];
        [p, LM, e] = pmesh(pv, hmax, 0);
        dirichlet_nodes(1,:) = e(p(e,2) > 0.6 - abs(p(e,1) - 0.5) - 1e-6);
    case 4
        pv = [1,0; 2,0; 3,1; 3,2; 2,3; 1,3; 0,2; 0,1; 1,0]; hmax = 0.25;
        [p, LM, e] = pmesh(pv, hmax, 0);
        dirichlet_nodes(1,:) = e;
    otherwise
        disp('Select an appropriate case number to run!')
end

num_elem = length(LM(:,1)); 

% specify the boundary conditions - homogeneous neumann and dirichlet
dirichlet_nodes(2,:) = zeros .* dirichlet_nodes(1,:);
a_k = dirichlet_nodes(2,:);
num_nodes = length(p(:,1));

% define the quadrature rule
[wt, qp] = quadrature(qp_order);

% assemble the elemental k and elemental f
K = zeros(num_nodes);
F = zeros(num_nodes, 1);

for elem = 1:num_elem
    k = 0;
    f = 0;

    for ll = 1:length(qp) % eta loop
         for l = 1:length(qp) % xe loop
            [N, dN_dxe, dN_deta, x_xe_eta, y_xe_eta, dx_dxe, dx_deta, dy_dxe, dy_deta, B] = shapefunctions(qp(l), qp(ll), num_nodes_per_elem, p, LM, elem);
            F_mat = transpose([dx_dxe, dx_deta; dy_dxe, dy_deta]);
            J = det(F_mat);

            % assemble the (elemental) forcing vector
            f = f + wt(ll) * wt(l) * transpose(N) * J;

            % assemble the (elemental) stiffness matrix - correct
            k = k + wt(ll) * wt(l) * transpose(inv(F_mat) * B) * inv(F_mat) * B * J;      
         end
    end

    % place the elemental k matrix into the global K matrix
    for m = 1:length(permutation(:,1))
       i = permutation(m,1);
       j = permutation(m,2);
       K(LM(elem, i), LM(elem, j)) = K(LM(elem, i), LM(elem, j)) + k(i,j);
    end

    % place the elemental f matrix into the global F matrix
    for i = 1:length(f)
       F(LM(elem, i)) = F((LM(elem, i))) + f(i);
    end
end

% perform static condensation to remove known Dirichlet nodes from solve
[K_uu, K_uk, F_u, F_k] = condensation(K, F, num_nodes, dirichlet_nodes);

% perform the solve
a_u_condensed = K_uu \ (F_u - K_uk * dirichlet_nodes(2,:)');

% expand a_condensed to include the Dirichlet nodes
a = zeros(num_nodes, 1);

a_row = 1;
i = 1;      % index for dirichlet_nodes
j = 1;      % index for expanded row

for a_row = 1:num_nodes
    if (find(dirichlet_nodes(1, :) == a_row))
        a(a_row) = dirichlet_nodes(2,i);
        i = i + 1;
    else
        a(a_row) = a_u_condensed(j);
        j = j + 1;
    end
end

tplot(p, LM, a)