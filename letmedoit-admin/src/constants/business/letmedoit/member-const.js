/*
 * 让我做 · 会员报表枚举
 *
 * @Author: 让我做
 */

// 会员状态
export const MEMBER_STATUS_ENUM = {
  NORMAL: {
    value: false,
    desc: '正常',
  },
  DISABLED: {
    value: true,
    desc: '已禁用',
  },
};

// 会员在任务中的身份
export const MEMBER_TASK_ROLE_ENUM = {
  CREATOR: {
    value: 'creator',
    desc: '委托人',
  },
  PARTICIPANT: {
    value: 'participant',
    desc: '参与者',
  },
};

export default {
  MEMBER_STATUS_ENUM,
  MEMBER_TASK_ROLE_ENUM,
};
