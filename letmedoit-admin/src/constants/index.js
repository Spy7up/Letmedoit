/*
 * 所有常量入口
 *
 * @author letmedoit
 */
import menu from './system/menu-const';
import { LOGIN_DEVICE_ENUM } from './system/login-device-const';
import { FLAG_NUMBER_ENUM, GENDER_ENUM, USER_TYPE_ENUM } from './common-const';
import { LAYOUT_ENUM } from './layout-const';
import file from './support/file-const';
import loginLog from './support/login-log-const';
import message from './business/message/message-const';
import codeGeneratorConst from './support/code-generator-const';
import jobConst from './support/job-const';
import dictConst from './support/dict-const';
import letmedoitTask from './business/letmedoit/task-const';
import letmedoitFeedback from './business/letmedoit/feedback-const';
import letmedoitMember from './business/letmedoit/member-const';

export default {
  FLAG_NUMBER_ENUM,
  LOGIN_DEVICE_ENUM,
  GENDER_ENUM,
  USER_TYPE_ENUM,
  LAYOUT_ENUM,
  ...loginLog,
  ...menu,
  ...file,
  ...message,
  ...codeGeneratorConst,
  ...jobConst,
  ...dictConst,
  ...letmedoitTask,
  ...letmedoitFeedback,
  ...letmedoitMember,
};
