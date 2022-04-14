from typing import Callable, Iterable, Tuple, List
from typing import Iterable, Tuple
from string import Template   
import matplotlib.pyplot as plt 


class ThermalMass():

    def __init__(self, mass: float, cp: float, start_temp: float):
        """Create a thermal mass with the given properties.

        Parameters
        ----------
        mass       : The body's mass in kilograms.
        cp         : The body's specific heat capacity in J/K/kg.
        start_temp : The body's starting temperature, in Kelvin.
        """
        self._mass = mass
        self._cp = cp
        self._temp = start_temp


    def current_temperature(self) -> float:
        """Get the current temperature of the body."""
        return self._temp


    def update(self, heat_in: float, heat_out: float):
        """Update the body state given a certain heat input and output.

        Parameters
        ----------
        heat_in  : The amount of heat added to the body in Joules.
        heat_out : The amount of heat removed from the body in Joules.
        """
        d_q = heat_in - heat_out
        # We find the change in temperature by taking the change in heat and scaling it by the
        # body's heat capacity.
        self._temp += d_q / (self._mass * self._cp)            

class ThermalSystem():

    def __init__(self,
                 mass: ThermalMass,
                 in_flow: Callable[[int], float],
                 out_flow: Callable[[int, float], float]):
        """Create a simple thermal system with the given mass and flow functions.

        Parameters
        ----------
        mass     : A thermal mass to use as the system's body of interest.
        in_flow  : The heat flow rate (in J/s) into the body as a function of time.
        out_flow : The heat flow rate (in J/s) out of the body as a function of time and
                   temperature.
        """
        self._mass = mass
        self._in_flow = in_flow
        self._out_flow = out_flow

        


    def simulate(self, timesteps: Iterable[int]) -> List[Tuple[int, float, float, float]]:
        """Simulate the system behavior over time, and give a state trace.

        This function runs the system state forward using the given timestep
        sequence. At each time point it computes input and output heat flows,
        updates the thermal mass, and records a datapoint for the output trace.
        The trace consists of a sequence of tuples, one for each time point,
        containing the time value, the temperature, and the instantaneous heat
        flow in and out values at that time.

        Parameters
        ----------
        timesteps : A monotonically increasing sequence of timepoints.
        """
        trace = []
        it = timesteps.__iter__()
        last_t = it.__next__()
        temp = self._mass.current_temperature()
        flow_in = self._in_flow(last_t)
        flow_out = self._out_flow(last_t, temp)

        self.time = []
        self.temp = []
        self.flow_in = []
        self.flow_out = [] 

        self.time.append(last_t)
        self.temp.append(temp)
        self.flow_in.append(flow_in)
        self.flow_out.append(flow_out)
        

        for t in it:
            dt = t - last_t
            last_t = t

            heat_in = flow_in * dt
            heat_out = flow_out * dt

            self._mass.update(heat_in, heat_out)

            temp = self._mass.current_temperature()
            flow_in = self._in_flow(t)
            flow_out = self._out_flow(t, temp)
           
            self.time.append(last_t)
            self.temp.append(temp)
            self.flow_in.append(flow_in)
            self.flow_out.append(flow_out)





class GraphicalFixture():

    GNUPLOT_TEMPLATE = Template("""
    # set term pngcairo transparent truecolor
    set term svg
    set output "$output_file"

    set datafile separator ","

    set timefmt '%S'
    set format x ""
    set xdata time

    set key noautotitle
    set xlabel 'Time'

    set style line 101 lw 2 lt rgb "#ba0306"
    set style line 102 lw 2 lt rgb "#aaaaaa"
    set style line 103 lw 2 lt rgb "#2e2e2e"

    set style line 11 lc rgb '#808080' lt 1
    set border 3 back ls 11
    set tics nomirror

    set multiplot layout 3,1 rowsfirst

    set title "Input"
    set ylabel "Flow Rate"
    set ytics scale 0.5 $y1_scale
    plot "$input_file" using 1:3 with lines ls 102

    set title "System State"
    set ylabel "Temperature"
    set ytics scale 0.5 $y2_scale
    plot "$input_file" using 1:2 with lines ls 101

    set title "Control"
    set ylabel "Flow Rate"
    set ytics scale 0.5 $y3_scale
    plot "$input_file" using 1:4 with lines ls 103

    unset multiplot
    """)

    def __init__(self, name: str, system: ThermalSystem):
        self._name = name
        self._system = system


    def simulate(self,
                 timesteps: Iterable[int],
                 y_scales: Tuple[int, int, int] = (10, 1, 20)) -> str:
        """Run the simulation over the given timesteps and plot the state.

        Returns a filename containing the state plot.
        """
        self._system.simulate(timesteps)
       
        plt.subplot(3, 1, 1)
        plt.plot(self._system.time,self._system.flow_in, label="input")
        plt.title("Input")
        
        plt.subplot(3, 1, 2)
        plt.plot(self._system.time,self._system.temp)
        plt.title("System State")

        plt.subplot(3, 1, 3)
        plt.plot(self._system.time,self._system.flow_out)
        plt.title("Control")
        
        plt.show()
         