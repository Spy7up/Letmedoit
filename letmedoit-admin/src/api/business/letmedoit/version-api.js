import { postRequest } from '/@/lib/axios';

export const letmedoitVersionApi = {
  query: (param) => postRequest('/appVersion/query', param),
  add: (param) => postRequest('/appVersion/add', param),
  update: (param) => postRequest('/appVersion/update', param),
  publish: (param) => postRequest('/appVersion/publish', param),
};
