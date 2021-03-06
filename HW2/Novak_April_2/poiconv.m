function [errors] = poiconv(pv, hmax, nrefmax)

errors = zeros(1, nrefmax);
tol = 1e-10;

% compute the reference solution
[p_ref, t, e] = pmesh(pv, hmax, nrefmax);
a_ref = fempoi(p_ref, t, e);

for nref = 0:(nrefmax - 1)
    [p, t, e] = pmesh(pv, hmax, nref);
    a = fempoi(p, t, e);

    k = 1;
    error = [];

    % loop over all the points in the ref soln to find the maximum error
    for i = 1:length(p_ref)
        % loop over all the points in the new soln
        for j = 1:length(p)
            % check if x-coordinates match
            if abs(p_ref(i, 1) - p(j, 1)) <= tol
                % check if y-coordinates match
                if abs(p_ref(i, 2) - p(j, 2)) <= tol
                    % compute the error at the shared node
                    error(k) = abs(a_ref(i) - a(j));
                    k = k + 1;
                end
            end
        end
    end

    % determine the max-norm (maximum element in error())
    errors(nref + 1) = max(error);
end

end

