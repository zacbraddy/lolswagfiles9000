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

    // Prompt for secret name
    const { name } = await inquirer.prompt([
      {
        type: 'input',
        name: 'name',
        message: 'Enter the name of the secret:',
        validate: input => {
          if (!input.trim()) return 'Secret name cannot be empty';
          if (existingSecrets.includes(input)) {
            return `Secret "${input}" already exists. Please use 'just secrets-update' to modify existing secrets.`;
          }
          return true;
        }
      }
    ]);

    // Prompt for secret value
    const { value } = await inquirer.prompt([
      {
        type: 'password',
        name: 'value',
        message: `Enter the value for secret "${name}":`,
        validate: input => input.trim() ? true : 'Secret value cannot be empty'
      }
    ]);

    // Get current secrets
    let secretsObj;
    try {
      const currentSecrets = execSync('SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml', { encoding: 'utf8' });
      secretsObj = yaml.parse(yaml.parse(currentSecrets).data);
    } catch (e) {
      console.error('Failed to decrypt or parse secrets:', e.message);
      process.exit(1);
    }

    // Add new secret
    secretsObj[name] = value;

    // Write to temporary file
    const tempFile = 'nix/secrets/secrets.yaml.decrypted';
    fs.writeFileSync(tempFile, yaml.stringify(secretsObj));

    // Re-encrypt the file
    execSync('SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -e --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml.decrypted > nix/secrets/secrets.yaml', { stdio: 'inherit' });

    // Clean up
    fs.unlinkSync(tempFile);

    console.log(`Secret "${name}" added successfully.`);
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
