from scipy.signal import butter, lfilter, sosfilt, sosfreqz
import scipy.signal as signal
import math

"""
x is the input fixed number which is of integer datatype
e is the number of fractional bits for example in Q1.15 e = 15
"""
def to_float(x,e):
    c = abs(x)
    sign = 1 
    if x < 0:
        # convert back from two's complement
        c = x - 1 
        c = ~c
        sign = -1
    f = (1.0 * c) / (2 ** e)
    f = f * sign
    return f
    
"""
f is the input floating point number 
e is the number of fractional bits in the Q format. 
    Example in Q1.15 format e = 15
"""
def to_fixed(f,e):
    a = f* (2**e)
    b = math.floor(a)
    # if a < 0:
    #     # next three lines turns b into it's 2's complement.
    #     b = abs(b)
    #     b = ~b
    #     b = b + 1
    return b

def generateSin(freq, time, amp, sample_rate, random, random_range):
    samples = np.arange(0, time, 1/sample_rate) 
    noise = 0
    if random == 1:
            noise = np.random.randint(random_range, size=(len(samples)))  
            
    wave = amp * np.sin(2 * np.pi * freq * samples)   + noise
    wave = np.int16(wave)
    return wave

def butter_bandpass(lowcut, highcut, Fs, order=5):
    return butter(order, [lowcut, highcut], fs=Fs, btype='band')
    # nyq = 0.5 * Fs
    # low = lowcut / nyq
    # high = highcut / nyq
    # sos = butter(order, [low, high], analog=False, btype='band', output='sos')
    # return sos

def butter_bandpass_filter(data, lowcut, highcut, Fs, order=5):
    b, a = butter_bandpass(lowcut, highcut, Fs, order=order)
    #sos = butter_bandpass(lowcut, highcut, Fs, order=order)

    #print(sos)
        
    print('Numerator Coefficients:', b)
    print('Denominator Coefficients:', a)
       
    nBits = 28   
    #print(to_fixed(abs(sos[0][0]),nBits))
    # print(to_fixed(abs(sos[0][1]),nBits))
    # print(to_fixed(abs(sos[0][2]),nBits))

    # print(to_fixed(abs(sos[0][3]),nBits))
    # print(to_fixed(abs(sos[0][4]),nBits))
    print(to_fixed(abs(b[0]),nBits))
    print(to_fixed(abs(b[1]),nBits))
    print(to_fixed(abs(b[2]),nBits))

    #print(to_fixed(a[0],nBits))
    print(to_fixed(abs(a[1]),nBits))
    print(to_fixed(abs(a[2]),nBits))

    y = lfilter(b, a, data)
    return y
    #y = sosfilt(sos, data)
    #return y



if __name__ == "__main__":
    import numpy as np
    import matplotlib.pyplot as plt
    from scipy.signal import freqz

    # Given specification
    # Sample rate and desired cutoff frequencies (in Hz).
    #orders= np.array([1,2,12])
    N = 6
    Fs = 25e6       # Sampling frequency in Hz
    fc = 60
    lowcut = 59.2
    highcut = 60.8   
          
    # fp = np.array([lowcut, highcut])  # Pass band frequency in Hz
    # fs = np.array([6000, 8000])  # Stop band frequency in Hz
    # Ap = 0.4  # Pass band ripple in dB
    # As = 50  # stop band attenuation in dB    
    
    # # Compute pass band and stop band edge frequencies
    # wp = fp/(Fs/2)  # Normalized passband edge frequencies w.r.t. Nyquist rate
    # ws = fs/(Fs/2)  # Normalized stopband edge frequencies

    # # Compute order of the digital Butterworth filter using signal.buttord
    # N, wc = signal.buttord(wp, ws, Ap, As, analog=False)

    # print(N)
    # print(wc)

    # Plot the frequency response for a few different orders.
    plt.figure(1)
    plt.clf()
    for order in range(N):
        b, a = butter_bandpass(lowcut, highcut, Fs, order=order)       
        w, h = freqz(b, a, fs=Fs, worN=2048)
        #sos = butter_bandpass(lowcut, highcut, Fs, order=order)
        #w, h = sosfreqz(sos, worN=2000)
        plt.plot(w, abs(h), label="order = %d" % order)

    plt.plot([0, 0.5 * Fs], [np.sqrt(0.5), np.sqrt(0.5)],
             '--', label='sqrt(0.5)')
    plt.xlabel('Frequency (Hz)')
    plt.ylabel('Gain')
    plt.grid(True)
    plt.legend(loc='best')

    # Filter a noisy signal.
    T = 20*1/(fc)

    x = generateSin(fc,T,3500, Fs,1,500) 
    nsamples = len(x)
    t = np.arange(0, nsamples) / Fs
    #a = 0.02
    #f0 = fc
    #x = 0.1 * np.sin(2 * np.pi * 1.2 * np.sqrt(t))
    #x += 0.01 * np.cos(2 * np.pi * (f0/1.92) * t + 0.1)
    #x += a * np.cos(2 * np.pi * f0 * t + .11)
    #x += 0.03 * np.cos(2 * np.pi * f0*3.333 * t)
    plt.figure(2)
    plt.clf()
    plt.plot(t, x, label='Noisy signal')

    y = butter_bandpass_filter(x, lowcut, highcut, Fs, order=1)

    plt.plot(t, y, label='Filtered signal (%g Hz)' % fc)
    plt.xlabel('time (seconds)')
    #plt.hlines([-a, a], 0, T, linestyles='--')
    plt.grid(True)
    plt.axis('tight')
    plt.legend(loc='upper left')

    plt.show()