import pystan


sm = pystan.StanModel(file='1model.stan')


schools_dat = {}
schools_dat['N'] = 3
schools_dat['Y'] = [0.2, 0.6, 0.1]
schools_dat['N_1'] = 2
schools_dat['M_1'] = 1
schools_dat["J_1"] = [1, 1, 2]
schools_dat['Z_1_1'] = [0.1, 0.6, 0.2]
schools_dat ["prior_only"] = 0              


#sm = pystan.StanModel(model_code=schools_code)



fit = sm.sampling(data=schools_dat, iter=100, chains=1)
la = fit.extract(permuted=True)  # return a dictionary of arrays
print(fit)
print(la)
