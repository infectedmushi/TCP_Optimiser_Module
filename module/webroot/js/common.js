import { exec, toast, moduleInfo } from './kernelsu.js';
import router_state from './router.js';
import { addLog } from './logs.js';

async function readModuleProp () {
	try {
		const { stdout: details } = await exec(`cat /data/adb/modules/tcp_optimiser/module.prop`);
		const lines = details.trim().split('\n').filter(line => line);
		
		// Convert lines to object
		let moduleInfo = lines.reduce((acc, line) => {
		  const [key, ...rest] = line.split('=');
		  const value = rest.join('=').trim(); // handle values with '=' in them
		  acc[key.trim()] = value;
		  return acc;
		}, {});
		
		moduleInfo["moduleDir"] = `/data/adb/modules/${moduleInfo.id}`;
		return moduleInfo;
	} catch (error) {
		console.error('Error reading module.prop:', error);
		// Return a fallback object if reading fails
		return {
			id: 'tcp_optimiser',
			name: 'TCP Optimiser with CAKE',
			version: '2.5',
			versionCode: '25',
			author: 'deepongi',
			description: 'TCP Optimisation module with CAKE support',
			moduleDir: '/data/adb/modules/tcp_optimiser'
		};
	}
}

export async function updateModuleInformation () {
	try {
		// First try to get module info from KernelSU
		let moduleInfoData;
		try {
			moduleInfoData = JSON.parse(moduleInfo());
		} catch (e) {
			console.log('KernelSU moduleInfo not available, using fallback');
			moduleInfoData = {};
		}
		
		// Always read from module.prop for accurate version info
		const moduleProp = await readModuleProp();
		
		// Merge the data, preferring module.prop for version info
		router_state.moduleInformation = {
			...moduleInfoData,
			...moduleProp
		};
		
	} catch (error) {
		console.error('Error updating module info:', error);
		// Set fallback information
		router_state.moduleInformation = {
			id: 'tcp_optimiser',
			name: 'TCP Optimiser with CAKE',
			version: '2.5',
			versionCode: '25',
			author: 'deepongi',
			description: 'TCP Optimisation module with CAKE support',
			moduleDir: '/data/adb/modules/tcp_optimiser'
		};
	}
	
	// Update the version display
	updateVersionDisplay();
}

function updateVersionDisplay() {
	const versionElement = document.getElementById('version');
	if (!versionElement) return;
	
	try {
		const info = router_state.moduleInformation;
		let versionStr = '';
		
		if (info.version) {
			versionStr = `v${info.version}`;
		}
		
		if (info.versionCode) {
			versionStr += versionStr ? ` (${info.versionCode})` : info.versionCode;
		}
		
		// If we still don't have version info, show fallback
		if (!versionStr) {
			versionStr = 'v2.5 (25)'; // Hardcoded fallback
		}
		
		versionElement.textContent = versionStr;
		
	} catch (error) {
		console.error('Error updating version display:', error);
		versionElement.textContent = 'v2.5 (25)'; // Hardcoded fallback
	}
}

export async function getModuleActiveState () {
	try {
		const { stdout: file_exists } = await exec(`ls "/dev/.tcp_module_log_cleared"`);
		return file_exists != "" ? true: false;
	}catch (error) {
		console.error('Error updating module state:', error);
		toast("Error fetching module state.");
	}
}

export async function get_active_iface () {
	try {
		const { stdout: active_iface } = await exec(`ip route get 192.0.2.1 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}'`);
		return active_iface.trim()
	} catch (error) {
		console.error('Error fetching active interface: ', error);
		addLog('Error fetching active interface.');
		toast("Error fetching active interface.");
		return "error"
	}
};

export async function get_active_algorithm () {
	try {
		const { stdout: active_algo } = await exec(`cat /proc/sys/net/ipv4/tcp_congestion_control`);
		return active_algo.trim()
	} catch (error) {
		console.error('Error fetching active interface: ', error);
		addLog('Error fetching active interface.');
		toast("Error fetching active interface.");
		return "error"
	}
};

export async function getInitcwndInitrwndValue () {
	try {
		const { stdout: initcwndInitrwndValueOutput } = await exec(`ip route show | grep -o 'initcwnd [0-9]* initrwnd [0-9]*'`);
		const initcwndInitrwndValues = initcwndInitrwndValueOutput.trim().split(/\s+/).filter((_, i) => i % 2 === 1);
		return initcwndInitrwndValues;
	} catch (error) {
		console.error('Error fetching active interface: ', error);
		addLog('Error fetching active interface.');
		toast("Error fetching active interface.");
		return [];
	}
};

export async function get_wifi_calling_state() {
  const DUMPSYS_TMP_FILE = `${router_state.moduleInformation.moduleDir}/dumpsys.tmp`;

  try {
    // Run dumpsys and save to file
    await exec(`dumpsys activity service SystemUIService > "${DUMPSYS_TMP_FILE}" 2>/dev/null`);

    // Check for VoWiFi pattern
     const { stdout: returnCode } = await exec(`
      grep -qE "slot=\'vowifi\'.*visible user=.*" "${DUMPSYS_TMP_FILE}" && echo $?`
    );

    // Clean up temp file
    await exec(`rm -f "${DUMPSYS_TMP_FILE}"`);

    // Return true if match found (exit code 0)
    return returnCode.trim() === '0';
  } catch (error) {
    console.error('Error checking VoWiFi state:', error);
	addLog('Error checking VoWiFi state.');
    return false;
  }
}

