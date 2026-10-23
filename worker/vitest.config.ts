import { defineWorkersConfig } from '@cloudflare/vitest-pool-workers/config';

export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        wrangler: { configPath: './wrangler.jsonc' },
        miniflare: {
          bindings: { RATE_LIMIT_MAX: '1000', PUBLIC_ENDPOINTS_ENABLED: 'true' },
        },
      },
    },
  },
});
