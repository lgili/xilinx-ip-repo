from typing import Callable, Iterable, Tuple, List

class PidController():
    """A classical PID controller which maintains state between calls.

    This class is intended to be integrated into an external control loop. It
    remembers enough of the state history to compute integral and derivative
    terms, and produces a combined control signal with the given gains.
    """

    def __init__(self,
                 kp: float,
                 ki: float,
                 kd: float,
                 target: float,
                 initial_state: float,
                 t_0: int) -> None:
        """Create a PID controller with the specified gains and initial state.

        Parameters
        ----------
        kp, ki, kd    : The PID control gains.
        target        : The desired system state, also called a "setpoint".
        initial_state : The starting state of the system.
        t_0           : The starting time.
        """
        # Gains for the proportional, integral, and derivative terms.
        self._kp: float = kp
        self._ki: float = ki
        self._kd: float = kd

        # The target state which the controller tries to maintain.
        self._target: float = target

        # Tracks the integrated error over time. This starts at 0 as no time has passed.
        self._accumulated_error: float = 0.0
        # Tracks the previous sample's error to compute derivative term.
        self._last_error: float = initial_state - target
        # Tracks the previous sample time point for computing the d_t value used in I and D terms.
        self._last_t: int = t_0

    def next(self, t: int, state: float) -> float:
        """Incorporate a sample of the state at time t and produce a control value.

        Because the controller is stateful, calls to this method should be
        monotonic - that is, subsequent calls should not go backwards in time.

        Parameters
        ----------
        t     : The time at which the sample was taken.
        state : The system state at time t.
        """
        error = state - self._target
        d_t = (t - self._last_t)
        p = self._proportional(error)
        i = self._integral(d_t, error)
        d = self._derivative(d_t, error)
        self._last_t = t
        self._last_error = error
        return p + i + d
    
    def _proportional(self, error: float) -> float:
        return self._kp * error


    def _integral(self, d_t: float, error: float) -> float:
        # The constant part of the error.
        base_error = min(error, self._last_error) * d_t
        # Adjust by adding a little triangle on the constant part.
        error_adj = abs(error - self._last_error) * d_t / 2.0
        self._accumulated_error += base_error + error_adj
        return self._ki * self._accumulated_error


    def _derivative(self, d_t: float, error: float) -> float:
        d_e = (error - self._last_error)
        if d_t > 0:
            return self._kd * (d_e / d_t)
        else:
            return 0