export async function fetchIsConfigFile (file_name) {
	try {
		const { stdout: output } = await exec(`[ -f "${router_state.moduleInformation.moduleDir}/${file_name}" ] && echo "exist" || echo ""`);
		return output == "exist";
	} catch (error) {
		console.error('Error fetching kill connections status: ', error);
		addLog('Error fetching kill connections status.');
		toast("Error fetching kill connections status.");
		return false;
	}
};

// =============================================================================
// CAKE Optimizer API Functions
// =============================================================================

export const cakeApiCall = async (endpoint, data = null) => {
    try {
        const payload = {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                action: endpoint,
                ...(data || {})
            })
        };

        // For now, we'll use direct shell commands since we don't have a Flask server
        // In a real implementation, this would call your backend API
        const response = await executeCakeCommand(endpoint, data);
        return response;
        
    } catch (error) {
        console.error('CAKE API call failed:', error);
        addLog(`CAKE API error: ${error.message}`);
        throw error;
    }
};

// Helper function to execute CAKE-related shell commands
const executeCakeCommand = async (action, data = null) => {
    try {
        switch (action) {
            case 'status':
                return await getCakeStatusCommand();
            case 'presets':
                return await getCakePresetsCommand();
            case 'optimize':
                return await applyCakeOptimizationCommand(data);
            default:
                throw new Error(`Unknown CAKE action: ${action}`);
        }
    } catch (error) {
        console.error('CAKE command execution failed:', error);
        throw error;
    }
};

// Get CAKE status using shell commands
const getCakeStatusCommand = async () => {
    try {
        // Get current congestion control
        const { stdout: cc } = await exec(`cat /proc/sys/net/ipv4/tcp_congestion_control`);
        
        // Get primary interface
        const { stdout: interface } = await exec(`ip route show default | awk '/dev/ {print $5}' | head -1`);
        
        // Check if CAKE is active
        const { stdout: cakeStatus } = await exec(`tc qdisc show dev ${interface.trim()} 2>/dev/null | grep -q cake && echo "active" || echo "inactive"`);
        
        // Check if CAKE is available in kernel
        const { stdout: cakeAvailable } = await exec(`tc qdisc help 2>/dev/null | grep -q cake && echo "true" || echo "false"`);
        
        // Get available congestion control algorithms
        const { stdout: availableCC } = await exec(`cat /proc/sys/net/ipv4/tcp_available_congestion_control`);
        
        return {
            success: true,
            data: {
                status: {
                    congestion_control: cc.trim(),
                    interface: interface.trim(),
                    cake_available: cakeAvailable.trim() === 'true',
                    cake_active: cakeStatus.trim() === 'active'
                },
                presets: {
                    cc_algorithms: availableCC.trim().split(' '),
                    cake_presets: {
                        'general': { description: 'General purpose optimization', bandwidth: '1gbit', options: ['dual-srchost'] },
                        'gaming': { description: 'Low latency for gaming', bandwidth: '100mbit', options: ['rtt', '50ms', 'dual-dsthost'] },
                        'streaming': { description: 'Stable streaming performance', bandwidth: '500mbit', options: ['memlimit', '64Mb'] },
                        'wireless': { description: 'Wireless network optimization', bandwidth: '100mbit', options: ['wireless', 'dual-dsthost'] },
                        'high_latency': { description: 'High latency/satellite links', bandwidth: '50mbit', options: ['rtt', '500ms', 'raw'] }
                    }
                }
            }
        };
    } catch (error) {
        console.error('Error getting CAKE status:', error);
        return {
            success: false,
            error: `Failed to get CAKE status: ${error.message}`
        };
    }
};

// Get CAKE presets
const getCakePresetsCommand = async () => {
    try {
        // Get available congestion control algorithms
        const { stdout: availableCC } = await exec(`cat /proc/sys/net/ipv4/tcp_available_congestion_control`);
        
        return {
            success: true,
            data: {
                cc_algorithms: availableCC.trim().split(' '),
                cake_presets: {
                    'general': { description: 'General purpose optimization', bandwidth: '1gbit', options: ['dual-srchost'] },
                    'gaming': { description: 'Low latency for gaming', bandwidth: '100mbit', options: ['rtt', '50ms', 'dual-dsthost'] },
                    'streaming': { description: 'Stable streaming performance', bandwidth: '500mbit', options: ['memlimit', '64Mb'] },
                    'wireless': { description: 'Wireless network optimization', bandwidth: '100mbit', options: ['wireless', 'dual-dsthost'] },
                    'high_latency': { description: 'High latency/satellite links', bandwidth: '50mbit', options: ['rtt', '500ms', 'raw'] }
                }
            }
        };
    } catch (error) {
        console.error('Error getting CAKE presets:', error);
        return {
            success: false,
            error: `Failed to get CAKE presets: ${error.message}`
        };
    }
};

