#!/usr/bin/env node
import inquirer from 'inquirer';
import { execSync } from 'child_process';
import process from 'process';
import fs from 'fs';
import yaml from 'yaml';

function getSecretsList() {
  try {
    const output = execSync('SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml', { encoding: 'utf8' });
    const secrets = yaml.parse(yaml.parse(output).data);
    return Object.keys(secrets);
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

  const { name } = await inquirer.prompt([
    {
      type: 'list',
      name: 'name',
      message: 'Select the secret to remove:',
      choices: secrets,
    },
  ]);

  let secretsObj = {};
  try {
    const currentSecrets = execSync('SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt sops -d --config nix/secrets/.sops.yaml nix/secrets/secrets.yaml', { encoding: 'utf8' });
    secretsObj = yaml.parse(yaml.parse(currentSecrets).data);
  } catch (e) {
    console.error('Failed to decrypt or parse secrets:', e.message);
    process.exit(1);
  }

  // Remove the secret
  delete secretsObj[name];

  // Create a new YAML document
  const doc = new yaml.Document();
  doc.contents = secretsObj;

  // Write to temp file
  const tempFile = 'nix/secrets/secrets.yaml.temp';
  fs.writeFileSync(tempFile, doc.toString());

  // Re-encrypt the updated secrets
  try {
    execSync(`sops -e --config nix/secrets/.sops.yaml ${tempFile} > nix/secrets/secrets.yaml`, {
      stdio: 'inherit',
      shell: '/bin/bash',
    });
    fs.unlinkSync(tempFile);
    console.log(`Secret "${name}" removed successfully.`);
    console.log('Note: You may need to update nix/modules/secrets.nix manually to remove the secret configuration.');
    console.log('Running home-manager switch to apply changes...');
    execSync('just hmr', { stdio: 'inherit' });
  } catch (e) {
    console.error('Failed to re-encrypt secrets:', e.message);
    fs.unlinkSync(tempFile);
    process.exit(1);
  }
}

main();
