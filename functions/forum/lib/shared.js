import { Octokit } from '@octokit/rest';
export const getOctokit = (env) => new Octokit({ auth: env.GITHUB_TOKEN });
export const OWNER = 'odesseu';
export const REPO  = 'hosting';
export const BRANCH = 'main';
export async function hashPassword(pass, env) {
  const salt = env.DOCS_SALT || 'nekoq-docs-2025';
  const encoder = new TextEncoder();
  const data = encoder.encode(pass + salt);
  const hashBuffer = await crypto.subtle.digest('SHA-512', data);
  return Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, '0')).join('');
}
export async function getGHFile(path, env) {
  const octokit = getOctokit(env);
  try {
    const { data } = await octokit.repos.getContent({ owner: OWNER, repo: REPO, path, ref: BRANCH });
    return { 
      content: JSON.parse(atob(data.content)), 
      sha: data.sha 
    };
  } catch(e) { return null; }
}