import { exec, toast } from './kernelsu.js';
import { get_active_iface, get_active_algorithm, getInitcwndInitrwndValue, get_wifi_calling_state, getModuleActiveState, getCakeStatus } from './common.js';
import router_state from './router.js';

export async function updateModuleStatus () {
	var module_status = "Loading Module Status...⌛";
	var active_iface = "None";
	var active_iface_type = "Unknown ⁉️";
	var active_algorithm = "Unknown ⁉️";
	var wifi_calling_state = "Unknown ⁉️";
	var active_InitcwndInitrwndValue = [];
	var cake_status = "Unknown ⁉️";
	
	try
	{
		module_status = (await getModuleActiveState()) == true ? "Enabled ✅" : "Disabled ❌";
		active_iface = await get_active_iface();
		active_iface = active_iface ? active_iface : "None";
		active_iface_type = active_iface.match("rmnet") || active_iface.match("ccmni") ? "Cellular 📶" : active_iface.startsWith("wlan") || active_iface.startsWith("tun") ? "Wi-Fi 🛜" : "Unknown ⁉️";
		active_algorithm = await get_active_algorithm();
		active_InitcwndInitrwndValue = await getInitcwndInitrwndValue();
		
		if(active_iface_type == "Wi-Fi 🛜")
		{
			wifi_calling_state = await get_wifi_calling_state() ? "Active " : "Inactive ";
		}
		
		// Get CAKE status
		try {
			const cakeResponse = await getCakeStatus();
			if (cakeResponse.success) {
				cake_status = cakeResponse.data.status.cake_active ? "Active ✅" : "Inactive ❌";
			} else {
				cake_status = "Error ⁉️";
			}
		} catch (cakeError) {
			console.error('Error fetching CAKE status: ', cakeError);
			cake_status = "Error ⁉️";
		}
		
	} catch (error) {
		console.error('Error updating status: ', error);
		addLog('Error updating status.');
		toast("Error updating status.");
	} finally {
		router_state.homePageParams.module_status = module_status;
		router_state.homePageParams.active_iface_type = active_iface_type;
		router_state.homePageParams.active_iface = active_iface;
		router_state.homePageParams.active_algorithm = active_algorithm;
		router_state.homePageParams.active_InitcwndInitrwndValue = active_InitcwndInitrwndValue;
		router_state.homePageParams.wifi_calling_state = wifi_calling_state;
		router_state.homePageParams.cake_status = cake_status;
	}
}

