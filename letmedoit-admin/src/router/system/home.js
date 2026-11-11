/*
 * 首页路由
 *
 * @author letmedoit
 */
import { HOME_PAGE_NAME, HOME_REDIRECT_PATH } from '/@/constants/system/home-const';
import { MENU_TYPE_ENUM } from '/@/constants/system/menu-const';
import SmartLayout from '/@/layout/index.vue';

export const homeRouters = [
  {
    path: '/',
    name: '_home',
    redirect: { name: HOME_PAGE_NAME },
    component: SmartLayout,
    meta: {
      title: '首页',
      menuType: MENU_TYPE_ENUM.CATALOG.value,
      icon: 'HomeOutlined',
    },
    children: [
      {
        /**
         * 首页不再使用框架自带演示页（views/system/home），直接落到「让我做 · 运营概览」。
         * 保留 name=Home，是为了 logo 点击、标签页回首页等 router.push({ name: HOME_PAGE_NAME }) 的调用不出错。
         * 运营概览是动态菜单路由，登录时由 buildRoutes 注册，所以这里只能用 path 重定向。
         */
        path: '/home',
        name: HOME_PAGE_NAME,
        redirect: HOME_REDIRECT_PATH,
        meta: {
          title: '运营概览',
          menuType: MENU_TYPE_ENUM.MENU.value,
          icon: 'HomeOutlined',
          parentMenuList: [{ name: '_home', title: '首页' }],
        },
      },
      {
        path: '/account',
        name: 'Account',
        component: () => import('/@/views/system/account/index.vue'),
        meta: {
          title: '个人中心',
          hideInMenu: false,
        },
      },
    ],
  },
];