// Apply CAKE optimization
const applyCakeOptimizationCommand = async (data) => {
    try {
        const { cc_algorithm, cake_preset } = data;
        const messages = [];
        
        // Get primary interface
        const { stdout: interface } = await exec(`ip route show default | awk '/dev/ {print $5}' | head -1`);
        const iface = interface.trim();
        
        // Set congestion control
        try {
            await exec(`echo "${cc_algorithm}" > /proc/sys/net/ipv4/tcp_congestion_control`);
            messages.push(`Congestion control set to ${cc_algorithm}`);
            addLog(`CAKE: Congestion control set to ${cc_algorithm}`);
        } catch (error) {
            messages.push(`Failed to set congestion control to ${cc_algorithm}`);
            addLog(`CAKE: Failed to set CC to ${cc_algorithm}`);
        }
        
        // Apply CAKE configuration based on preset
        if (cake_preset) {
            try {
                // Remove existing qdisc
                await exec(`tc qdisc del dev ${iface} root 2>/dev/null || true`);
                await exec(`tc qdisc del dev ${iface} ingress 2>/dev/null || true`);
                
                // Build CAKE command based on preset
                let cakeCmd = `tc qdisc add dev ${iface} root cake`;
                
                const presets = {
                    'general': { bandwidth: '1gbit', options: ['dual-srchost'] },
                    'gaming': { bandwidth: '100mbit', options: ['rtt', '50ms', 'dual-dsthost'] },
                    'streaming': { bandwidth: '500mbit', options: ['memlimit', '64Mb'] },
                    'wireless': { bandwidth: '100mbit', options: ['wireless', 'dual-dsthost'] },
                    'high_latency': { bandwidth: '50mbit', options: ['rtt', '500ms', 'raw'] }
                };
                
                const preset = presets[cake_preset] || presets.general;
                cakeCmd += ` bandwidth ${preset.bandwidth}`;
                
                preset.options.forEach(opt => {
                    cakeCmd += ` ${opt}`;
                });
                
                // Add best practices
                cakeCmd += ` ingress wash`;
                
                await exec(cakeCmd);
                messages.push(`CAKE ${cake_preset} preset applied successfully`);
                addLog(`CAKE: ${cake_preset} preset applied on ${iface}`);
                
            } catch (error) {
                messages.push(`Failed to apply CAKE ${cake_preset} preset`);
                addLog(`CAKE: Failed to apply ${cake_preset} preset`);
            }
        }
        
        return {
            success: true,
            data: {
                messages: messages
            }
        };
        
    } catch (error) {
        console.error('Error applying CAKE optimization:', error);
        return {
            success: false,
            error: `Failed to apply CAKE optimization: ${error.message}`
        };
    }
};

// Convenience functions for CAKE operations
export const getCakeStatus = async () => {
    return await cakeApiCall('status');
};

export const getCakePresets = async () => {
    return await cakeApiCall('presets');
};

export const applyCakeOptimization = async (ccAlgorithm, cakePreset) => {
    return await cakeApiCall('optimize', {
        cc_algorithm: ccAlgorithm,
        cake_preset: cakePreset
    });
};

// Additional CAKE utility functions
export const checkCakeSupport = async () => {
    try {
        const { stdout: support } = await exec(`tc qdisc help 2>/dev/null | grep -q cake && echo "supported" || echo "not_supported"`);
        return support.trim() === 'supported';
    } catch (error) {
        console.error('Error checking CAKE support:', error);
        return false;
    }
};

export const removeCakeQdisc = async (interface = null) => {
    try {
        if (!interface) {
            const { stdout: iface } = await exec(`ip route show default | awk '/dev/ {print $5}' | head -1`);
            interface = iface.trim();
        }
        
        await exec(`tc qdisc del dev ${interface} root 2>/dev/null || true`);
        await exec(`tc qdisc del dev ${interface} ingress 2>/dev/null || true`);
        
        addLog(`CAKE: Removed qdisc from ${interface}`);
        return true;
    } catch (error) {
        console.error('Error removing CAKE qdisc:', error);
        addLog(`CAKE: Failed to remove qdisc from ${interface}`);
        return false;
    }
};

export function formatLocalDateTime(date = new Date()) {
  const pad = (n) => n.toString().padStart(2, '0');

  const yyyy = date.getFullYear();
  const mm   = pad(date.getMonth() + 1);
  const dd   = pad(date.getDate());

  const hh   = pad(date.getHours());
  const min  = pad(date.getMinutes());
  const ss   = pad(date.getSeconds());

  return `${yyyy}-${mm}-${dd} ${hh}:${min}:${ss}`;
}

// Initialize version on load
document.addEventListener('DOMContentLoaded', async () => {
	// Update module information immediately
	await updateModuleInformation();
	
	// Set up link handlers
	document.querySelectorAll('.link').forEach(async (link) => {
		link.addEventListener('click', async (event) => {
			event.preventDefault();
			const url = event.currentTarget.getAttribute('data-value');
			await exec(`am start -a android.intent.action.VIEW -d "${url}"`);
		});
	});
});
