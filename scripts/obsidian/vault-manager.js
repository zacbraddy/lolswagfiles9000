#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const OBSIDIAN_CONFIG_DIR = path.join(os.homedir(), '.obsidian');
const MANAGED_VAULTS_FILE = path.join(OBSIDIAN_CONFIG_DIR, 'managed-vaults.txt');
const OBSIDIAN_CONFIG_FILE = path.join(OBSIDIAN_CONFIG_DIR, 'config');

function getDotfilesPath() {
  try {
    if (fs.existsSync(OBSIDIAN_CONFIG_FILE)) {
      const config = fs.readFileSync(OBSIDIAN_CONFIG_FILE, 'utf8');
      const match = config.match(/^DOTFILES_PATH=(.+)$/m);
      if (match) {
        return path.join(match[1], 'obsidian');
      }
    }
  } catch (error) {
    console.error('Error reading obsidian config:', error.message);
  }
  
  // Fallback to relative path (for development/testing)
  return path.resolve(__dirname, '../../obsidian');
}

const DOTFILES_OBSIDIAN_DIR = getDotfilesPath();

// Files and directories to sync
const CONFIG_ITEMS = [
  'app.json',
  'appearance.json',
  'backlink.json',
  'core-plugins.json',
  'community-plugins.json',
  'workspace.json',
  'vimrc',
  'plugins',
  'themes',
  'icons'
];

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function ensureManagedVaultsFile() {
  const obsidianDir = path.dirname(MANAGED_VAULTS_FILE);
  ensureDir(obsidianDir);
  
  if (!fs.existsSync(MANAGED_VAULTS_FILE)) {
    // Create file with dotfiles path as first entry
    fs.writeFileSync(MANAGED_VAULTS_FILE, `DOTFILES:${DOTFILES_OBSIDIAN_DIR}\n`);
    return;
  }

  // Check if current dotfiles path exists in file
  const content = fs.readFileSync(MANAGED_VAULTS_FILE, 'utf8');
  const lines = content.split('\n').filter(line => line.trim());
  
  // Check if current dotfiles path is already present
  const currentDotfilesEntry = `DOTFILES:${DOTFILES_OBSIDIAN_DIR}`;
  const hasCurrentPath = lines.some(line => line === currentDotfilesEntry);
  
  if (!hasCurrentPath) {
    // Remove any old DOTFILES entries and add current one at the beginning
    const nonDotfilesLines = lines.filter(line => !line.startsWith('DOTFILES:'));
    const updatedLines = [currentDotfilesEntry, ...nonDotfilesLines];
    fs.writeFileSync(MANAGED_VAULTS_FILE, updatedLines.join('\n') + '\n');
  }
}

function getManagedVaults() {
  ensureManagedVaultsFile();
  const content = fs.readFileSync(MANAGED_VAULTS_FILE, 'utf8');
  return content.split('\n')
    .filter(line => line.trim())
    .map(line => {
      if (line.startsWith('DOTFILES:')) {
        return { type: 'dotfiles', path: line.substring(9) };
      }
      return { type: 'vault', path: line };
    });
}

function addManagedVault(vaultPath) {
  const vaults = getManagedVaults();
  const exists = vaults.some(v => v.path === vaultPath && v.type === 'vault');
  
  if (!exists) {
    fs.appendFileSync(MANAGED_VAULTS_FILE, `${vaultPath}\n`);
    return true;
  }
  return false;
}

// Files to include when syncing plugins (configuration, not runtime data)
const PLUGIN_INCLUDE_FILES = [
  'main.js',              // Plugin executable
  'manifest.json',        // Plugin metadata
  'styles.css',           // Plugin styles
  'data.json',            // Plugin configuration
  'settings.json',        // Plugin settings
  'config.json',          // Plugin config
  '*.json',               // Other JSON config files
  '*.css',                // Style files
  '*.js',                 // JavaScript files
  '*.md',                 // Documentation
  '*.sh',                 // Shell scripts (like obsidian_askpass.sh)
];

// Patterns to always exclude (security and runtime data)
const PLUGIN_EXCLUDE_PATTERNS = [
  '*.pem',                // SSL certificates
  '*.key',                // Private keys
  '*.crt',                // Certificates
  '*.p12',                // Certificate bundles
  '*.log',                // Log files
  '*.tmp',                // Temporary files
  '*-cache*',             // Cache files
  '*cache*',              // Cache directories/files
  'node_modules',         // Dependencies
  '.git',                 // Git directories
  'histories.json',       // Runtime histories
  '*-history*',           // History files
  '*history*',            // History files
  '*-positions*',         // Position tracking
  '*positions*',          // Position tracking
  'recent-*',             // Recent files data
  'workspace-*',          // Workspace snapshots
];

function matchesPattern(filename, patterns) {
  return patterns.some(pattern => {
    if (pattern.includes('*')) {
      const regex = new RegExp('^' + pattern.replace(/\*/g, '.*') + '$');
      return regex.test(filename);
    }
    return filename === pattern;
  });
}

function shouldExcludeFile(filename, isPlugin = false) {
  if (!isPlugin) return false;
  
  // Always exclude security/runtime patterns
  if (matchesPattern(filename, PLUGIN_EXCLUDE_PATTERNS)) {
    return true;
  }
  
  // For JSON files, be more selective - exclude known runtime data patterns
  if (filename.endsWith('.json')) {
    const runtimeDataPatterns = [
      'histories', 'history', 'cache', 'recent', 'positions', 
      'cursor', 'workspace', 'session', 'state', 'temp'
    ];
    
    const baseName = filename.toLowerCase().replace('.json', '');
    if (runtimeDataPatterns.some(pattern => baseName.includes(pattern))) {
      return true;
    }
  }
  
  return false;
}

