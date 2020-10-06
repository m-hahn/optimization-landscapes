import numpy as np
B= np.matrix([[0.3, 0.7], [0.1, -0.2]])
factor = np.matrix([[2*B[0,0], 2*B[0,1], 0], [B[1,0], B[0,0]+B[1,1], B[0,1]], [0, 2*B[1,0], 2*B[1,1]]])
Sigma = np.matrix([[1, 0.2], [0.2, 1.2]])
instant_cov_components = np.matrix([[Sigma[0,0]], [Sigma[0,1]], [Sigma[1,1]]])
Omega_components = np.matmul(np.linalg.inv(factor), instant_cov_components)
print(factor)
print(np.linalg.inv(factor), "\n", instant_cov_components, "\n", Omega_components)
Omega = np.matrix([[Omega_components[0,0], Omega_components[1,0]], [Omega_components[1,0], Omega_components[2,0]]])
print(np.matmul(B, Omega) + np.matmul(Omega, B.transpose()))
print(Sigma)

