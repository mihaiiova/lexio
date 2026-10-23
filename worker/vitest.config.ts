import { defineWorkersConfig, readD1Migrations } from '@cloudflare/vitest-pool-workers/config';

export default defineWorkersConfig(async () => ({
  test: {
    poolOptions: {
      workers: {
        wrangler: { configPath: './wrangler.jsonc' },
        miniflare: {
          bindings: { RATE_LIMIT_MAX: '1000', PUBLIC_ENDPOINTS_ENABLED: 'true', TEST_MIGRATIONS: await readD1Migrations('./migrations') },
        },
      },
    },
  },
}));
