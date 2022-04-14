

import python.thermal as thermal
import python.PidController as PID



# First test
TARGET_TEMP = 0
total_simulate_time = 200

# Create our PID controller with some initial values for the gains.
controller = PID.PidController(0.0, 1.0, 0.0, TARGET_TEMP, TARGET_TEMP, 0)


mass = thermal.ThermalMass(1.0, 4000, TARGET_TEMP)
in_flow = lambda t: total_simulate_time
out_flow = lambda t, s: controller.next(t, s) * total_simulate_time
system = thermal.ThermalSystem(mass, in_flow, out_flow)
f = thermal.GraphicalFixture("pid_linear", system)
f.simulate(range(0, total_simulate_time), y_scales=(1, 1, 40))            