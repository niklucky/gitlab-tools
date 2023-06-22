#!/usr/bin/env node

const { join } = require('path')
const { readFileSync } = require('fs')

console.log('args: ', process.argv[2]);
console.log('args: ', process.argv);

let platform = null;
let chat_id = null;

process.argv.forEach(arg => {
  if (arg === 'android' || arg === 'ios') {
    platform = arg;
    return;
  }
  if (arg.includes('chat_id')) {
    const [, id] = process.argv[3].split('=');
    chat_id = id.trim();
  }
});

if (process.argv[2] === undefined) {
  process.exit(0);
}

const {
  CI_PROJECT_NAMESPACE = 'Test',
  CI_PROJECT_TITLE = 'Project',
  CI_JOB_NAME = 'job_name',
  CI_PIPELINE_ID = '0',
  CI_PROJECT_URL = 'https://example.com',
  CI_COMMIT_BRANCH = 'develop',
  CI_PROJECT_DIR,
  TELEGRAM_BOT_TOKEN,
  TELEGRAM_CHAT_ID,

} = process.env;

if (!TELEGRAM_CHAT_ID) {
  console.error('TELEGRAM_CHAT_ID env varibale is undefined')
  process.exit(0)
}
if (!TELEGRAM_BOT_TOKEN) {
  console.error('TELEGRAM_BOT_TOKEN env varibale is undefined')
  process.exit(0)
}
const STAGING =
  process.env.CI_COMMIT_BRANCH === 'main' ? 'Production' : 'Staging';

const CI_JOB_STATUS = process.env.CI_JOB_STATUS ?? 'unknown';

function notify(platform) {
  console.log('env', STAGING);
  console.log('CI_PROJECT_DIR', CI_PROJECT_DIR);
  const fileName = platform === 'ios'
    ? 'ios_version.json'
    : 'android_version.json'

  console.log(fileName)
  const p = join(CI_PROJECT_DIR, fileName)
  console.log(p)
  const file = readFileSync(p)
  const appcenterVersion = JSON.parse(file.toString())

  if (!appcenterVersion || !appcenterVersion.length) {
    process.exit(1);
  }

  const version = appcenterVersion.find(item => {
    return item.name === STAGING;
  });
  if (!version) {
    return;
  }

  console.log(version);

  let status_icon = '🟢';
  if (CI_JOB_STATUS === 'failed') {
    status_icon = '💥';
  }
  if (CI_JOB_STATUS === 'cancelled') {
    status_icon = '⚪';
  }

  const message = `

${status_icon} <b>${CI_JOB_NAME}</b>
#${CI_JOB_STATUS} #${CI_PROJECT_NAMESPACE}_${CI_PROJECT_TITLE}

🚀 <b>${CI_PROJECT_NAMESPACE} / ${CI_PROJECT_TITLE}</b> (👉 ${platform})

📱 Version: <b>${version.latestRelease.targetBinaryRange} - ${version.latestRelease.label}</b>

👷 Staging: <b>${STAGING}</b> (branch: <b>${CI_COMMIT_BRANCH}</b>)

🔨 Build: <a href="${CI_PROJECT_URL}/-/pipelines/${CI_PIPELINE_ID}">${CI_PIPELINE_ID}</a>
  `;

  fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      chat_id: chat_id ?? TELEGRAM_CHAT_ID,
      parse_mode: 'HTML',
      text: message,
    }),
  })
    .then(response => {
      return response.json();
    })
    .then(data => {
      console.log(data.ok);
    })
    .catch(e => {
      console.log(e);
    });
}

if (platform) {
  notify(platform);
}
