# TPPMTestFeeders
Generates and validates TPPM data models for common test feeders. Some of these require some adjustment after the call to the OpenDSS parser, and are therefore contained here for now.

## Dependencies
Note that this code relies on a version of ThreePhasePowerModels (TPPM) that is still being merged. You can find it in my fork of TPPM, in the [branch 'loadmodels'](https://https://github.com/sanderclaeys/ThreePhasePowerModels.jl/tree/loadmodels).

This can be installed by executing
```
 ]add https://github.com/sanderclaeys/ThreePhasePowerModels.jl#loadmodels
```

## Included test feeders

|publisher|name|status|files|OpenDSS|
|---    |---    |---        |---|---|
|IEEE   |IEEE13 |validated  |[zip](http://sites.ieee.org/pes-testfeeders/files/2017/08/feeder13.zip)|[@GitHub](https://github.com/tshort/OpenDSS/blob/master/Test/IEEE13_Assets.dss) |
|IEEE   |IEEE34 |planned    |[zip](http://sites.ieee.org/pes-testfeeders/files/2017/08/feeder34.zip)  |?   |
|IEEE   |IEEE37 |planned    |[zip](http://sites.ieee.org/pes-testfeeders/files/2017/08/feeder37.zip)  |?   |
|IEEE   |IEEE123 |planned    |[zip](http://sites.ieee.org/pes-testfeeders/files/2017/08/feeder123.zip)  |?   |

### IEEE13
"This circuit model is very small and used to test common features of distribution analysis software, operating at 4.16 kV. It is characterized by being short, relatively highly loaded, a single voltage regulator at the substation, overhead and underground lines, shunt capacitors, an in-line transformer, and unbalanced loading." [[source]](http://sites.ieee.org/pes-testfeeders/resources/)

### IEEE34
"This feeder is an actual feeder located in Arizona, with a nominal voltage of 24.9 kV. It is characterized by long and lightly loaded, two in-line regulators, an in-line transformer for short 4.16 kV section, unbalanced loading, and shunt capacitors." [[source]](http://sites.ieee.org/pes-testfeeders/resources/)

### IEEE37
"This feeder is an actual feeder in California, with a 4.8 kV operating voltage. It is characterized by delta configured, all line segments are underground, substation voltage regulation is two single-phase open-delta regulators, spot loads, and very unbalanced. This circuit configuration is fairly uncommon." [[source]](http://sites.ieee.org/pes-testfeeders/resources/)

### IEEE123
"The IEEE 123 node test feeder operates at a nominal voltage of 4.16 kV. While this is not a popular voltage level it does provide voltage drop problems that must be solved with the application of voltage regulators and shunt capacitors. This circuit is characterized by overhead and underground lines, unbalanced loading with constant current, impedance, and power, four voltage regulators, shunt capacitor banks, and multiple switches.This circuit is “well-behaved” with minimal convergence problems." [[source]](http://sites.ieee.org/pes-testfeeders/resources/)
