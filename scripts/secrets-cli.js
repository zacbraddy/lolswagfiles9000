#!/usr/bin/env node
import inquirer from 'inquirer';
import { execSync } from 'child_process';
import process from 'process';
import fs from 'fs';

function getSecretsList() {
  try {
    const output = execSync('SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml | yq ". | keys | .[]"', { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'] });
    return output.split('\n').filter(Boolean);
  } catch (e) {
    console.error('Failed to list secrets:', e.message);
    process.exit(1);
  }
}

async function main() {
  const secrets = getSecretsList();
  if (secrets.length === 0) {
    console.log('No secrets found.');
    return;
  }

  const { toDelete } = await inquirer.prompt([
    {
      type: 'checkbox',
      name: 'toDelete',
      message: 'Select secrets to delete:',
      choices: secrets,
    }
  ]);

  if (toDelete.length === 0) {
    console.log('No secrets selected.');
    return;
  }

  const { confirm } = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'confirm',
      message: `Are you sure you want to delete: ${toDelete.join(', ')}?`,
      default: false,
    }
  ]);

  if (!confirm) {
    console.log('Deletion cancelled.');
    return;
  }

  let currentSecrets = null;
  try {
    currentSecrets = execSync('SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml', { encoding: 'utf8' });
  } catch (e) {
    console.error('Failed to decrypt secrets:', e.message);
    process.exit(1);
  }

  let yqCmd = 'yq -y';
  for (const name of toDelete) {
    yqCmd += ` "del(.\"${name}\")"`;
  }

  let updatedSecrets;
  try {
    updatedSecrets = execSync(yqCmd, { input: currentSecrets, encoding: 'utf8' });
  } catch (e) {
    console.error('Failed to update secrets with yq:', e.message);
    process.exit(1);
  }

  try {
    const tempFile = 'nix/secrets/secrets.yaml.temp';
    fs.writeFileSync(tempFile, updatedSecrets);
    execSync(`sops -e --config nix/secrets/.sops.yaml ${tempFile} > nix/secrets/secrets.yaml`, {
      stdio: 'inherit',
      shell: '/bin/bash',
    });
    fs.unlinkSync(tempFile);
    console.log('Secrets deleted successfully.');
  } catch (e) {
    console.error('Failed to re-encrypt secrets:', e.message);
    process.exit(1);
  }
}

main();