function copyDir(source, target, isPlugin = false) {
  ensureDir(target);

  const entries = fs.readdirSync(source, { withFileTypes: true });

  for (const entry of entries) {
    const sourcePath = path.join(source, entry.name);
    const targetPath = path.join(target, entry.name);

    // Skip excluded files for plugins
    if (shouldExcludeFile(entry.name, isPlugin)) {
      console.log(`⏭️  Skipped excluded file: ${entry.name}`);
      continue;
    }

    if (entry.isDirectory()) {
      copyDir(sourcePath, targetPath, isPlugin);
    } else {
      fs.copyFileSync(sourcePath, targetPath);
    }
  }
}

function syncFromDotfilesToVault(vaultPath) {
  console.log(`📤 Syncing dotfiles to vault: ${vaultPath}`);
  
  const obsidianDir = path.join(vaultPath, '.obsidian');
  ensureDir(obsidianDir);

  CONFIG_ITEMS.forEach(item => {
    const sourcePath = path.join(DOTFILES_OBSIDIAN_DIR, item);
    const targetPath = path.join(obsidianDir, item);

    if (fs.existsSync(sourcePath)) {
      const stats = fs.statSync(sourcePath);

      if (stats.isDirectory()) {
        const isPluginDir = item === 'plugins';
        copyDir(sourcePath, targetPath, isPluginDir);
        console.log(`✅ Synced directory: ${item}`);
      } else {
        const sourceContent = fs.readFileSync(sourcePath);
        fs.writeFileSync(targetPath, sourceContent);
        console.log(`✅ Synced file: ${item}`);
      }
    } else {
      console.log(`⚠️  Source item not found: ${item}`);
    }
  });
}

function syncFromVaultToDotfiles(vaultPath) {
  console.log(`📥 Syncing vault to dotfiles: ${vaultPath}`);
  
  const obsidianDir = path.join(vaultPath, '.obsidian');
  
  if (!fs.existsSync(obsidianDir)) {
    throw new Error(`No .obsidian directory found in: ${vaultPath}`);
  }

  CONFIG_ITEMS.forEach(item => {
    const sourcePath = path.join(obsidianDir, item);
    const targetPath = path.join(DOTFILES_OBSIDIAN_DIR, item);

    if (fs.existsSync(sourcePath)) {
      const stats = fs.statSync(sourcePath);

      if (stats.isDirectory()) {
        const isPluginDir = item === 'plugins';
        copyDir(sourcePath, targetPath, isPluginDir);
        console.log(`✅ Synced directory: ${item}`);
      } else {
        const sourceContent = fs.readFileSync(sourcePath);
        const targetDir = path.dirname(targetPath);
        ensureDir(targetDir);
        fs.writeFileSync(targetPath, sourceContent);
        console.log(`✅ Synced file: ${item}`);
      }
    } else {
      console.log(`⚠️  Source item not found: ${item}`);
    }
  });
}

function createVault(vaultPath) {
  console.log(`🆕 Creating new Obsidian vault at: ${vaultPath}`);
  
  // Create vault directory
  ensureDir(vaultPath);
  
  // Create .obsidian directory and sync settings
  syncFromDotfilesToVault(vaultPath);
  
  // Add to managed vaults
  if (addManagedVault(vaultPath)) {
    console.log(`✅ Added vault to managed list: ${vaultPath}`);
  } else {
    console.log(`ℹ️  Vault already in managed list: ${vaultPath}`);
  }
  
  console.log(`✨ Vault created successfully!`);
}

function updateVault(vaultPath) {
  console.log(`🔄 Updating vault settings: ${vaultPath}`);
  
  if (!fs.existsSync(vaultPath)) {
    throw new Error(`Vault directory not found: ${vaultPath}`);
  }
  
  syncFromDotfilesToVault(vaultPath);
  console.log(`✨ Vault updated successfully!`);
}

function refreshDotfiles(vaultPath) {
  console.log(`🔄 Refreshing dotfiles from vault: ${vaultPath}`);
  
  if (!fs.existsSync(vaultPath)) {
    throw new Error(`Vault directory not found: ${vaultPath}`);
  }
  
  syncFromVaultToDotfiles(vaultPath);
  console.log(`✨ Dotfiles refreshed successfully!`);
}

// Export functions for use by shell scripts
export {
  ensureManagedVaultsFile,
  getManagedVaults,
  addManagedVault,
  createVault,
  updateVault,
  refreshDotfiles,
  DOTFILES_OBSIDIAN_DIR
};

// CLI interface
if (import.meta.url === `file://${process.argv[1]}`) {
  const command = process.argv[2];
  const vaultPath = process.argv[3];

  try {
    switch (command) {
      case 'create':
        if (!vaultPath) {
          console.error('❌ Please provide a vault path');
          process.exit(1);
        }
        createVault(path.resolve(vaultPath));
        break;
      
      case 'update':
        if (!vaultPath) {
          console.error('❌ Please provide a vault path');
          process.exit(1);
        }
        updateVault(path.resolve(vaultPath));
        break;
      
      case 'refresh':
        if (!vaultPath) {
          console.error('❌ Please provide a vault path');
          process.exit(1);
        }
        refreshDotfiles(path.resolve(vaultPath));
        break;
      
      case 'init':
        ensureManagedVaultsFile();
        console.log('✅ Managed vaults file initialised');
        break;
      
      default:
        console.log('Usage: vault-manager.js <create|update|refresh|init> [vault-path]');
        process.exit(1);
    }
  } catch (error) {
    console.error(`❌ Error: ${error.message}`);
    process.exit(1);
  }
}