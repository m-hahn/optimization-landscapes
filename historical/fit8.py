with open("us.tsv", "r") as inFile:
    data = [x.replace('"', "").split("\t") for x in inFile.read().strip().split("\n")]
    if len(data[0]) < len(data[1]):
        data[0] = ["_"]+data[0]
header = data[0]
header = dict(list(zip(header, range(len(header)))))
data = data[1:]

from math import sqrt, log
import math

observations = {}
for line in data:
    trajectory = line[header["Trajectory"]]
    time = line[header["Time"]]
    x = float(line[header["OSSameSide_Real_Prob"]])
    y = float(line[header["OSSameSide"]])
    if trajectory not in observations:
        observations[trajectory] = []
#    a, b = 1, -1
 #   y1 = (( a*x + b*y  )) / (sqrt( a*a + b*b))
  #  a, b = 1, 1
   # y2 = ( a*x + b*y ) / (sqrt( a*a + b*b))
    observations[trajectory].append((int(time)/1000.0, (x,y)))

observations = [y for _, y in observations.items()]

import torch

xmean = torch.FloatTensor([0.0])
xmean.requires_grad=True
eta = torch.FloatTensor([-0.0])
eta.requires_grad=True
sigma = torch.FloatTensor([1.0])
sigma.requires_grad = True

xmean2 = torch.FloatTensor([0.0])
xmean2.requires_grad=True
eta2 = torch.FloatTensor([-0.0])
eta2.requires_grad=True
sigma2 = torch.FloatTensor([1.0])
sigma2.requires_grad = True

optim = torch.optim.SGD([xmean, eta, sigma, xmean2, eta2, sigma2], lr=0.001)


# http://www.investmentscience.com/Content/howtoArticles/MLE_for_OR_mean_reverting.pdf

#observations = [[(0, (0, 0)), (1, (1, 1))]]

#tensor([-0.0107], grad_fn=<SubBackward0>) tensor([0.1090], requires_grad=True) tensor([-4.0093], requires_grad=True) tensor([2.9276], requires_grad=True)


for it in range(1000000):
    eta_ = torch.log(1+torch.exp(eta))
    eta2_ = torch.log(1+torch.exp(eta2))
#    print([(x[1][1][1], x[0][1][1]) for x in observations])
#    likelihood = -len(observations)/2 * torch.log(sigma.pow(2) / 2*eta_) - 1/2 * sum(torch.log(1-torch.exp(-2*eta_*(x[1][0] - x[0][0]))) for x in observations)
 #   likelihood = likelihood - eta_ / sigma.pow(2) * sum(((x[1][1][1] - xmean) - (x[0][1][1] - xmean) * torch.exp(-eta_*(x[1][0]-x[0][0]))).pow(2)/(1-torch.exp(-2*eta_*((x[1][0]-x[0][0])))) for x in observations)
 # Page 6, formula (2.5) in Parameter estimation and bias correction for diffusion processes" by Tang and Chen 
    likelihood = - 2 * eta_ / sigma.pow(2) * sum(((x[1][1][0] - xmean) - (x[0][1][0] - xmean) * torch.exp(-eta_*(x[1][0]-x[0][0]))).pow(2)/(1-torch.exp(-2*eta_*((x[1][0]-x[0][0])))) for x in observations)
    likelihood += - 2 * eta2_ / sigma2.pow(2) * sum(((x[1][1][1] - xmean2) - (x[0][1][1] - xmean2) * torch.exp(-eta2_*(x[1][0]-x[0][0]))).pow(2)/(1-torch.exp(-2*eta2_*((x[1][0]-x[0][0])))) for x in observations)
    likelihood -= sum(torch.log(1/2 * sigma.pow(2) * (1-torch.exp(-2*eta_*((x[1][0]-x[0][0])))) / eta_)/2 for x in observations)
    likelihood -= sum(torch.log(1/2 * sigma2.pow(2) * (1-torch.exp(-2*eta2_*((x[1][0]-x[0][0])))) / eta2_)/2 for x in observations)
    likelihood -= 2 * len(observations) * log(sqrt(2*math.pi))
    print(likelihood, xmean, eta, sigma, xmean2, eta2, sigma2)
    optim.zero_grad()
    (-likelihood).backward()
    optim.step()

