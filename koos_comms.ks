@lazyglobal off.

function comms_cpu_reboot {
	parameter cpu.
	cpu:DEACTIVATE().
	wait 1.
	cpu:ACTIVATE().
}
	