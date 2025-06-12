#!/usr/bin/env node

import inquirer from 'inquirer';
import { execSync } from 'child_process';
import process from 'process';
import fs from 'fs';
import yaml from 'yaml';

async function main() {
  try {
    // Get list of existing secrets
    const existingSecrets = getSecretsList();

    if (existingSecrets.length === 0) {
      console.log('No secrets found. Use "just secrets-add" to add a new secret.');
      process.exit(0);
    }

    // Prompt for secret to update
    const { name } = await inquirer.prompt([
      {
        type: 'list',
        name: 'name',
        message: 'Select the secret to update:',
        choices: existingSecrets
      }
    ]);

    // Get current value
    let currentValue;
    try {
      const currentSecrets = execSync('SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml', { encoding: 'utf8' });
      const secretsObj = yaml.parse(yaml.parse(currentSecrets).data);
      currentValue = secretsObj[name];
    } catch (e) {
      console.error('Failed to decrypt or parse secrets:', e.message);
      process.exit(1);
    }

    // Prompt for new value
    const { value } = await inquirer.prompt([
      {
        type: 'password',
        name: 'value',
        message: `Enter new value for "${name}" (current value: ${currentValue}):`,
        validate: input => input.trim() ? true : 'Secret value cannot be empty'
      }
    ]);

    // Update the secret
    let secretsObj;
    try {
      const currentSecrets = execSync('SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml', { encoding: 'utf8' });
      secretsObj = yaml.parse(yaml.parse(currentSecrets).data);
    } catch (e) {
      console.error('Failed to decrypt or parse secrets:', e.message);
      process.exit(1);
    }

    secretsObj[name] = value;

    // Write to temporary file
    const tempFile = 'nix/secrets/secrets.yaml.decrypted';
    fs.writeFileSync(tempFile, yaml.stringify(secretsObj));

    // Re-encrypt the file
    execSync('SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -e --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml.decrypted > nix/secrets/secrets.yaml', { stdio: 'inherit' });

    // Clean up
    fs.unlinkSync(tempFile);

    console.log(`Secret "${name}" updated successfully.`);
  } catch (e) {
    console.error('Error:', e.message);
    process.exit(1);
  }
}

function getSecretsList() {
  try {
    const output = execSync('SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml', { encoding: 'utf8' });
    const secrets = yaml.parse(yaml.parse(output).data);
    return Object.keys(secrets);
  } catch (e) {
    return [];
  }
}

main();
