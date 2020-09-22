import pystan




dat = {}

dat["ObservedN"] = 4
dat["TraitsObserved"] = [[0.4, 0.2], [0.8, 0.9], [0.2, 0.1], [0.6, 0.6]]
dat["HiddenN"] = 2
dat["TotalN"] = dat["ObservedN"] + dat["HiddenN"]
dat["IsHidden"] = [1]*dat["HiddenN"] + [0]*dat["ObservedN"]
dat["ParentIndex"] = [0, 1, 1, 2, 5, 2]
dat["Total2Observed"] = [0, 0, 1, 2, 3, 4]
dat["Total2Hidden"] = [1, 2, 0, 0, 0, 0]
dat["ParentDistance"] = [0, 0.2, 0.5, 0.1, 0.2, 0.3]
dat["prior_only"] = 0
dat["Components"] = 2


sm = pystan.StanModel(file='2model.stan')


fit = sm.sampling(data=dat, iter=100, chains=1)
la = fit.extract(permuted=True)  # return a dictionary of arrays
print(fit)
print(la)
