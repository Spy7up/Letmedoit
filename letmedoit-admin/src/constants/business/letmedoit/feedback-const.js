/*
 * 让我做 · 小程序反馈枚举
 * 与 sa-app 的 FEEDBACK_TYPE / FEEDBACK_STATUS 字典一致
 *
 * @Author: 让我做
 */

// 反馈类型
export const FEEDBACK_TYPE_ENUM = {
  SUGGESTION: {
    value: 1,
    desc: '功能建议',
  },
  PROBLEM: {
    value: 2,
    desc: '使用问题',
  },
  VIOLATION: {
    value: 3,
    desc: '内容违规',
  },
  OTHER: {
    value: 4,
    desc: '其他',
  },
};

// 处理状态
export const FEEDBACK_STATUS_ENUM = {
  PENDING: {
    value: 0,
    desc: '待处理',
  },
  PROCESSING: {
    value: 1,
    desc: '处理中',
  },
  RESOLVED: {
    value: 2,
    desc: '已解决',
  },
  CLOSED: {
    value: 3,
    desc: '已关闭',
  },
};

// 状态标签颜色
export const FEEDBACK_STATUS_COLOR = {
  0: 'gold',
  1: 'processing',
  2: 'green',
  3: 'default',
};

// 类型标签颜色
export const FEEDBACK_TYPE_COLOR = {
  1: 'blue',
  2: 'orange',
  3: 'red',
  4: 'default',
};

/**
 * 允许的状态流转，与后端 AppFeedbackStatusEnum.allowNextStatus 保持一致
 * 已关闭为终态
 */
export function allowNextStatusList(currentStatus) {
  if (currentStatus === 0) {
    return [1, 2, 3];
  }
  if (currentStatus === 1) {
    return [2, 3];
  }
  if (currentStatus === 2) {
    return [3];
  }
  return [];
}

export default {
  FEEDBACK_TYPE_ENUM,
  FEEDBACK_STATUS_ENUM,
  FEEDBACK_STATUS_COLOR,
  FEEDBACK_TYPE_COLOR,
  allowNextStatusList,
};
