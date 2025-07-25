#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const CLAUDE_FILE = path.join(__dirname, '../../claude/CLAUDE.md');
const CLAUDE_DIR = path.join(process.env.HOME, '.claude');
const CLAUDE_TARGET = path.join(CLAUDE_DIR, 'CLAUDE.md');
const BACKUP_DIR = path.join(__dirname, '../../claude/backups');

function showHelp() {
  console.log(`
Claude Configuration Manager

Usage: node manage.js [command]

Commands:
  edit           Open CLAUDE.md in your default editor
  view           Display current CLAUDE.md contents
  backup         Create a timestamped backup of current config
  backup-all     Backup entire Claude directory (including memories, projects, settings)
  restore        Restore from the most recent backup
  restore-all    Restore entire Claude directory from backup
  diff           Show differences between dotfiles and live config
  status         Show current configuration status
  memory-status  Show memory usage and project data status
  clean-projects Clean old project conversation logs (interactive)

Examples:
  node manage.js edit
  node manage.js backup-all
  node manage.js memory-status
  node manage.js clean-projects
  `);
}

function editClaudeConfig() {
  const editor = process.env.EDITOR || 'nano';
  console.log(`Opening ${CLAUDE_FILE} with ${editor}...`);
  
  try {
    execSync(`${editor} "${CLAUDE_FILE}"`, { stdio: 'inherit' });
    console.log('✅ CLAUDE.md edited successfully');
    console.log('💡 Run "just hmr" to apply changes');
  } catch (error) {
    console.error('❌ Failed to open editor:', error.message);
    process.exit(1);
  }
}

function viewClaudeConfig() {
  if (!fs.existsSync(CLAUDE_FILE)) {
    console.error('❌ CLAUDE.md not found in dotfiles');
    process.exit(1);
  }
  
  console.log('📄 Current CLAUDE.md contents:');
  console.log('=' .repeat(50));
  console.log(fs.readFileSync(CLAUDE_FILE, 'utf8'));
  console.log('=' .repeat(50));
}

function backupClaudeConfig() {
  if (!fs.existsSync(CLAUDE_TARGET)) {
    console.log('ℹ️  No live CLAUDE.md found to backup');
    return;
  }
  
  if (!fs.existsSync(BACKUP_DIR)) {
    fs.mkdirSync(BACKUP_DIR, { recursive: true });
  }
  
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupFile = path.join(BACKUP_DIR, `CLAUDE-${timestamp}.md`);
  
  try {
    fs.copyFileSync(CLAUDE_TARGET, backupFile);
    console.log(`✅ Backup created: ${backupFile}`);
  } catch (error) {
    console.error('❌ Failed to create backup:', error.message);
    process.exit(1);
  }
}

