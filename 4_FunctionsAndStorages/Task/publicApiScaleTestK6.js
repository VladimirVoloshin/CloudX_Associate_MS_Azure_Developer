import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
    vus: 5000,
    duration: '15m',
  };

export default function () {
  http.get('https://publicapi-20233007.azurewebsites.net/api/catalog-brands');
  sleep(1);
}