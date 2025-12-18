## State Machines

An implementation of a finite state machine as well as a state machine with a push automata as a node.  

A state machine handles processing of input, frames, and physics for a current state and transitioning between states.  
Each state has an enter and exit callback as well as processing callbacks. Signals are also emitted for this.  
A state machine is also a state itself! This allows for nested state machines.  

Additionally there is a "predictable" state implementation that separates logic and visuals for situations where you
might want animations, sounds, etc. to not play for a while, e.g. client side prediction reconciliation.

For more information on how to use the state machines and states, refer to the in-engine documentation.
