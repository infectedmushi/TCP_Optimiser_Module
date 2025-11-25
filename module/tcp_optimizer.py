# tcp_optimizer.py
import subprocess
import re
import os
import time
import json
from typing import Dict, List, Optional

class CakeOptimizer:
    """CAKE Queuing Discipline Optimizer"""
    
    def __init__(self, interface: str = None):
        self.interface = interface or self.detect_primary_interface()
        self.supported_features = self.check_cake_features()
    
    def detect_primary_interface(self) -> str:
        """Detect the primary network interface"""
        try:
            result = subprocess.run(['ip', 'route', 'show', 'default'], 
                                  capture_output=True, text=True, check=True)
            match = re.search(r'dev\s+(\w+)', result.stdout)
            return match.group(1) if match else 'eth0'
        except:
            return 'eth0'
    
    def check_cake_features(self) -> Dict[str, bool]:
        """Check which CAKE features are available"""
        features = {'cake_available': False}
        try:
            result = subprocess.run(['tc', 'qdisc', 'help'], capture_output=True, text=True)
            features['cake_available'] = 'cake' in result.stdout
        except:
            pass
        return features
    
    def remove_existing_qdisc(self) -> bool:
        """Remove existing qdisc from interface"""
        try:
            subprocess.run(['tc', 'qdisc', 'del', 'dev', self.interface, 'root'], 
                         capture_output=True, stderr=subprocess.DEVNULL)
            subprocess.run(['tc', 'qdisc', 'del', 'dev', self.interface, 'ingress'], 
                         capture_output=True, stderr=subprocess.DEVNULL)
            time.sleep(0.2)
            return True
        except:
            return False
    
    def apply_cake_configuration(self, config: Dict) -> bool:
        """Apply CAKE configuration"""
        try:
            if not self.remove_existing_qdisc():
                return False
            
            cake_cmd = ['tc', 'qdisc', 'add', 'dev', self.interface, 'root', 'cake']
            
            if config.get('bandwidth'):
                cake_cmd.extend(['bandwidth', config['bandwidth']])
            else:
                cake_cmd.extend(['bandwidth', '1gbit'])
            
            options = config.get('options', [])
            for option in options:
                cake_cmd.append(option)
            
            cake_cmd.extend(['ingress', 'wash'])
            
            if config.get('fairness', True):
                cake_cmd.append('dual-srchost')
            
            result = subprocess.run(cake_cmd, check=True, capture_output=True, text=True)
            return result.returncode == 0
            
        except subprocess.CalledProcessError as e:
            return False
    
    def get_optimized_presets(self) -> Dict[str, Dict]:
        """Get CAKE presets for different scenarios"""
        return {
            'general': {'description': 'General purpose optimization', 'bandwidth': '1gbit', 'options': ['dual-srchost']},
            'gaming': {'description': 'Low latency for gaming', 'bandwidth': '100mbit', 'options': ['rtt', '50ms', 'dual-dsthost']},
            'streaming': {'description': 'Stable streaming performance', 'bandwidth': '500mbit', 'options': ['memlimit', '64Mb']},
            'wireless': {'description': 'Wireless network optimization', 'bandwidth': '100mbit', 'options': ['wireless', 'dual-dsthost']},
            'high_latency': {'description': 'High latency/satellite links', 'bandwidth': '50mbit', 'options': ['rtt', '500ms', 'raw']}
        }
    
    def apply_preset(self, preset_name: str) -> bool:
        """Apply a CAKE preset"""
        presets = self.get_optimized_presets()
        if preset_name not in presets:
            return False
        return self.apply_cake_configuration(presets[preset_name])
    
    def get_status(self) -> Dict:
        """Get current CAKE status"""
        status = {
            'interface': self.interface,
            'cake_available': self.supported_features['cake_available'],
            'active': False
        }
        try:
            result = subprocess.run(['tc', 'qdisc', 'show', 'dev', self.interface],
                                  capture_output=True, text=True)
            status['active'] = 'cake' in result.stdout
        except:
            pass
        return status

class TCPOptimizer:
    """Enhanced TCP Optimizer with CAKE support"""
    
    def __init__(self, enable_cake: bool = True):
        self.cake_optimizer = CakeOptimizer()
        self.enable_cake = enable_cake and self.cake_optimizer.supported_features['cake_available']
        self.sysctl_path = "/proc/sys/net/ipv4"
        self.available_cc = self.get_available_congestion_control()
    
    def get_available_congestion_control(self) -> list:
        """Get available TCP congestion control algorithms"""
        try:
            with open('/proc/sys/net/ipv4/tcp_available_congestion_control', 'r') as f:
                return f.read().strip().split()
        except:
            return ['cubic']
    
    def set_congestion_control(self, algorithm: str) -> bool:
        """Set TCP congestion control algorithm"""
        if algorithm not in self.available_cc:
            algorithm = 'cubic'
        try:
            with open('/proc/sys/net/ipv4/tcp_congestion_control', 'w') as f:
                f.write(algorithm)
            return True
        except:
            return False
    
    def optimize_comprehensive(self, cc_algorithm: str = "bbr", cake_preset: str = "general") -> Dict:
        """Comprehensive optimization with CAKE"""
        result = {'success': True, 'messages': []}
        
        # Apply CAKE first
        if self.enable_cake:
            if self.cake_optimizer.apply_preset(cake_preset):
                result['messages'].append('CAKE applied successfully')
            else:
                result['messages'].append('CAKE application failed')
                result['success'] = False
        
        # Set congestion control
        if self.set_congestion_control(cc_algorithm):
            result['messages'].append(f'Congestion control set to {cc_algorithm}')
        else:
            result['messages'].append('Failed to set congestion control')
            result['success'] = False
        
        return result
    
    def get_status(self) -> Dict:
        """Get current optimization status"""
        status = {
            'congestion_control': 'unknown',
            'cake_available': self.enable_cake,
            'cake_active': False,
            'available_cc': self.available_cc
        }
        
        try:
            with open('/proc/sys/net/ipv4/tcp_congestion_control', 'r') as f:
                status['congestion_control'] = f.read().strip()
        except:
            pass
        
        cake_status = self.cake_optimizer.get_status()
        status['cake_active'] = cake_status['active']
        status['interface'] = cake_status['interface']
        
        return status
    
    def get_presets(self) -> Dict:
        """Get all available presets"""
        return {
            'cake_presets': self.cake_optimizer.get_optimized_presets(),
            'cc_algorithms': self.available_cc
        }

# Web API functions
def api_optimize(data):
    """API endpoint for optimization"""
    try:
        optimizer = TCPOptimizer()
        cc_algorithm = data.get('cc_algorithm', 'bbr')
        cake_preset = data.get('cake_preset', 'general')
        
        result = optimizer.optimize_comprehensive(cc_algorithm, cake_preset)
        return {'success': True, 'data': result}
    except Exception as e:
        return {'success': False, 'error': str(e)}

def api_status():
    """API endpoint for status"""
    try:
        optimizer = TCPOptimizer()
        status = optimizer.get_status()
        presets = optimizer.get_presets()
        return {'success': True, 'data': {'status': status, 'presets': presets}}
    except Exception as e:
        return {'success': False, 'error': str(e)}

def api_presets():
    """API endpoint for presets"""
    try:
        optimizer = TCPOptimizer()
        presets = optimizer.get_presets()
        return {'success': True, 'data': presets}
    except Exception as e:
        return {'success': False, 'error': str(e)}
