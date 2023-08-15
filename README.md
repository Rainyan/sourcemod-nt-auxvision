# sourcemod-nt-auxvision
Experimental SourceMod plugin for Neotokyo that makes vision modes use AUX power, with optional class filtering. By default, only assault vision is affected.

[Example](https://github.com/Rainyan/sourcemod-nt-auxvision/assets/6595066/d7b3bc6c-3577-4db1-a2a9-c69af16f80a1)

## Build requirements
* SourceMod 1.7.3 or newer
* The [neotokyo.inc include](https://github.com/softashell/sourcemod-nt-include/blob/master/scripting/include/neotokyo.inc), version 1.1 or newer

## Config
These cvars are recommended to be stored in `cfg/sourcemod/plugin.nt_auxvision.cfg`. This config file is automatically generated with the below default values on first run.

The default values are balanced around 8 seconds (the duration of the assault class's thermoptic cloak).

* `sm_auxvision_lenght_secs`
  * For how long, in seconds, the vision mode can be kept on at full AUX level.
  * default: `8.0`, minimum: `0.001`
* `sm_auxvision_cooldown_secs`
  * For how long, in seconds, can the vision mode not be enabled after exhausting it.
  * default: `4.0`, minimum: `0`
* `sm_auxvision_initial_cost`
  * How much AUX does starting the vision mode cost.
  * default: `4.0`, minimum: `0`, maximum: `100`
* `sm_auxvision_class_bits`
  * Bit flags for which classes to enable AUX cost for.
  * default: 2 (assault only)
  * Note that since supports have no AUX, enabling vision AUX cost for them will disable the support vision mode entirely.
  * Possible values: 0 (no classes) to 7 (`(1|2|4)` i.e. all classes)
  * Example values: 1 (recon only), 2 (assault only), 3 (recon and assault)
