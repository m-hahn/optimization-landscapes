with open("us.tsv", "r") as inFile:
    data = [x.replace('"', "").split("\t") for x in inFile.read().strip().split("\n")]
    if len(data[0]) < len(data[1]):
        data[0] = ["_"]+data[0]
header = data[0]
header = dict(list(zip(header, range(len(header)))))
data = data[1:]

from math import sqrt
observations = {}
for line in data:
    trajectory = line[header["Trajectory"]]
    time = line[header["Time"]]
    x = float(line[header["OSSameSide_Real_Prob"]])
    y = float(line[header["OSSameSide"]])
    if trajectory not in observations:
        observations[trajectory] = []
    a, b = 1, -1
    y1 = (abs( a*x + b*y  )) / (sqrt( a*a + b*b))
    a, b = 1, 1
    y2 = abs( a*x + b*y ) / (sqrt( a*a + b*b))
    observations[trajectory].append((int(time)/1000.0, (y1,y2)))

observations = [y for _, y in observations.items()]

import torch

xmean = torch.FloatTensor([0.0])
xmean.requires_grad=True
eta = torch.FloatTensor([0.0])
eta.requires_grad=True
sigma = torch.FloatTensor([1.0])
sigma.requires_grad = True

optim = torch.optim.SGD([xmean, eta, sigma], lr=0.0001)


# http://www.investmentscience.com/Content/howtoArticles/MLE_for_OR_mean_reverting.pdf

#observations = [[(0, (0, 0)), (1, (1, 1))]]

for it in range(1000000):
    eta_ = torch.log(1+torch.exp(eta))
#    print([(x[1][1][1], x[0][1][1]) for x in observations])
#    likelihood = -len(observations)/2 * torch.log(sigma.pow(2) / 2*eta_) - 1/2 * sum(torch.log(1-torch.exp(-2*eta_*(x[1][0] - x[0][0]))) for x in observations)
 #   likelihood = likelihood - eta_ / sigma.pow(2) * sum(((x[1][1][1] - xmean) - (x[0][1][1] - xmean) * torch.exp(-eta_*(x[1][0]-x[0][0]))).pow(2)/(1-torch.exp(-2*eta_*((x[1][0]-x[0][0])))) for x in observations)
 # Page 6, formula (2.5) in Parameter estimation and bias correction for diffusion processes" by Tang and Chen 
    likelihood = - eta_ / sigma.pow(2) * sum(((x[1][1][0] - xmean) - (x[0][1][0] - xmean) * torch.exp(-eta_*(x[1][0]-x[0][0]))).pow(2)/(1-torch.exp(-2*eta_*((x[1][0]-x[0][0])))) for x in observations)
    likelihood -= eta_/sigma.pow(2) * sum((x[0][1][0] - xmean).pow(2) for x in observations)
    print(likelihood, xmean, eta, sigma)
    optim.zero_grad()
    (-likelihood).backward()
    optim.step()

