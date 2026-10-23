import {defineConfig} from '@playwright/test';
export default defineConfig({testDir:'./ui_test', use:{baseURL:'http://127.0.0.1:8799'}, webServer:{command:'node --experimental-strip-types ui_test/server.mjs',url:'http://127.0.0.1:8799/private/report/'}, reporter:'list'});
