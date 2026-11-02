/*
 * 所有路由入口
 *
 * @author letmedoit
 */
import { homeRouters } from './system/home';
import { loginRouters } from './system/login';
import NotFound from '/@/views/system/40X/404.vue';
import NoPrivilege from '/@/views/system/40X/403.vue';

export const routerArray = [
    ...loginRouters,
     ...homeRouters, 
    { path: '/:pathMatch(.*)*', name: '404', component: NotFound },
    { path: '/403', name: '403', component: NoPrivilege }
];
