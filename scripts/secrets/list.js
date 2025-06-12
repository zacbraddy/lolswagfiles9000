#!/usr/bin/env node
import { execSync } from 'child_process';
import process from 'process';
import yaml from 'yaml';
import fs from 'fs';

function getSecretsList() {
  try {
    // Check if the file exists before trying to decrypt
    if (!fs.existsSync('nix/secrets/secrets.yaml')) {
      return [];
    }
    const output = execSync('SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml', { encoding: 'utf8' });
    const secrets = yaml.parse(yaml.parse(output).data);
    // Handle both empty files and files with no keys
    if (!secrets || typeof secrets !== 'object') {
      return [];
    }
    return Object.keys(secrets);
  } catch (e) {
    // If the file doesn't exist or is empty, return empty array
    if (e.message.includes('no such file') || e.message.includes('empty file')) {
      return [];
    }
    console.error('Failed to list secrets:', e.message);
    process.exit(1);
  }
}

function main() {
  const secrets = getSecretsList();
  if (secrets.length === 0) {
    console.log('No secrets found.');
    return;
  }

  console.log('\nAvailable secrets:');
  secrets.forEach(secret => {
    console.log(`- ${secret}`);
  });
}

main();