export function updateHomeUI () {
	if (router_state.isInitializing == false) {
		document.getElementById('module_status_value').textContent = router_state.homePageParams.module_status;
		if(router_state.homePageParams.module_status == "Enabled ✅")
		{
			const ifaceTypeDiv = document.getElementById('active_iface_type_div');
			const ifaceValDiv = document.getElementById('active_iface_div');
			const tcpCongValDiv = document.getElementById('tcp_cong_div');
			const cakeStatusDiv = document.getElementById('cake_status_div');
			
			// Update basic network info
			document.getElementById('active_iface_type_value').textContent = router_state.homePageParams.active_iface_type;
			document.getElementById('active_iface_value').textContent = router_state.homePageParams.active_iface;
			document.getElementById('tcp_cong_value').textContent = router_state.homePageParams.active_algorithm;
			
			// Update CAKE status
			if (cakeStatusDiv) {
				document.getElementById('cake_status_value').textContent = router_state.homePageParams.cake_status;
			}
			
			// Show/hide basic info sections
			if (ifaceTypeDiv?.classList.contains('hidden'))
					ifaceTypeDiv.classList.remove('hidden');
			
			if (ifaceValDiv?.classList.contains('hidden'))
					ifaceValDiv.classList.remove('hidden');
			
			if (tcpCongValDiv?.classList.contains('hidden'))
					tcpCongValDiv.classList.remove('hidden');
			
			// Show/hide CAKE status section
			if (cakeStatusDiv) {
				if (cakeStatusDiv?.classList.contains('hidden'))
					cakeStatusDiv.classList.remove('hidden');
			}
			
			// WiFi Calling section
			const wifiCallingDiv = document.getElementById('wifi_calling_value_div');
			const wifiCallingSpan = document.getElementById('wifi_calling_value');
			
			if(router_state.homePageParams.active_iface_type == "Wi-Fi 🛜")
			{
				if (wifiCallingDiv?.classList.contains('hidden'))
					wifiCallingDiv.classList.remove('hidden');
				
				wifiCallingSpan.textContent = router_state.homePageParams.wifi_calling_state;
			}
			else
			{
				if (wifiCallingDiv && !wifiCallingDiv.classList.contains('hidden'))
					wifiCallingDiv.classList.add('hidden');
				if (wifiCallingSpan)
					wifiCallingSpan.textContent = "Unknown ⁉️";
			}
			
			// Initcwnd/Initrwnd section
			const initcwndDiv = document.getElementById('initcwnd_value_div');
			const initrwndDiv = document.getElementById('initrwnd_value_div');
			const initcwndSpan = document.getElementById('initcwnd_value');
			const initrwndSpan = document.getElementById('initrwnd_value');
			
			const values = router_state.homePageParams.active_InitcwndInitrwndValue;
			const isLoading = values.length < 2 && router_state.settingsPageParams.initcwndInitrwnd;
			
			if(values.length == 2 || isLoading)
			{
				if (initcwndDiv?.classList.contains('hidden'))
					initcwndDiv.classList.remove('hidden');
				
				if (initrwndDiv?.classList.contains('hidden'))
					initrwndDiv.classList.remove('hidden');
				
				if (initcwndSpan)
					initcwndSpan.textContent = values.length == 2 ? values[0] : "Loading initcwnd value...";
				if (initrwndSpan)
					initrwndSpan.textContent = values.length == 2 ? values[1] : "Loading initrwnd value...";
			}
			else
			{
				// No data and not loading → hide the section
				if (initcwndDiv && !initcwndDiv.classList.contains('hidden'))
					initcwndDiv.classList.add('hidden');
				
				if (initrwndDiv && !initrwndDiv.classList.contains('hidden'))
					initrwndDiv.classList.add('hidden');
			}
		} else {
			// Module is disabled, hide all detailed sections
			this.hideDetailedSections();
		}
	}
}

// Helper function to hide detailed sections when module is disabled
function hideDetailedSections() {
	const sectionsToHide = [
		'active_iface_type_div',
		'active_iface_div', 
		'tcp_cong_div',
		'wifi_calling_value_div',
		'initcwnd_value_div',
		'initrwnd_value_div',
		'cake_status_div'
	];
	
	sectionsToHide.forEach(sectionId => {
		const element = document.getElementById(sectionId);
		if (element && !element.classList.contains('hidden')) {
			element.classList.add('hidden');
		}
	});
}

export async function initHome() {
	router_state.isInitializing = false;
	
	// Add CAKE status section to home page if it doesn't exist
	setTimeout(() => {
		const statusContainer = document.querySelector('.status-container');
		if (statusContainer && !document.getElementById('cake_status_div')) {
			// Insert CAKE status after TCP congestion control
			const tcpCongDiv = document.getElementById('tcp_cong_div');
			if (tcpCongDiv) {
				const cakeHtml = `
					<div id="cake_status_div" class="status-item hidden">
						<span class="status-label">CAKE Status:</span>
						<span id="cake_status_value" class="status-value">Loading...⌛</span>
					</div>
				`;
				tcpCongDiv.insertAdjacentHTML('afterend', cakeHtml);
			}
		}
	}, 100);
	
	updateHomeUI();
}

// Function to refresh CAKE status specifically
export async function refreshCakeStatus() {
	try {
		const cakeResponse = await getCakeStatus();
		if (cakeResponse.success) {
			const cakeStatus = cakeResponse.data.status.cake_active ? "Active ✅" : "Inactive ❌";
			router_state.homePageParams.cake_status = cakeStatus;
			
			// Update UI immediately
			const cakeStatusElement = document.getElementById('cake_status_value');
			if (cakeStatusElement) {
				cakeStatusElement.textContent = cakeStatus;
			}
			
			return cakeStatus;
		}
	} catch (error) {
		console.error('Error refreshing CAKE status:', error);
		router_state.homePageParams.cake_status = "Error ⁉️";
		
		const cakeStatusElement = document.getElementById('cake_status_value');
		if (cakeStatusElement) {
			cakeStatusElement.textContent = "Error ⁉️";
		}
	}
	return null;
}
