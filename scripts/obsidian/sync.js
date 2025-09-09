#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const VAULTS_FILE = path.join(__dirname, '../../obsidian/vaults.json');

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

function readVaults() {
  try {
    return JSON.parse(fs.readFileSync(VAULTS_FILE, 'utf8'));
  } catch (error) {
    console.error('❌ Error reading vaults file:', error.message);
    process.exit(1);
  }
}

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function copyDir(source, target) {
  ensureDir(target);

  const entries = fs.readdirSync(source, { withFileTypes: true });

  for (const entry of entries) {
    const sourcePath = path.join(source, entry.name);
    const targetPath = path.join(target, entry.name);

    if (entry.isDirectory()) {
      copyDir(sourcePath, targetPath);
    } else {
      fs.copyFileSync(sourcePath, targetPath);
    }
  }
}

function syncFromVaultToDotfiles(vaultPath, itemPath) {
  try {
    const sourceFullPath = path.join(vaultPath, '.obsidian', itemPath);
    const targetFullPath = path.join(__dirname, '../../obsidian', itemPath);

    if (!fs.existsSync(sourceFullPath)) {
      console.log(`⚠️  Source item not found: ${itemPath}`);
      return;
    }

    const stats = fs.statSync(sourceFullPath);

    if (stats.isDirectory()) {
      copyDir(sourceFullPath, targetFullPath);
      console.log(`✅ Synced directory: ${itemPath}`);
    } else {
      const sourceContent = fs.readFileSync(sourceFullPath);
      const targetDir = path.dirname(targetFullPath);
      ensureDir(targetDir);
      fs.writeFileSync(targetFullPath, sourceContent);
      console.log(`✅ Synced file: ${itemPath}`);
    }
  } catch (error) {
    console.error(`❌ Error syncing ${itemPath}:`, error.message);
  }
}

async function promptForSourceVault(vaults) {
  const enabledVaults = vaults.vaults.filter(v => v.enabled);
  
  if (enabledVaults.length === 0) {
    return null;
  }

  console.log('📥 Do you want to sync settings FROM a specific vault first?');
  console.log('   (This will copy settings from that vault to dotfiles, then to all vaults)\n');
  
  console.log('Available options:');
  console.log('0. Skip - just sync from dotfiles to all vaults');
  enabledVaults.forEach((vault, index) => {
    console.log(`${index + 1}. ${vault.name} (${vault.path})`);
  });

  // Simple readline implementation
  const readline = await import('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    rl.question('\nEnter your choice (0-' + enabledVaults.length + '): ', (answer) => {
      rl.close();
      
      const choice = parseInt(answer);
      if (choice === 0) {
        resolve(null);
      } else if (choice >= 1 && choice <= enabledVaults.length) {
        resolve(enabledVaults[choice - 1]);
      } else {
        console.log('❌ Invalid choice. Skipping vault-to-dotfiles sync.');
        resolve(null);
      }
    });
  });
}

async function main() {
  const vaults = readVaults();

  if (vaults.vaults.length === 0) {
    console.log('No vaults configured. Use "just obsidian-vaults-add" to add a vault.');
    process.exit(1);
  }

  console.log('🔄 Starting Obsidian configuration sync...\n');

  // Step 1: Optionally sync from a chosen vault to dotfiles
  const sourceVault = await promptForSourceVault(vaults);

  if (sourceVault) {
    console.log(`\n📥 Syncing from source vault '${sourceVault.name}' to dotfiles...\n`);
    CONFIG_ITEMS.forEach(item => {
      syncFromVaultToDotfiles(sourceVault.path, item);
    });
    console.log('');
  }

  // Step 2: Sync from dotfiles to all vaults
  console.log('📤 Syncing from dotfiles to all vaults...\n');
  
  vaults.vaults.forEach(vault => {
    if (!vault.enabled) {
      console.log(`⏭️  Skipping disabled vault: ${vault.name}`);
      return;
    }

    console.log(`\n📁 Processing vault: ${vault.name}`);

    CONFIG_ITEMS.forEach(item => {
      const sourcePath = path.join(__dirname, '../../obsidian', item);
      const targetPath = path.join(vault.path, '.obsidian', item);

      if (fs.existsSync(sourcePath)) {
        const stats = fs.statSync(sourcePath);

        if (stats.isDirectory()) {
          copyDir(sourcePath, targetPath);
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
  });

  console.log('\n✨ Obsidian configuration sync complete!');
  if (sourceVault) {
    console.log(`📝 Configuration changes from '${sourceVault.name}' have been applied to all vaults.`);
  }
  console.log('\n⚠️  Important: You will need to restart Obsidian for the changes to take effect.');
}

main();
