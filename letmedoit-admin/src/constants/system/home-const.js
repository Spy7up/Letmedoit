/*
 * 首页页面名词
 *
 * @author letmedoit
 */

//首页页面名字（保留给菜单折叠、标签页、logo 点击等 router.push({ name }) 调用）
export const HOME_PAGE_NAME = 'Home';

//首页页面路径
export const HOME_PAGE_PATH = '/home';

/**
 * 首页实际落地页：让我做 · 运营概览
 *
 * 框架自带的演示首页（views/system/home）不再作为入口，/home 直接重定向到这里。
 * 路径必须与后端 t_menu 里「运营概览」的 path 一致（docs/sql/updates/2026-10-29/01_admin_menu.sql），
 * 否则未授权该菜单的账号会落到 404。
 */
export const HOME_REDIRECT_PATH = '/letmedoit/dashboard';
