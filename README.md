A `Desynced`(the game) mod
------
the mod added a command.
------

This command checks for all currently missing orders (whether for buildings or production) and schedules them automatically, including any required sub-components (recursive).

Note: This only scans the current state of your base. If a component is already being produced, the script assumes it belongs to a different plan and will ignore it. Therefore, if you run this command twice in a row, it will queue a duplicate set of whatever is currently missing.

Logging: If you want to see the execution details, you can add -log to the game’s Launch Options in Steam to display the log.

Examples:

Simple Production: If you are missing 20 Iron Plates and have 3 idle Fabricators, running this command will automatically distribute the workload (e.g., 8+6+6) across those 3 machines.

Recursive Crafting: If you are missing one Laser Turret, and the Small Turret required to build it is also missing, the command will automatically assign one Fabricator to build the Small Turret and another to build the Laser Turret (provided you have idle Fabricators available). 

-----

Shared for free. Please don't expect custom changes from me.


