#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import readline from 'readline';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const VAULTS_FILE = path.join(__dirname, '../../obsidian/vaults.json');

function readVaults() {
  try {
    return JSON.parse(fs.readFileSync(VAULTS_FILE, 'utf8'));
  } catch (error) {
    return { vaults: [] };
  }
}

function writeVaults(data) {
  fs.writeFileSync(VAULTS_FILE, JSON.stringify(data, null, 2));
}

function prompt(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise(resolve => {
    rl.question(question, answer => {
      rl.close();
      resolve(answer);
    });
  });
}

async function addVault() {
  const vaults = readVaults();
  const path = await prompt('Enter vault path: ');
  const name = await prompt('Enter vault name: ');

  if (vaults.vaults.some(v => v.path === path)) {
    console.log('❌ Vault with this path already exists');
    return;
  }

  vaults.vaults.push({
    path,
    name,
    enabled: true
  });

  writeVaults(vaults);
  console.log('✅ Vault added successfully');
}

async function removeVault() {
  const vaults = readVaults();
  if (vaults.vaults.length === 0) {
    console.log('No vaults configured');
    return;
  }

  console.log('\nConfigured vaults:');
  vaults.vaults.forEach((vault, index) => {
    console.log(`${index + 1}. ${vault.name} (${vault.path})`);
  });

  const index = parseInt(await prompt('\nEnter vault number to remove: ')) - 1;
  if (isNaN(index) || index < 0 || index >= vaults.vaults.length) {
    console.log('❌ Invalid vault number');
    return;
  }

  vaults.vaults.splice(index, 1);
  writeVaults(vaults);
  console.log('✅ Vault removed successfully');
}

async function editVault() {
  const vaults = readVaults();
  if (vaults.vaults.length === 0) {
    console.log('No vaults configured');
    return;
  }

  console.log('\nConfigured vaults:');
  vaults.vaults.forEach((vault, index) => {
    console.log(`${index + 1}. ${vault.name} (${vault.path})`);
  });

  const index = parseInt(await prompt('\nEnter vault number to edit: ')) - 1;
  if (isNaN(index) || index < 0 || index >= vaults.vaults.length) {
    console.log('❌ Invalid vault number');
    return;
  }

  const vault = vaults.vaults[index];
  const newPath = await prompt(`Enter new path [${vault.path}]: `) || vault.path;
  const newName = await prompt(`Enter new name [${vault.name}]: `) || vault.name;

  vault.path = newPath;
  vault.name = newName;

  writeVaults(vaults);
  console.log('✅ Vault updated successfully');
}

async function listVaults() {
  const vaults = readVaults();
  if (vaults.vaults.length === 0) {
    console.log('No vaults configured');
    return;
  }

  console.log('\nConfigured vaults:');
  vaults.vaults.forEach((vault, index) => {
    console.log(`${index + 1}. ${vault.name} (${vault.path})`);
  });
}

async function main() {
  const command = process.argv[2];

  switch (command) {
    case 'add':
      await addVault();
      break;
    case 'remove':
      await removeVault();
      break;
    case 'edit':
      await editVault();
      break;
    case 'list':
      await listVaults();
      break;
    default:
      console.log('Usage: node manage-vaults.js [add|remove|edit|list]');
  }
}

main().catch(console.error);
