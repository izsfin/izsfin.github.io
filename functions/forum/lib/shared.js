import { Octokit } from '@octokit/rest';
import Redis from 'ioredis'; // Для CF лучше использовать @upstash/redis, если нет TCP-гейта

export const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
export const redis = new Redis(process.env.REDIS_URL);

export const OWNER = 'misterlerp';
export const REPO  = 'ML';
export const BRANCH = 'main';

const BLACKLIST = ['nigger','faggot','retard','слив','leaked'];
export const hasBlacklist = (str) => BLACKLIST.some(w => str.toLowerCase().includes(w));

export async function hashPassword(pass) {
  const salt = process.env.DOCS_SALT || 'nekoq-docs-2025';
  // В CF Workers лучше использовать Web Crypto API (crypto.subtle)
  const encoder = new TextEncoder();
  const data = encoder.encode(pass + salt);
  const hashBuffer = await crypto.subtle.digest('SHA-512', data);
  return Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, '0')).join('');
}

export async function getGHFile(path) {
  try {
    const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path, ref: BRANCH });
    return { 
      content: JSON.parse(atob(data.content)), 
      sha: data.sha 
    };
  } catch(e) { return null; }
}

export async function createOrUpdateGHFile(path, content, message) {
  const existing = await getGHFile(path);
  return await octokit.repos.createOrUpdateFileContents({
    owner: OWNER, repo: REPO, path, branch: BRANCH,
    message,
    content: btoa(JSON.stringify(content, null, 2)),
    sha: existing?.sha
  });
}