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
  view           Display current CLAUDE.md contents
  memory-status  Show memory usage and project data status
  clean-projects Clean old project conversation logs (interactive)

Examples:
  node manage.js view
  node manage.js memory-status
  node manage.js clean-projects
  `);
}



function viewClaudeConfig() {
  if (!fs.existsSync(CLAUDE_FILE)) {
    console.error('❌ CLAUDE.md not found in dotfiles');
    process.exit(1);
  }

  console.log('📄 Current CLAUDE.md contents:');
  console.log('='.repeat(50));
  console.log(fs.readFileSync(CLAUDE_FILE, 'utf8'));
  console.log('='.repeat(50));
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





function showMemoryStatus() {
  console.log('🧠 Claude Memory & Project Status');
  console.log('='.repeat(40));

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
  console.log('='.repeat(30));

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
  case 'view':
    viewClaudeConfig();
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
