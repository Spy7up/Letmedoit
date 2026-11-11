/*
 * loading 组件
 *
 * @author letmedoit
 */
import { useSpinStore } from "/@/store/modules/system/spin";

export const SmartLoading = {
  show: () => {
    useSpinStore().show();
  },

  hide: () => {
    useSpinStore().hide();
  },
};