function backupAllClaudeData() {
  if (!fs.existsSync(CLAUDE_DIR)) {
    console.log('ℹ️  No Claude directory found to backup');
    return;
  }
  
  if (!fs.existsSync(BACKUP_DIR)) {
    fs.mkdirSync(BACKUP_DIR, { recursive: true });
  }
  
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupName = `claude-full-${timestamp}`;
  const backupPath = path.join(BACKUP_DIR, backupName);
  
  try {
    console.log('🔄 Creating full Claude backup...');
    
    // Create backup directory
    fs.mkdirSync(backupPath, { recursive: true });
    
    // Backup main files (excluding credentials for security)
    const filesToBackup = ['CLAUDE.md', 'settings.json'];
    filesToBackup.forEach(file => {
      const srcPath = path.join(CLAUDE_DIR, file);
      if (fs.existsSync(srcPath)) {
        const destPath = path.join(backupPath, file);
        fs.copyFileSync(srcPath, destPath);
        console.log(`  ✅ Backed up ${file}`);
      }
    });
    
    // Note about credentials
    if (fs.existsSync(path.join(CLAUDE_DIR, '.credentials.json'))) {
      console.log(`  ⚠️  Skipped .credentials.json for security (not backed up)`);
    }
    
    // Backup directories
    const dirsToBackup = ['memory', 'projects', 'todos', 'commands'];
    dirsToBackup.forEach(dir => {
      const srcPath = path.join(CLAUDE_DIR, dir);
      if (fs.existsSync(srcPath)) {
        const destPath = path.join(backupPath, dir);
        copyDirectoryRecursive(srcPath, destPath);
        console.log(`  ✅ Backed up ${dir}/`);
      }
    });
    
    console.log(`✅ Full backup created: ${backupPath}`);
    
    // Clean old full backups (keep last 5)
    const fullBackups = fs.readdirSync(BACKUP_DIR)
      .filter(item => item.startsWith('claude-full-'))
      .sort()
      .reverse();
    
    if (fullBackups.length > 5) {
      const toDelete = fullBackups.slice(5);
      toDelete.forEach(backup => {
        const backupPath = path.join(BACKUP_DIR, backup);
        fs.rmSync(backupPath, { recursive: true, force: true });
        console.log(`🗑️  Cleaned old backup: ${backup}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Failed to create full backup:', error.message);
    process.exit(1);
  }
}

function copyDirectoryRecursive(src, dest) {
  if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
  }
  
  const items = fs.readdirSync(src);
  items.forEach(item => {
    const srcPath = path.join(src, item);
    const destPath = path.join(dest, item);
    
    if (fs.statSync(srcPath).isDirectory()) {
      copyDirectoryRecursive(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  });
}

function restoreClaudeConfig() {
  if (!fs.existsSync(BACKUP_DIR)) {
    console.log('❌ No backups directory found');
    process.exit(1);
  }
  
  const backups = fs.readdirSync(BACKUP_DIR)
    .filter(file => file.startsWith('CLAUDE-') && file.endsWith('.md'))
    .sort()
    .reverse();
  
  if (backups.length === 0) {
    console.log('❌ No backups found');
    process.exit(1);
  }
  
  const latestBackup = path.join(BACKUP_DIR, backups[0]);
  console.log(`🔄 Restoring from: ${backups[0]}`);
  
  try {
    fs.copyFileSync(latestBackup, CLAUDE_FILE);
    console.log('✅ Configuration restored from backup');
    console.log('💡 Run "just hmr" to apply changes');
  } catch (error) {
    console.error('❌ Failed to restore backup:', error.message);
    process.exit(1);
  }
}

function restoreAllClaudeData() {
  if (!fs.existsSync(BACKUP_DIR)) {
    console.log('❌ No backups directory found');
    process.exit(1);
  }
  
  const fullBackups = fs.readdirSync(BACKUP_DIR)
    .filter(item => item.startsWith('claude-full-'))
    .sort()
    .reverse();
  
  if (fullBackups.length === 0) {
    console.log('❌ No full backups found');
    process.exit(1);
  }
  
  const latestFullBackup = path.join(BACKUP_DIR, fullBackups[0]);
  console.log(`🔄 Restoring full Claude data from: ${fullBackups[0]}`);
  console.log('⚠️  This will overwrite your current Claude configuration!');
  
  // Simple confirmation (in a real scenario, you might want a more robust prompt)
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  rl.question('Continue? (y/N): ', (answer) => {
    if (answer.toLowerCase() !== 'y') {
      console.log('❌ Restore cancelled');
      rl.close();
      return;
    }
    
    try {
      // Restore files (excluding credentials which are never backed up)
      const filesToRestore = ['CLAUDE.md', 'settings.json'];
      filesToRestore.forEach(file => {
        const srcPath = path.join(latestFullBackup, file);
        const destPath = path.join(CLAUDE_DIR, file);
        if (fs.existsSync(srcPath)) {
          fs.copyFileSync(srcPath, destPath);
          console.log(`  ✅ Restored ${file}`);
        }
      });
      
      console.log(`  ℹ️  Note: .credentials.json not restored (never backed up for security)`);
      console.log(`      You'll need to re-authenticate with Claude CLI after restore`);
      
      // Restore directories
      const dirsToRestore = ['memory', 'projects', 'todos', 'commands'];
      dirsToRestore.forEach(dir => {
        const srcPath = path.join(latestFullBackup, dir);
        const destPath = path.join(CLAUDE_DIR, dir);
        if (fs.existsSync(srcPath)) {
          // Remove existing directory
          if (fs.existsSync(destPath)) {
            fs.rmSync(destPath, { recursive: true, force: true });
          }
          copyDirectoryRecursive(srcPath, destPath);
          console.log(`  ✅ Restored ${dir}/`);
        }
      });
      
      console.log('✅ Full Claude data restored from backup');
      console.log('💡 Run "just hmr" to apply CLAUDE.md changes');
      
    } catch (error) {
      console.error('❌ Failed to restore backup:', error.message);
      process.exit(1);
    }
    
    rl.close();
  });
}

function diffClaudeConfig() {
  if (!fs.existsSync(CLAUDE_FILE)) {
    console.error('❌ CLAUDE.md not found in dotfiles');
    process.exit(1);
  }
  
  if (!fs.existsSync(CLAUDE_TARGET)) {
    console.log('ℹ️  No live CLAUDE.md found for comparison');
    console.log('📄 Current dotfiles version:');
    viewClaudeConfig();
    return;
  }
  
  try {
    console.log('📊 Comparing dotfiles version with live version...');
    const result = execSync(`diff -u "${CLAUDE_TARGET}" "${CLAUDE_FILE}" || true`, { stdio: 'pipe' });
    if (result.length === 0) {
      console.log('✅ Files are identical - no differences found');
    } else {
      console.log(result.toString());
    }
  } catch (error) {
    console.error('❌ Failed to compare files:', error.message);
  }
}

function showStatus() {
  console.log('📋 Claude Configuration Status');
  console.log('=' .repeat(40));
  
  // Check dotfiles version
  if (fs.existsSync(CLAUDE_FILE)) {
    const stats = fs.statSync(CLAUDE_FILE);
    console.log(`✅ Dotfiles: ${CLAUDE_FILE}`);
    console.log(`   Modified: ${stats.mtime.toLocaleString()}`);
  } else {
    console.log(`❌ Dotfiles: ${CLAUDE_FILE} (not found)`);
  }
  
  // Check live version
  if (fs.existsSync(CLAUDE_TARGET)) {
    const stats = fs.statSync(CLAUDE_TARGET);
    console.log(`✅ Live: ${CLAUDE_TARGET}`);
    console.log(`   Modified: ${stats.mtime.toLocaleString()}`);
    
    // Check if it's a symlink (managed by Home Manager)
    const lstat = fs.lstatSync(CLAUDE_TARGET);
    if (lstat.isSymbolicLink()) {
      const linkTarget = fs.readlinkSync(CLAUDE_TARGET);
      console.log(`   Symlink: ${linkTarget}`);
      console.log(`   Status: ✅ Managed by Home Manager`);
    } else {
      console.log(`   Status: ⚠️  Not managed by Home Manager`);
    }
  } else {
    console.log(`❌ Live: ${CLAUDE_TARGET} (not found)`);
  }
  
  // Check backups
  if (fs.existsSync(BACKUP_DIR)) {
    const backups = fs.readdirSync(BACKUP_DIR)
      .filter(file => file.startsWith('CLAUDE-') && file.endsWith('.md'));
    const fullBackups = fs.readdirSync(BACKUP_DIR)
      .filter(item => item.startsWith('claude-full-'));
    console.log(`💾 Backups: ${backups.length} config backups, ${fullBackups.length} full backups`);
  } else {
    console.log(`💾 Backups: 0 found`);
  }
}

function showMemoryStatus() {
  console.log('🧠 Claude Memory & Project Status');
  console.log('=' .repeat(40));
  
  // Check memory directory
  const memoryDir = path.join(CLAUDE_DIR, 'memory');
  if (fs.existsSync(memoryDir)) {
    const memoryFiles = fs.readdirSync(memoryDir);
    console.log(`📝 Memory files: ${memoryFiles.length}`);
    if (memoryFiles.length > 0) {
      memoryFiles.forEach(file => {
        const filePath = path.join(memoryDir, file);
        const stats = fs.statSync(filePath);
        console.log(`   - ${file} (${(stats.size / 1024).toFixed(1)}KB, ${stats.mtime.toLocaleDateString()})`);
      });
    }
  } else {
    console.log('📝 Memory directory: Not found');
  }
  
  // Check projects directory
  const projectsDir = path.join(CLAUDE_DIR, 'projects');
  if (fs.existsSync(projectsDir)) {
    const projects = fs.readdirSync(projectsDir);
    console.log(`📁 Project directories: ${projects.length}`);
    
    let totalConversations = 0;
    let totalSize = 0;
    
    projects.forEach(project => {
      const projectPath = path.join(projectsDir, project);
      if (fs.statSync(projectPath).isDirectory()) {
        const conversations = fs.readdirSync(projectPath)
          .filter(file => file.endsWith('.jsonl'));
        totalConversations += conversations.length;
        
        let projectSize = 0;
        conversations.forEach(conv => {
          const convPath = path.join(projectPath, conv);
          projectSize += fs.statSync(convPath).size;
        });
        totalSize += projectSize;
        
        // Decode project path
        const decodedPath = project.replace(/^-/, '').replace(/-/g, '/');
        console.log(`   - ${decodedPath}`);
        console.log(`     Conversations: ${conversations.length}, Size: ${(projectSize / 1024).toFixed(1)}KB`);
      }
    });
    
    console.log(`📊 Total: ${totalConversations} conversations, ${(totalSize / 1024 / 1024).toFixed(2)}MB`);
  } else {
    console.log('📁 Projects directory: Not found');
  }
  
  // Check todos directory
  const todosDir = path.join(CLAUDE_DIR, 'todos');
  if (fs.existsSync(todosDir)) {
    const todoFiles = fs.readdirSync(todosDir);
    console.log(`✅ Todo files: ${todoFiles.length}`);
  } else {
    console.log('✅ Todos directory: Not found');
  }
}

function cleanProjects() {
  const projectsDir = path.join(CLAUDE_DIR, 'projects');
  if (!fs.existsSync(projectsDir)) {
    console.log('📁 No projects directory found');
    return;
  }
  
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  const projects = fs.readdirSync(projectsDir);
  console.log('🧹 Claude Project Cleanup');
  console.log('=' .repeat(30));
  
  projects.forEach((project, index) => {
    const projectPath = path.join(projectsDir, project);
    if (fs.statSync(projectPath).isDirectory()) {
      const conversations = fs.readdirSync(projectPath)
        .filter(file => file.endsWith('.jsonl'));
      
      let projectSize = 0;
      let oldestConv = null;
      let newestConv = null;
      
      conversations.forEach(conv => {
        const convPath = path.join(projectPath, conv);
        const stats = fs.statSync(convPath);
        projectSize += stats.size;
        
        if (!oldestConv || stats.mtime < oldestConv.mtime) {
          oldestConv = { name: conv, mtime: stats.mtime };
        }
        if (!newestConv || stats.mtime > newestConv.mtime) {
          newestConv = { name: conv, mtime: stats.mtime };
        }
      });
      
      const decodedPath = project.replace(/^-/, '').replace(/-/g, '/');
      console.log(`\n${index + 1}. ${decodedPath}`);
      console.log(`   Conversations: ${conversations.length}`);
      console.log(`   Size: ${(projectSize / 1024).toFixed(1)}KB`);
      if (oldestConv) {
        console.log(`   Oldest: ${oldestConv.mtime.toLocaleDateString()}`);
        console.log(`   Newest: ${newestConv.mtime.toLocaleDateString()}`);
      }
    }
  });
  
  console.log('\nOptions:');
  console.log('1. Delete conversations older than 30 days');
  console.log('2. Delete conversations older than 7 days'); 
  console.log('3. Delete specific project');
  console.log('4. Exit');
  
  rl.question('\nSelect option (1-4): ', (choice) => {
    const now = new Date();
    
    switch (choice) {
      case '1':
        cleanOldConversations(30, now);
        break;
      case '2':
        cleanOldConversations(7, now);
        break;
      case '3':
        rl.question('Enter project number to delete: ', (projectNum) => {
          const projectIndex = parseInt(projectNum) - 1;
          if (projectIndex >= 0 && projectIndex < projects.length) {
            const projectToDelete = projects[projectIndex];
            const projectPath = path.join(projectsDir, projectToDelete);
            fs.rmSync(projectPath, { recursive: true, force: true });
            console.log(`✅ Deleted project: ${projectToDelete}`);
          } else {
            console.log('❌ Invalid project number');
          }
          rl.close();
        });
        return;
      case '4':
        console.log('👋 Cleanup cancelled');
        rl.close();
        return;
      default:
        console.log('❌ Invalid option');
        rl.close();
        return;
    }
    rl.close();
  });
  
  function cleanOldConversations(days, now) {
    const cutoffDate = new Date(now.getTime() - (days * 24 * 60 * 60 * 1000));
    let deletedCount = 0;
    let deletedSize = 0;
    
    projects.forEach(project => {
      const projectPath = path.join(projectsDir, project);
      if (fs.statSync(projectPath).isDirectory()) {
        const conversations = fs.readdirSync(projectPath)
          .filter(file => file.endsWith('.jsonl'));
        
        conversations.forEach(conv => {
          const convPath = path.join(projectPath, conv);
          const stats = fs.statSync(convPath);
          
          if (stats.mtime < cutoffDate) {
            deletedSize += stats.size;
            fs.unlinkSync(convPath);
            deletedCount++;
          }
        });
      }
    });
    
    console.log(`✅ Deleted ${deletedCount} conversations older than ${days} days`);
    console.log(`💾 Freed ${(deletedSize / 1024).toFixed(1)}KB of storage`);
  }
}

const command = process.argv[2];

switch (command) {
  case 'edit':
    editClaudeConfig();
    break;
  case 'view':
    viewClaudeConfig();
    break;
  case 'backup':
    backupClaudeConfig();
    break;
  case 'backup-all':
    backupAllClaudeData();
    break;
  case 'restore':
    restoreClaudeConfig();
    break;
  case 'restore-all':
    restoreAllClaudeData();
    break;
  case 'diff':
    diffClaudeConfig();
    break;
  case 'status':
    showStatus();
    break;
  case 'memory-status':
    showMemoryStatus();
    break;
  case 'clean-projects':
    cleanProjects();
    break;
  default:
    showHelp();
    if (command) {
      console.error(`❌ Unknown command: ${command}`);
      process.exit(1);
    }
}