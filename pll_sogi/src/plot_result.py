import matplotlib.pyplot as plt
import csv

in_Va = []
in_Vb = []
in_Vc = []
out_d = []
out_q = []
out_theta = []
out_freq = []
  
with open('../solution1/csim/build/inputs.csv','r') as csvfile:
    plots = csv.reader(csvfile, delimiter = ',')
    #(plots)  
    for row in plots:
        in_Va.append(float(row[0]))
        in_Vb.append(float(row[1]))
        in_Vc.append(float(row[2]))

with open('../solution1/csim/build/outputs.csv','r') as csvfile:
    plots = csv.reader(csvfile, delimiter = ',')
    #(plots)  
    for row in plots:
        out_d.append(float(row[0]))
        out_q.append(float(row[1]))
        out_theta.append(float(row[2])*100)
        out_freq.append(float(row[4]))

# print(in_Va)
plt.plot(in_Va, label="Va")
plt.plot(in_Vb, label="Vb")
plt.plot(in_Vc, label="Vc")

plt.plot(out_d, label="d")
plt.plot(out_q, label="q")
plt.plot(out_theta, label="theta")
plt.plot(out_freq, label="w")
plt.legend()
plt.show() 