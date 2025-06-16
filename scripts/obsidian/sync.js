#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const VAULTS_FILE = path.join(__dirname, '../../obsidian/vaults.json');
const SOURCE_VAULT = '/home/zacbraddy/Projects/Fireflai/Vaults/FireFlai';

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

function syncItem(sourcePath, targetPath) {
  try {
    const sourceFullPath = path.join(SOURCE_VAULT, '.obsidian', sourcePath);
    const targetFullPath = path.join(__dirname, '../../obsidian', sourcePath);

    if (!fs.existsSync(sourceFullPath)) {
      console.log(`⚠️  Source item not found: ${sourcePath}`);
      return;
    }

    const stats = fs.statSync(sourceFullPath);

    if (stats.isDirectory()) {
      copyDir(sourceFullPath, targetFullPath);
      console.log(`✅ Synced directory: ${sourcePath}`);
    } else {
      const sourceContent = fs.readFileSync(sourceFullPath);
      const targetDir = path.dirname(targetFullPath);
      ensureDir(targetDir);
      fs.writeFileSync(targetFullPath, sourceContent);
      console.log(`✅ Synced file: ${sourcePath}`);
    }
  } catch (error) {
    console.error(`❌ Error syncing ${sourcePath}:`, error.message);
  }
}

function main() {
  const vaults = readVaults();

  if (vaults.vaults.length === 0) {
    console.log('No vaults configured. Use "just obsidian-vaults-add" to add a vault.');
    process.exit(1);
  }

  console.log('🔄 Starting Obsidian configuration sync...\n');

  // First, sync from source vault to dotfiles
  console.log('📥 Syncing from source vault to dotfiles...\n');
  CONFIG_ITEMS.forEach(item => syncItem(item, item));

  // Then sync from dotfiles to all vaults
  console.log('\n📤 Syncing from dotfiles to all vaults...\n');
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
  console.log('\n⚠️  Important: You will need to restart Obsidian for the changes to take effect.');
}

main();
