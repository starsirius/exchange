# States

An Exchange order is modeled as a [finite-state machine][state_machine]. We use the [MicroMachine][micromachine] gem
to [build the state machine][build_machine]. The following state diagram illustrates the states and transitions:

![][diagram_published]

Diagram editable [here][diagram_source].

[state_machine]: https://en.wikipedia.org/wiki/Finite-state_machine
[micromachine]: https://github.com/soveran/micromachine
[build_machine]: https://github.com/artsy/exchange/blob/83ebfa0e018faf18ccb09ff1f2129ce35f9b2a84/app/models/order.rb#L270-L286
[diagram_published]: https://docs.google.com/drawings/d/e/2PACX-1vRLVXWTFCeqDMQpR8CHrYhv_JvDIuQcuNbei0BaYOuzq7sSl0715twW9y4P6wfqPxGjPFanA-N51wlr/pub?w=840&h=892
[diagram_source]: https://docs.google.com/drawings/d/1-Ak7IsfodYlcjZoIDM9zakCfLhisSUqeWfx1H6TeGb8/edit?usp=sharing
