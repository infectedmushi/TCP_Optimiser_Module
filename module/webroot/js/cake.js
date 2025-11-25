// js/cake.js
import { getCakeStatus, getCakePresets, applyCakeOptimization, addLog } from './common.js';

class CakeOptimizerUI {
    constructor() {
        this.isLoading = false;
        this.init();
    }

    init() {
        this.bindEvents();
        this.loadStatus();
        addLog('CAKE Optimizer UI initialized');
    }

    bindEvents() {
        // Refresh status button
        const refreshBtn = document.getElementById('refresh-status');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.loadStatus();
            });
        }

        // Apply optimization button
        const applyBtn = document.getElementById('apply-optimization');
        if (applyBtn) {
            applyBtn.addEventListener('click', () => {
                this.applyOptimization();
            });
        }

        // Enter key support for form
        const ccSelect = document.getElementById('cc-algorithm');
        const cakeSelect = document.getElementById('cake-preset');
        
        if (ccSelect && cakeSelect) {
            const handleEnter = (e) => {
                if (e.key === 'Enter') {
                    this.applyOptimization();
                }
            };
            ccSelect.addEventListener('keypress', handleEnter);
            cakeSelect.addEventListener('keypress', handleEnter);
        }
    }

    async loadStatus() {
        if (this.isLoading) return;
        
        this.setLoading(true);
        try {
            const response = await getCakeStatus();
            if (response.success) {
                this.updateStatusUI(response.data.status);
                this.updatePresetsDropdown(response.data.presets);
                addLog('CAKE status loaded successfully');
            } else {
                this.showNotification('Failed to load status: ' + response.error, 'error');
                addLog('Failed to load CAKE status: ' + response.error);
            }
        } catch (error) {
            this.showNotification('Error loading status: ' + error.message, 'error');
            addLog('Error loading CAKE status: ' + error.message);
            console.error('Status load error:', error);
        } finally {
            this.setLoading(false);
        }
    }

    updateStatusUI(status) {
        // Update interface status
        this.updateElement('interface-status', status.interface || 'Unknown');
        
        // Update CAKE available status
        const cakeAvailable = status.cake_available ? 'Available' : 'Not Available';
        const cakeAvailableClass = status.cake_available ? 'active' : 'inactive';
        this.updateElement('cake-available-status', cakeAvailable, cakeAvailableClass);
        
        // Update CAKE active status
        const cakeActive = status.cake_active ? 'Active' : 'Inactive';
        const cakeActiveClass = status.cake_active ? 'active' : 'inactive';
        this.updateElement('cake-active-status', cakeActive, cakeActiveClass);
        
        // Update congestion control
        this.updateElement('cc-status', status.congestion_control || 'Unknown');
        
        // Update CC algorithm dropdown to match current
        const ccSelect = document.getElementById('cc-algorithm');
        if (ccSelect && status.congestion_control) {
            ccSelect.value = status.congestion_control;
        }
    }

    updatePresetsDropdown(presets) {
        if (!presets) return;

        // Update CC algorithm dropdown with available options
        const ccSelect = document.getElementById('cc-algorithm');
        if (ccSelect && presets.cc_algorithms) {
            const currentValue = ccSelect.value;
            ccSelect.innerHTML = '';
            
            presets.cc_algorithms.forEach(algo => {
                const option = document.createElement('option');
                option.value = algo;
                option.textContent = algo.toUpperCase();
                ccSelect.appendChild(option);
            });
            
            // Restore previous selection if still available
            if (presets.cc_algorithms.includes(currentValue)) {
                ccSelect.value = currentValue;
            }
        }

        // Update CAKE preset dropdown
        const cakeSelect = document.getElementById('cake-preset');
        if (cakeSelect && presets.cake_presets) {
            const currentValue = cakeSelect.value;
            cakeSelect.innerHTML = '';
            
            Object.entries(presets.cake_presets).forEach(([key, preset]) => {
                const option = document.createElement('option');
                option.value = key;
                option.textContent = preset.description;
                cakeSelect.appendChild(option);
            });
            
            // Restore previous selection if still available
            if (presets.cake_presets[currentValue]) {
                cakeSelect.value = currentValue;
            }
        }
    }

    async applyOptimization() {
        if (this.isLoading) return;

        const ccAlgorithm = document.getElementById('cc-algorithm').value;
        const cakePreset = document.getElementById('cake-preset').value;

        if (!ccAlgorithm || !cakePreset) {
            this.showNotification('Please select both congestion control and CAKE preset', 'error');
            return;
        }

        this.setLoading(true);
        try {
            const response = await applyCakeOptimization(ccAlgorithm, cakePreset);

            if (response.success) {
                this.showNotification('Optimization applied successfully!', 'success');
                addLog(`CAKE optimization applied: ${ccAlgorithm} + ${cakePreset}`);
                
                // Show detailed messages if available
                if (response.data && response.data.messages) {
                    response.data.messages.forEach(msg => {
                        setTimeout(() => {
                            this.showNotification(msg, 'info');
                            addLog('CAKE: ' + msg);
                        }, 500);
                    });
                }
                
                // Reload status after a delay to show changes
                setTimeout(() => this.loadStatus(), 1500);
            } else {
                this.showNotification('Optimization failed: ' + (response.error || 'Unknown error'), 'error');
                addLog('CAKE optimization failed: ' + (response.error || 'Unknown error'));
            }
        } catch (error) {
            this.showNotification('Error applying optimization: ' + error.message, 'error');
            addLog('CAKE optimization error: ' + error.message);
            console.error('Optimization error:', error);
        } finally {
            this.setLoading(false);
        }
    }

    updateElement(elementId, text, className = '') {
        const element = document.getElementById(elementId);
        if (element) {
            element.textContent = text;
            if (className) {
                element.className = `status-value ${className}`;
            }
        }
    }

    setLoading(loading) {
        this.isLoading = loading;
        const applyBtn = document.getElementById('apply-optimization');
        const refreshBtn = document.getElementById('refresh-status');
        
        if (applyBtn) {
            applyBtn.disabled = loading;
            applyBtn.textContent = loading ? 'Applying...' : 'Apply Optimization';
        }
        
        if (refreshBtn) {
            refreshBtn.disabled = loading;
            refreshBtn.textContent = loading ? 'Refreshing...' : '🔄 Refresh Status';
        }
        
        // Add/remove loading class to page
        const page = document.getElementById('cake-page');
        if (page) {
            page.classList.toggle('loading', loading);
        }
    }

    showNotification(message, type = 'info') {
        // Remove existing notifications
        const existingNotifications = document.querySelectorAll('.notification');
        existingNotifications.forEach(notification => notification.remove());

        // Create new notification
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;

        // Add to body
        document.body.appendChild(notification);

        // Remove after 5 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 5000);
    }
}

export { CakeOptimizerUI };
